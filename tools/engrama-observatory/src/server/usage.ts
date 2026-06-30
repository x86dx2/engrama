import fs from "node:fs/promises";

import type {
  BreakdownItem,
  ConfigEvent,
  TimelinePoint,
  UsageRecord,
  UsageSummary,
} from "../shared/types.js";
import { maskSecrets } from "./maskSecrets.js";
import { assertSafeRepoPath } from "./repo.js";

type MutableBreakdown = {
  key: string;
  count: number;
  failures: number;
  turns: number;
  knownTokens: number;
  estimatedApiCostUsd: number;
  allocatedSubscriptionCostUsd: number;
};

type MutableTimelinePoint = {
  day: string;
  runs: number;
  failures: number;
  t4OrHigher: number;
  knownTokens: number;
  estimatedApiCostUsd: number;
  allocatedSubscriptionCostUsd: number;
};

function currentMonthUtc(): string {
  return new Date().toISOString().slice(0, 7);
}

function resolveMonth(requested?: string): string {
  if (!requested || requested === "current") {
    return currentMonthUtc();
  }

  if (!/^\d{4}-\d{2}$/.test(requested)) {
    throw new Error(`Invalid month: ${requested}`);
  }

  return requested;
}

function asNullableNumber(value: unknown): number | null {
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}

function asNullableString(value: unknown): string | null {
  return typeof value === "string" && value.length > 0 ? maskSecrets(value) : null;
}

function asNullableBoolean(value: unknown): boolean | null {
  return typeof value === "boolean" ? value : null;
}

function normalizeRecord(raw: Record<string, unknown>): UsageRecord {
  return {
    schema: typeof raw.schema === "string" ? raw.schema : "unknown",
    run_id: typeof raw.run_id === "string" ? raw.run_id : "unknown",
    project: typeof raw.project === "string" ? raw.project : "unknown",
    branch: typeof raw.branch === "string" ? raw.branch : "unknown",
    role: asNullableString(raw.role),
    tier: asNullableString(raw.tier),
    adapter: asNullableString(raw.adapter),
    provider: asNullableString(raw.provider),
    surface: asNullableString(raw.surface),
    model: asNullableString(raw.model),
    configured_model: asNullableString(raw.configured_model),
    observed_model: asNullableString(raw.observed_model),
    effort: asNullableString(raw.effort),
    billing_mode: asNullableString(raw.billing_mode),
    plan: asNullableString(raw.plan),
    started_at: asNullableString(raw.started_at),
    finished_at: asNullableString(raw.finished_at),
    duration_seconds: asNullableNumber(raw.duration_seconds),
    input_tokens: asNullableNumber(raw.input_tokens),
    output_tokens: asNullableNumber(raw.output_tokens),
    cached_input_tokens: asNullableNumber(raw.cached_input_tokens),
    total_tokens: asNullableNumber(raw.total_tokens),
    turns: asNullableNumber(raw.turns),
    estimated_api_cost_usd: asNullableNumber(raw.estimated_api_cost_usd),
    allocated_subscription_cost_usd: asNullableNumber(
      raw.allocated_subscription_cost_usd,
    ),
    governance_mode: asNullableString(raw.governance_mode),
    role_contract: asNullableString(raw.role_contract),
    role_contract_hash: asNullableString(raw.role_contract_hash),
    routing_reason: asNullableString(raw.routing_reason),
    transcript_path: asNullableString(raw.transcript_path),
    codex_session: asNullableString(raw.codex_session),
    success: asNullableBoolean(raw.success),
  };
}

export function parseUsageLedger(content: string): {
  runs: UsageRecord[];
  invalidLines: number;
} {
  const runs: UsageRecord[] = [];
  let invalidLines = 0;

  for (const rawLine of content.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line) {
      continue;
    }

    try {
      const parsed = JSON.parse(line) as Record<string, unknown>;
      runs.push(normalizeRecord(parsed));
    } catch {
      invalidLines += 1;
    }
  }

  return { runs, invalidLines };
}

