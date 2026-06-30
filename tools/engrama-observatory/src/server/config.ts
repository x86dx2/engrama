import fs from "node:fs/promises";
import path from "node:path";

import type {
  ModelsConfigDraft,
  ModelsConfigResponse,
  ModelsSaveResponse,
  ModelsValidationResponse,
  PricePoint,
  SubscriptionPlan,
  TierConfig,
} from "../shared/types.js";
import { maskSecrets } from "./maskSecrets.js";
import { assertSafeRepoPath, assertSafeWritePath } from "./repo.js";

type ParsedConfig = Record<string, string>;

export const ROLE_POLICY = [
  { role: "execute", minimumTier: "T1" },
  { role: "orchestrate", minimumTier: "T3" },
  { role: "review", minimumTier: "T3" },
  { role: "critique", minimumTier: "T4" },
  { role: "audit", minimumTier: "T4" },
  { role: "authority", minimumTier: "T4+" },
] as const;

const TIER_PREFIXES = [
  { tier: "T1", prefix: "ENGRAMA_T1" },
  { tier: "T2", prefix: "ENGRAMA_T2" },
  { tier: "T3", prefix: "ENGRAMA_T3" },
  { tier: "T4", prefix: "ENGRAMA_T4" },
  { tier: "T4+", prefix: "ENGRAMA_T4_PLUS" },
] as const;

const MODEL_KEYS = [
  "ENGRAMA_CRITIQUE_NO_FALLBACK",
  ...TIER_PREFIXES.flatMap(({ prefix }) => [
    `${prefix}_ADAPTER`,
    `${prefix}_PROVIDER`,
    `${prefix}_MODEL`,
    `${prefix}_EFFORT`,
  ]),
] as const;

const VALIDATION_COMMANDS = [
  ".engrama/engine/scripts/model-router.sh --role execute --tier T2",
  ".engrama/engine/scripts/model-router.sh --role critique --tier T4",
  ".engrama/engine/scripts/model-router.sh --role authority --tier T4+",
];

export function parseShellConfig(content: string): ParsedConfig {
  const config: ParsedConfig = {};

  for (const rawLine of content.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith("#")) {
      continue;
    }

    const separatorIndex = line.indexOf("=");
    if (separatorIndex <= 0) {
      continue;
    }

    const key = line.slice(0, separatorIndex).trim();
    let value = line.slice(separatorIndex + 1).trim();

    if (
      (value.startsWith("'") && value.endsWith("'")) ||
      (value.startsWith('"') && value.endsWith('"'))
    ) {
      value = value.slice(1, -1);
    }

    config[key] = value;
  }

  return config;
}

