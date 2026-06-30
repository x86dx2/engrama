import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";

import { afterEach, describe, expect, it } from "vitest";

import { loadConfigEvents, loadUsageSummary, parseUsageLedger } from "./usage";

const tmpDirs: string[] = [];

afterEach(async () => {
  await Promise.all(tmpDirs.splice(0).map((dir) => fs.rm(dir, { recursive: true, force: true })));
});

async function makeRepo() {
  const repoRoot = await fs.mkdtemp(path.join(os.tmpdir(), "engrama-usage-"));
  tmpDirs.push(repoRoot);
  await fs.mkdir(path.join(repoRoot, ".engrama/evidence/usage"), { recursive: true });
  await fs.mkdir(path.join(repoRoot, ".engrama/engine/config"), { recursive: true });
  await fs.writeFile(
    path.join(repoRoot, ".engrama/engine/config/subscriptions.conf"),
    `ENGRAMA_CODEX_PRO_ENABLED=1
ENGRAMA_CODEX_PRO_MONTHLY_USD=100
ENGRAMA_CODEX_PRO_BILLING_UNIT=turn
ENGRAMA_CODEX_PRO_PROVIDER=openai
ENGRAMA_CODEX_PRO_MODEL_PATTERN='gpt-5*'
`,
    "utf8",
  );
  return repoRoot;
}

