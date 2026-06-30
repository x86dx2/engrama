import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";

import { afterEach, describe, expect, it } from "vitest";

import {
  buildValidationResponse,
  parseShellConfig,
  saveModelsConfig,
  serializeModelsConfig,
} from "./config";
import type { ModelsConfigDraft } from "../shared/types";

const baseModelsConf = `# Runtime model routing defaults for the Engrama executor bridge.
ENGRAMA_DEFAULT_ADAPTER=codex
ENGRAMA_DEFAULT_PROVIDER=openai
ENGRAMA_CRITIQUE_NO_FALLBACK=1
ENGRAMA_T1_ADAPTER=codex
ENGRAMA_T1_PROVIDER=openai
ENGRAMA_T1_MODEL=gpt-5.4-mini
ENGRAMA_T1_EFFORT=low
ENGRAMA_T2_ADAPTER=codex
ENGRAMA_T2_PROVIDER=openai
ENGRAMA_T2_MODEL=gpt-5.4
ENGRAMA_T2_EFFORT=medium
ENGRAMA_T3_ADAPTER=codex
ENGRAMA_T3_PROVIDER=openai
ENGRAMA_T3_MODEL=gpt-5.4
ENGRAMA_T3_EFFORT=high
ENGRAMA_T4_ADAPTER=codex
ENGRAMA_T4_PROVIDER=openai
ENGRAMA_T4_MODEL=gpt-5.5
ENGRAMA_T4_EFFORT=high
ENGRAMA_T4_PLUS_ADAPTER=codex
ENGRAMA_T4_PLUS_PROVIDER=openai
ENGRAMA_T4_PLUS_MODEL=gpt-5.5
ENGRAMA_T4_PLUS_EFFORT=xhigh
`;

const draft: ModelsConfigDraft = {
  critiqueNoFallback: true,
  tiers: [
    { tier: "T1", adapter: "codex", provider: "openai", model: "gpt-5.4-mini", effort: "low" },
    { tier: "T2", adapter: "codex", provider: "openai", model: "gpt-5.4", effort: "medium" },
    { tier: "T3", adapter: "codex", provider: "openai", model: "gpt-5.4", effort: "high" },
    { tier: "T4", adapter: "codex", provider: "openai", model: "gpt-5.5", effort: "high" },
    { tier: "T4+", adapter: "codex", provider: "openai", model: "gpt-5.5", effort: "xhigh" },
  ],
};

const tmpDirs: string[] = [];

afterEach(async () => {
  await Promise.all(tmpDirs.splice(0).map((dir) => fs.rm(dir, { recursive: true, force: true })));
});

async function makeRepo() {
  const repoRoot = await fs.mkdtemp(path.join(os.tmpdir(), "engrama-observatory-"));
  tmpDirs.push(repoRoot);
  await fs.mkdir(path.join(repoRoot, ".engrama/engine/config"), { recursive: true });
  await fs.writeFile(
    path.join(repoRoot, ".engrama/engine/config/models.conf"),
    baseModelsConf,
    "utf8",
  );
  return repoRoot;
}

describe("config helpers", () => {
  it("parses shell-style key value pairs without executing them", () => {
    const parsed = parseShellConfig(`
      # comment
      ENGRAMA_T2_MODEL=gpt-5.4
      ENGRAMA_CODEX_PRO_MODEL_PATTERN='gpt-5*'
      ENGRAMA_EMPTY=
    `);

    expect(parsed.ENGRAMA_T2_MODEL).toBe("gpt-5.4");
    expect(parsed.ENGRAMA_CODEX_PRO_MODEL_PATTERN).toBe("gpt-5*");
    expect(parsed.ENGRAMA_EMPTY).toBe("");
  });

  it("serializes changes while preserving known keys", () => {
    const nextContent = serializeModelsConfig(baseModelsConf, {
      ...draft,
      tiers: draft.tiers.map((tier) =>
        tier.tier === "T2" ? { ...tier, model: "kimi" } : tier,
      ),
    });

    expect(nextContent).toContain("ENGRAMA_T2_MODEL=kimi");
    expect(nextContent).toContain("ENGRAMA_T4_MODEL=gpt-5.5");
  });

  it("blocks critique/authority unsafe drafts and reports diff", () => {
    const result = buildValidationResponse(baseModelsConf, {
      ...draft,
      critiqueNoFallback: false,
      tiers: draft.tiers.map((tier) =>
        tier.tier === "T4+" ? { ...tier, model: "" } : tier,
      ),
    });

    expect(result.valid).toBe(false);
    expect(result.errors.join(" ")).toMatch(/fallback silencioso/i);
    expect(result.errors.join(" ")).toMatch(/authority\/T4\+/i);
    expect(result.diff).toMatch(/ENGRAMA_CRITIQUE_NO_FALLBACK=0/);
  });

  it("creates backup, writes models.conf and appends config event", async () => {
    const repoRoot = await makeRepo();
    const result = await saveModelsConfig(repoRoot, {
      ...draft,
      tiers: draft.tiers.map((tier) =>
        tier.tier === "T3" ? { ...tier, model: "kimi" } : tier,
      ),
    });

    const savedConfig = await fs.readFile(
      path.join(repoRoot, ".engrama/engine/config/models.conf"),
      "utf8",
    );
    const backupContent = await fs.readFile(path.join(repoRoot, result.backupPath), "utf8");
    const eventContent = await fs.readFile(path.join(repoRoot, result.eventPath), "utf8");

    expect(result.saved).toBe(true);
    expect(result.changedKeys).toContain("ENGRAMA_T3_MODEL");
    expect(savedConfig).toContain("ENGRAMA_T3_MODEL=kimi");
    expect(backupContent).toBe(baseModelsConf);
    expect(eventContent).toContain('"event_type":"models_conf_update"');
  });
});