function asNullableNumber(value: string | undefined): number | null {
  if (!value) {
    return null;
  }
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function buildTierConfigs(config: ParsedConfig): TierConfig[] {
  return TIER_PREFIXES.map(({ tier, prefix }) => ({
    tier,
    adapter: maskSecrets(config[`${prefix}_ADAPTER`] || "") || null,
    provider: maskSecrets(config[`${prefix}_PROVIDER`] || "") || null,
    model: maskSecrets(config[`${prefix}_MODEL`] || "") || null,
    effort: maskSecrets(config[`${prefix}_EFFORT`] || "") || null,
  }));
}

function buildSubscriptionPlans(config: ParsedConfig): SubscriptionPlan[] {
  return Object.keys(config)
    .filter((key) => key.endsWith("_ENABLED"))
    .map((key) => key.slice(0, -"_ENABLED".length))
    .sort()
    .map((baseKey) => ({
      key: baseKey.replace(/^ENGRAMA_/, "").toLowerCase(),
      enabled: config[`${baseKey}_ENABLED`] === "1",
      monthlyUsd: asNullableNumber(config[`${baseKey}_MONTHLY_USD`]),
      billingUnit: maskSecrets(config[`${baseKey}_BILLING_UNIT`] || "") || null,
      provider: maskSecrets(config[`${baseKey}_PROVIDER`] || "") || null,
      modelPattern: maskSecrets(config[`${baseKey}_MODEL_PATTERN`] || "") || null,
    }));
}

function buildPrices(config: ParsedConfig): PricePoint[] {
  const priceMap = new Map<string, PricePoint>();

  for (const key of Object.keys(config)) {
    const match = key.match(/^ENGRAMA_PRICE_(.+)_(INPUT|OUTPUT)_PER_1M_USD$/);
    if (!match) {
      continue;
    }

    const [, modelKey, direction] = match;
    const current = priceMap.get(modelKey) ?? {
      key: modelKey.toLowerCase(),
      inputPer1MUsd: null,
      outputPer1MUsd: null,
    };

    if (direction === "INPUT") {
      current.inputPer1MUsd = asNullableNumber(config[key]);
    } else {
      current.outputPer1MUsd = asNullableNumber(config[key]);
    }

    priceMap.set(modelKey, current);
  }

  return Array.from(priceMap.values()).sort((left, right) =>
    left.key.localeCompare(right.key),
  );
}

function draftFromConfig(config: ParsedConfig): ModelsConfigDraft {
  return {
    critiqueNoFallback: config.ENGRAMA_CRITIQUE_NO_FALLBACK === "1",
    tiers: TIER_PREFIXES.map(({ tier, prefix }) => ({
      tier,
      adapter: config[`${prefix}_ADAPTER`] || null,
      provider: config[`${prefix}_PROVIDER`] || null,
      model: config[`${prefix}_MODEL`] || null,
      effort: config[`${prefix}_EFFORT`] || null,
    })),
  };
}

function normalizeField(value: string | null): string {
  return value?.trim() ?? "";
}

function normalizeDraft(draft: ModelsConfigDraft): ModelsConfigDraft {
  return {
    critiqueNoFallback: Boolean(draft.critiqueNoFallback),
    tiers: TIER_PREFIXES.map(({ tier }) => {
      const source = draft.tiers.find((candidate) => candidate.tier === tier);
      return {
        tier,
        adapter: normalizeField(source?.adapter ?? null) || null,
        provider: normalizeField(source?.provider ?? null) || null,
        model: normalizeField(source?.model ?? null) || null,
        effort: normalizeField(source?.effort ?? null) || null,
      };
    }),
  };
}

function validateDraft(draft: ModelsConfigDraft): string[] {
  const errors: string[] = [];
  const normalized = normalizeDraft(draft);

  const incomingTiers = new Set(draft.tiers.map((tier) => tier.tier));
  for (const tier of incomingTiers) {
    if (!TIER_PREFIXES.some((item) => item.tier === tier)) {
      errors.push(`Tier invalido no payload: ${tier}`);
    }
  }

  for (const tier of normalized.tiers) {
    if (!tier.adapter) {
      errors.push(`${tier.tier}: adapter nao pode ficar vazio`);
    }
    if (!tier.provider) {
      errors.push(`${tier.tier}: provider nao pode ficar vazio`);
    }
    if (!tier.model) {
      errors.push(`${tier.tier}: model nao pode ficar vazio`);
    }
    if (!tier.effort) {
      errors.push(`${tier.tier}: effort nao pode ficar vazio`);
    }
  }

  const t4 = normalized.tiers.find((tier) => tier.tier === "T4");
  const t4Plus = normalized.tiers.find((tier) => tier.tier === "T4+");

  if (!t4?.model) {
    errors.push("critique/T4 nao pode ficar sem modelo");
  }
  if (!t4Plus?.model) {
    errors.push("authority/T4+ nao pode ficar sem modelo");
  }
  if (!normalized.critiqueNoFallback) {
    errors.push("critique/audit/authority nao podem permitir fallback silencioso");
  }

  return errors;
}

function modelValuesFromDraft(draft: ModelsConfigDraft): Record<string, string> {
  const normalized = normalizeDraft(draft);
  const values: Record<string, string> = {
    ENGRAMA_CRITIQUE_NO_FALLBACK: normalized.critiqueNoFallback ? "1" : "0",
  };

  for (const { tier, prefix } of TIER_PREFIXES) {
    const config = normalized.tiers.find((item) => item.tier === tier)!;
    values[`${prefix}_ADAPTER`] = config.adapter ?? "";
    values[`${prefix}_PROVIDER`] = config.provider ?? "";
    values[`${prefix}_MODEL`] = config.model ?? "";
    values[`${prefix}_EFFORT`] = config.effort ?? "";
  }

  return values;
}

export function serializeModelsConfig(
  originalContent: string,
  draft: ModelsConfigDraft,
): string {
  const desiredValues = modelValuesFromDraft(draft);
  const seen = new Set<string>();
  const lines = originalContent.split(/\r?\n/);
  const serialized = lines.map((line) => {
    const separatorIndex = line.indexOf("=");
    if (separatorIndex <= 0) {
      return line;
    }

    const key = line.slice(0, separatorIndex).trim();
    if (!(key in desiredValues)) {
      return line;
    }

    seen.add(key);
    return `${key}=${desiredValues[key]}`;
  });

  for (const key of MODEL_KEYS) {
    if (!seen.has(key)) {
      serialized.push(`${key}=${desiredValues[key] ?? ""}`);
    }
  }

  return serialized.join("\n").replace(/\n?$/, "\n");
}

export function diffModelsConfig(originalContent: string, nextContent: string): string {
  if (originalContent === nextContent) {
    return "No changes";
  }

  const originalLines = originalContent.split(/\r?\n/);
  const nextLines = nextContent.split(/\r?\n/);
  const maxLength = Math.max(originalLines.length, nextLines.length);
  const diff: string[] = [
    "--- .engrama/engine/config/models.conf",
    "+++ .engrama/engine/config/models.conf",
  ];

  for (let index = 0; index < maxLength; index += 1) {
    const before = originalLines[index];
    const after = nextLines[index];

    if (before === after) {
      continue;
    }

    if (before !== undefined) {
      diff.push(`- ${before}`);
    }
    if (after !== undefined) {
      diff.push(`+ ${after}`);
    }
  }

  return diff.join("\n");
}

function computeChangedKeys(
  originalContent: string,
  nextContent: string,
): string[] {
  const original = parseShellConfig(originalContent);
  const next = parseShellConfig(nextContent);

  return MODEL_KEYS.filter((key) => (original[key] ?? "") !== (next[key] ?? ""));
}

export function buildValidationResponse(
  originalContent: string,
  draft: ModelsConfigDraft,
): ModelsValidationResponse {
  const normalizedDraft = normalizeDraft(draft);
  const errors = validateDraft(normalizedDraft);
  const nextContent = serializeModelsConfig(originalContent, normalizedDraft);
  const changedKeys = computeChangedKeys(originalContent, nextContent);

  return {
    valid: errors.length === 0,
    errors,
    warnings:
      changedKeys.length === 0 ? ["Nenhuma alteracao detectada em models.conf"] : [],
    diff: diffModelsConfig(originalContent, nextContent),
    changedKeys,
    suggestedCommands: [...VALIDATION_COMMANDS],
  };
}

function timestampParts(date = new Date()) {
  const iso = date.toISOString();
  const month = iso.slice(0, 7);
  const backupStamp = iso
    .replace(/[-:]/g, "")
    .replace(/\.\d{3}Z$/, "Z")
    .replace("T", "-")
    .slice(0, 15);
  return { iso, month, backupStamp };
}

export async function loadModelsConfig(repoRoot: string): Promise<ModelsConfigResponse> {
  const modelsPath = assertSafeRepoPath(repoRoot, ".engrama/engine/config/models.conf");
  const subscriptionsPath = assertSafeRepoPath(
    repoRoot,
    ".engrama/engine/config/subscriptions.conf",
  );
  const pricesPath = assertSafeRepoPath(repoRoot, ".engrama/engine/config/prices.conf");

  const [modelsContent, subscriptionsContent, pricesContent] = await Promise.all([
    fs.readFile(modelsPath, "utf8"),
    fs.readFile(subscriptionsPath, "utf8"),
    fs.readFile(pricesPath, "utf8"),
  ]);

  const modelsConfig = parseShellConfig(modelsContent);
  const subscriptionsConfig = parseShellConfig(subscriptionsContent);
  const pricesConfig = parseShellConfig(pricesContent);

  return {
    defaults: {
      adapter: modelsConfig.ENGRAMA_DEFAULT_ADAPTER || null,
      provider: modelsConfig.ENGRAMA_DEFAULT_PROVIDER || null,
    },
    critiqueNoFallback: modelsConfig.ENGRAMA_CRITIQUE_NO_FALLBACK === "1",
    rolePolicy: [...ROLE_POLICY],
    tiers: buildTierConfigs(modelsConfig),
    subscriptions: buildSubscriptionPlans(subscriptionsConfig),
    prices: buildPrices(pricesConfig),
  };
}

export async function validateModelsConfig(
  repoRoot: string,
  draft: ModelsConfigDraft,
): Promise<ModelsValidationResponse> {
  const modelsPath = assertSafeRepoPath(repoRoot, ".engrama/engine/config/models.conf");
  const originalContent = await fs.readFile(modelsPath, "utf8");
  return buildValidationResponse(originalContent, draft);
}

export async function saveModelsConfig(
  repoRoot: string,
  draft: ModelsConfigDraft,
): Promise<ModelsSaveResponse> {
  const modelsPath = assertSafeWritePath(repoRoot, ".engrama/engine/config/models.conf");
  const originalContent = await fs.readFile(modelsPath, "utf8");
  const validation = buildValidationResponse(originalContent, draft);

  if (!validation.valid) {
    throw new Error(validation.errors.join(" | "));
  }

  const nextContent = serializeModelsConfig(originalContent, normalizeDraft(draft));
  const changedKeys = computeChangedKeys(originalContent, nextContent);
  const { iso, month, backupStamp } = timestampParts();

  const backupRelative = `.engrama/evidence/config-backups/models-${backupStamp}.conf`;
  const eventRelative = `.engrama/evidence/config-events/config-events-${month}.jsonl`;
  const backupPath = assertSafeWritePath(repoRoot, backupRelative);
  const eventPath = assertSafeWritePath(repoRoot, eventRelative);

  await fs.mkdir(path.dirname(backupPath), { recursive: true });
  await fs.mkdir(path.dirname(eventPath), { recursive: true });
  await fs.writeFile(backupPath, originalContent, "utf8");
  await fs.writeFile(modelsPath, nextContent, "utf8");

  const event = {
    schema: "engrama.config_event.v1",
    event_type: "models_conf_update",
    created_at: iso,
    actor: "local-ui",
    file: ".engrama/engine/config/models.conf",
    backup_path: backupRelative,
    changed_keys: changedKeys,
    validation_status: "passed",
    notes: "Updated via Engrama Observabilidade Cognitiva",
  };

  await fs.appendFile(eventPath, `${JSON.stringify(event)}\n`, "utf8");

  return {
    ...validation,
    saved: true,
    diff: diffModelsConfig(originalContent, nextContent),
    changedKeys,
    backupPath: backupRelative,
    eventPath: eventRelative,
    savedAt: iso,
  };
}

export { draftFromConfig };