function summarizeBreakdown(
  runs: UsageRecord[],
  picker: (run: UsageRecord) => string | null,
): BreakdownItem[] {
  const byKey = new Map<string, MutableBreakdown>();

  for (const run of runs) {
    const key = picker(run) || "unknown";
    const current = byKey.get(key) ?? {
      key,
      count: 0,
      failures: 0,
      turns: 0,
      knownTokens: 0,
      estimatedApiCostUsd: 0,
      allocatedSubscriptionCostUsd: 0,
    };

    current.count += 1;
    current.failures += run.success === false ? 1 : 0;
    current.turns += run.turns ?? 0;
    current.knownTokens += run.total_tokens ?? 0;
    current.estimatedApiCostUsd += run.estimated_api_cost_usd ?? 0;
    current.allocatedSubscriptionCostUsd += run.allocated_subscription_cost_usd ?? 0;

    byKey.set(key, current);
  }

  return Array.from(byKey.values())
    .map((item) => ({
      ...item,
      knownTokens: item.knownTokens > 0 ? item.knownTokens : null,
      estimatedApiCostUsd:
        item.estimatedApiCostUsd > 0 ? item.estimatedApiCostUsd : null,
      allocatedSubscriptionCostUsd:
        item.allocatedSubscriptionCostUsd > 0
          ? item.allocatedSubscriptionCostUsd
          : null,
    }))
    .sort((left, right) => right.count - left.count || left.key.localeCompare(right.key));
}

function rankTier(tier: string | null): number {
  switch (tier) {
    case "T1":
      return 1;
    case "T2":
      return 2;
    case "T3":
      return 3;
    case "T4":
      return 4;
    case "T4+":
      return 5;
    default:
      return 0;
  }
}

function summarizeTimeline(runs: UsageRecord[]): TimelinePoint[] {
  const byDay = new Map<string, MutableTimelinePoint>();

  for (const run of runs) {
    const day = run.started_at?.slice(0, 10) || "unknown";
    const current = byDay.get(day) ?? {
      day,
      runs: 0,
      failures: 0,
      t4OrHigher: 0,
      knownTokens: 0,
      estimatedApiCostUsd: 0,
      allocatedSubscriptionCostUsd: 0,
    };

    current.runs += 1;
    current.failures += run.success === false ? 1 : 0;
    current.t4OrHigher += rankTier(run.tier) >= 4 ? 1 : 0;
    current.knownTokens += run.total_tokens ?? 0;
    current.estimatedApiCostUsd += run.estimated_api_cost_usd ?? 0;
    current.allocatedSubscriptionCostUsd += run.allocated_subscription_cost_usd ?? 0;
    byDay.set(day, current);
  }

  return Array.from(byDay.values())
    .map((item) => ({
      ...item,
      knownTokens: item.knownTokens > 0 ? item.knownTokens : null,
      estimatedApiCostUsd:
        item.estimatedApiCostUsd > 0 ? item.estimatedApiCostUsd : null,
      allocatedSubscriptionCostUsd:
        item.allocatedSubscriptionCostUsd > 0
          ? item.allocatedSubscriptionCostUsd
          : null,
    }))
    .sort((left, right) => left.day.localeCompare(right.day));
}