describe("usage helpers", () => {
  it("keeps valid lines and ignores invalid JSONL", () => {
    const { runs, invalidLines } = parseUsageLedger(`
{"schema":"engrama.usage.v1","run_id":"r1","project":"engrama","branch":"main","role":"critique","tier":"T4","adapter":"codex","provider":"openai","surface":"exec","model":"gpt-5.5","configured_model":"gpt-5.5","observed_model":null,"effort":"high","billing_mode":"subscription","plan":"codex-pro","started_at":"2026-06-30T16:49:35Z","finished_at":"2026-06-30T16:49:44Z","duration_seconds":9,"input_tokens":16497,"output_tokens":33,"cached_input_tokens":4992,"total_tokens":16530,"turns":1,"estimated_api_cost_usd":null,"allocated_subscription_cost_usd":null,"routing_reason":"x","transcript_path":"t.md","codex_session":"s1","success":true}
not-json
`);

    expect(runs).toHaveLength(1);
    expect(runs[0]?.role).toBe("critique");
    expect(runs[0]?.total_tokens).toBe(16530);
    expect(invalidLines).toBe(1);
  });

  it("normalizes missing fields to unknown or null without crashing", () => {
    const { runs } = parseUsageLedger(`
{"schema":"engrama.usage.v1","run_id":"r2","project":"engrama","branch":"main"}
`);

    expect(runs[0]?.role).toBeNull();
    expect(runs[0]?.model).toBeNull();
    expect(runs[0]?.project).toBe("engrama");
  });

  it("ignores unknown extra fields without breaking base parsing", () => {
    const { runs, invalidLines } = parseUsageLedger(`
{"schema":"engrama.usage.v1","run_id":"r3","project":"engrama","branch":"main","role":"critique","tier":"T4","adapter":"codex","provider":"openai","surface":"exec","model":"gpt-5.5","configured_model":"gpt-5.5","observed_model":null,"effort":"xhigh","billing_mode":"subscription","plan":"codex-pro","started_at":"2026-06-30T16:49:35Z","finished_at":"2026-06-30T16:49:44Z","duration_seconds":9,"input_tokens":16497,"output_tokens":33,"cached_input_tokens":4992,"total_tokens":16530,"turns":1,"estimated_api_cost_usd":null,"allocated_subscription_cost_usd":null,"routing_reason":"x","extra_flag":"future-field","trace_id":"abc123","transcript_path":"t.md","codex_session":"s1","success":true}
`);

    expect(invalidLines).toBe(0);
    expect(runs).toHaveLength(1);
    expect(runs[0]?.role).toBe("critique");
    expect(runs[0]?.tier).toBe("T4");
    expect(runs[0]?.total_tokens).toBe(16530);
  });

  it("aggregates role, tier, model, failures, turns and known tokens", async () => {
    const repoRoot = await makeRepo();
    await fs.writeFile(
      path.join(repoRoot, ".engrama/evidence/usage/usage-2026-06.jsonl"),
      `{"schema":"engrama.usage.v1","run_id":"r1","project":"engrama","branch":"main","role":"critique","tier":"T4","adapter":"codex","provider":"openai","surface":"exec","model":"gpt-5.5","configured_model":"gpt-5.5","observed_model":null,"effort":"high","billing_mode":"subscription","plan":"codex-pro","started_at":"2026-06-30T10:00:00Z","finished_at":"2026-06-30T10:01:00Z","duration_seconds":60,"input_tokens":10,"output_tokens":5,"cached_input_tokens":0,"total_tokens":15,"turns":1,"estimated_api_cost_usd":0.002,"allocated_subscription_cost_usd":50,"routing_reason":"x","transcript_path":"a.md","codex_session":"s1","success":true}
{"schema":"engrama.usage.v1","run_id":"r2","project":"engrama","branch":"main","role":"execute","tier":"T2","adapter":"codex","provider":"openai","surface":"exec","model":"gpt-5.4","configured_model":"gpt-5.4","observed_model":"gpt-5.5","effort":"medium","billing_mode":"subscription","plan":"codex-pro","started_at":"2026-06-30T11:00:00Z","finished_at":"2026-06-30T11:02:00Z","duration_seconds":120,"input_tokens":null,"output_tokens":null,"cached_input_tokens":null,"total_tokens":null,"turns":2,"estimated_api_cost_usd":null,"allocated_subscription_cost_usd":50,"routing_reason":"token=super-secret-value","transcript_path":"b.md","codex_session":"s2","success":false}
`,
      "utf8",
    );

    const summary = await loadUsageSummary(repoRoot, "2026-06");

    expect(summary.counts.runs).toBe(2);
    expect(summary.counts.turns).toBe(3);
    expect(summary.counts.knownTokens).toBe(15);
    expect(summary.counts.failures).toBe(1);
    expect(summary.breakdowns.role[0]?.key).toBe("critique");
    expect(summary.breakdowns.role[0]?.estimatedApiCostUsd).toBe(0.002);
    expect(summary.breakdowns.role[0]?.allocatedSubscriptionCostUsd).toBe(50);
    expect(summary.breakdowns.tier.map((item) => item.key)).toContain("T4");
    expect(summary.breakdowns.model.map((item) => item.key)).toContain("gpt-5.5");
    expect(summary.breakdowns.timeline[0]?.estimatedApiCostUsd).toBe(0.002);
    expect(summary.breakdowns.timeline[0]?.allocatedSubscriptionCostUsd).toBe(100);
    expect(summary.apiEstimate.knownRuns).toBe(1);
    expect(summary.runs[1]?.routing_reason).toContain("supe****alue");
  });

  it("loads config events and keeps changed keys", async () => {
    const repoRoot = await makeRepo();
    await fs.mkdir(path.join(repoRoot, ".engrama/evidence/config-events"), {
      recursive: true,
    });
    await fs.writeFile(
      path.join(repoRoot, ".engrama/evidence/config-events/config-events-2026-06.jsonl"),
      `{"schema":"engrama.config_event.v1","event_type":"models_conf_update","created_at":"2026-06-30T18:42:10Z","actor":"local-ui","file":".engrama/engine/config/models.conf","backup_path":".engrama/evidence/config-backups/models-20260630-184210.conf","changed_keys":["ENGRAMA_T2_MODEL","ENGRAMA_T3_MODEL"],"validation_status":"passed","notes":"Updated via local UI"}
not-json
`,
      "utf8",
    );

    const events = await loadConfigEvents(repoRoot, "2026-06");

    expect(events.invalidLines).toBe(1);
    expect(events.events[0]?.changed_keys).toEqual([
      "ENGRAMA_T2_MODEL",
      "ENGRAMA_T3_MODEL",
    ]);
    expect(events.events[0]?.notes).toBe("Updated via local UI");
  });
});