function parseConfigContent(content: string): Record<string, string> {
  const config: Record<string, string> = {};

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

function summarizeSubscription(runs: UsageRecord[], subscriptions: Record<string, string>) {
  const enabledPlans = Object.keys(subscriptions)
    .filter((key) => key.endsWith("_ENABLED") && subscriptions[key] === "1")
    .map((key) => key.slice(0, -"_ENABLED".length));

  let totalMonthlyUsd = 0;
  let allocatedMonthlyUsd = 0;
  let totalTurns = 0;
  let totalRuns = 0;

  for (const baseKey of enabledPlans) {
    const monthlyUsd = Number(subscriptions[`${baseKey}_MONTHLY_USD`] || "");
    if (Number.isFinite(monthlyUsd)) {
      totalMonthlyUsd += monthlyUsd;
    }

    const provider = subscriptions[`${baseKey}_PROVIDER`];
    const pattern = subscriptions[`${baseKey}_MODEL_PATTERN`];
    const planKey = baseKey.replace(/^ENGRAMA_/, "").toLowerCase().replaceAll("_", "-");

    const matchingRuns = runs.filter((run) => {
      if (run.plan !== planKey) {
        return false;
      }
      if (!provider || run.provider !== provider) {
        return false;
      }
      if (!pattern || !run.model) {
        return false;
      }

      const regex = new RegExp(
        `^${pattern.replace(/[.+^${}()|[\]\\]/g, "\\$&").replaceAll("*", ".*")}$`,
      );
      return regex.test(run.model);
    });

    if (matchingRuns.length > 0 && Number.isFinite(monthlyUsd)) {
      allocatedMonthlyUsd += monthlyUsd;
      totalRuns += matchingRuns.length;
      totalTurns += matchingRuns.reduce((sum, run) => sum + (run.turns ?? 0), 0);
    }
  }

  return {
    totalMonthlyUsd: totalMonthlyUsd > 0 ? totalMonthlyUsd : null,
    allocatedMonthlyUsd: allocatedMonthlyUsd > 0 ? allocatedMonthlyUsd : null,
    effectiveCostPerRunUsd:
      allocatedMonthlyUsd > 0 && totalRuns > 0
        ? allocatedMonthlyUsd / totalRuns
        : null,
    effectiveCostPerTurnUsd:
      allocatedMonthlyUsd > 0 && totalTurns > 0
        ? allocatedMonthlyUsd / totalTurns
        : null,
  };
}

export async function loadUsageSummary(
  repoRoot: string,
  requestedMonth?: string,
): Promise<UsageSummary> {
  const month = resolveMonth(requestedMonth);
  const usagePath = assertSafeRepoPath(
    repoRoot,
    `.engrama/evidence/usage/usage-${month}.jsonl`,
  );
  const subscriptionsPath = assertSafeRepoPath(
    repoRoot,
    ".engrama/engine/config/subscriptions.conf",
  );

  let ledgerContent = "";
  try {
    ledgerContent = await fs.readFile(usagePath, "utf8");
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code !== "ENOENT") {
      throw error;
    }
  }

  const { runs, invalidLines } = parseUsageLedger(ledgerContent);
  const subscriptionsContent = await fs.readFile(subscriptionsPath, "utf8");
  const subscription = summarizeSubscription(
    runs,
    parseConfigContent(subscriptionsContent),
  );

  const warnings: string[] = [];
  if (invalidLines > 0) {
    warnings.push(`${invalidLines} line(s) of usage JSONL were ignored`);
  }
  if (runs.length === 0) {
    warnings.push("No usage ledger found for the selected month");
  }

  const knownTokensSum = runs.reduce(
    (sum, run) => sum + (run.total_tokens ?? 0),
    0,
  );
  const apiKnownRuns = runs.filter(
    (run) => run.estimated_api_cost_usd !== null,
  );
  const apiTotal = apiKnownRuns.reduce(
    (sum, run) => sum + (run.estimated_api_cost_usd ?? 0),
    0,
  );

  return {
    month,
    runs,
    invalidLines,
    counts: {
      runs: runs.length,
      turns: runs.reduce((sum, run) => sum + (run.turns ?? 0), 0),
      knownTokens: knownTokensSum > 0 ? knownTokensSum : null,
      unknownTokenRuns: runs.filter((run) => run.total_tokens === null).length,
      failures: runs.filter((run) => run.success === false).length,
      lastRunAt: runs
        .map((run) => run.finished_at ?? run.started_at)
        .filter((value): value is string => Boolean(value))
        .sort()
        .at(-1) ?? null,
    },
    breakdowns: {
      role: summarizeBreakdown(runs, (run) => run.role),
      tier: summarizeBreakdown(runs, (run) => run.tier),
      model: summarizeBreakdown(runs, (run) => run.model),
      adapter: summarizeBreakdown(runs, (run) => run.adapter),
      provider: summarizeBreakdown(runs, (run) => run.provider),
      timeline: summarizeTimeline(runs),
    },
    subscription,
    apiEstimate: {
      knownRuns: apiKnownRuns.length,
      totalUsd: apiKnownRuns.length > 0 ? apiTotal : null,
    },
    warnings,
  };
}

export async function loadConfigEvents(
  repoRoot: string,
  requestedMonth?: string,
): Promise<{ month: string; events: ConfigEvent[]; invalidLines: number }> {
  const month = resolveMonth(requestedMonth);
  const eventsPath = assertSafeRepoPath(
    repoRoot,
    `.engrama/evidence/config-events/config-events-${month}.jsonl`,
  );

  let eventsContent = "";
  try {
    eventsContent = await fs.readFile(eventsPath, "utf8");
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code !== "ENOENT") {
      throw error;
    }
  }

  let invalidLines = 0;
  const events: ConfigEvent[] = [];

  for (const rawLine of eventsContent.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line) {
      continue;
    }

    try {
      const parsed = JSON.parse(line) as Record<string, unknown>;
      events.push({
        raw: parsed,
        created_at: asNullableString(parsed.created_at),
        event_type: asNullableString(parsed.event_type),
        actor: asNullableString(parsed.actor),
        file: asNullableString(parsed.file),
        backup_path: asNullableString(parsed.backup_path),
        changed_keys: Array.isArray(parsed.changed_keys)
          ? parsed.changed_keys
              .map((item) => (typeof item === "string" ? maskSecrets(item) : null))
              .filter((item): item is string => Boolean(item))
          : [],
        validation_status: asNullableString(parsed.validation_status),
        notes: asNullableString(parsed.notes),
      });
    } catch {
      invalidLines += 1;
    }
  }

  return { month, events, invalidLines };
}
