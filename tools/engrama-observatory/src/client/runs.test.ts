import { describe, expect, it } from "vitest";

import type { UsageRecord } from "../shared/types";
import {
  filterRuns,
  getGovernanceIndicator,
  summarizeGovernance,
  type RunFilterState,
} from "./runs";

function makeRun(overrides: Partial<UsageRecord> = {}): UsageRecord {
  return {
    schema: "engrama.usage.v1",
    run_id: "r1",
    project: "engrama",
    branch: "main",
    role: "execute",
    tier: "T2",
    adapter: "codex",
    provider: "openai",
    surface: "exec",
    model: "gpt-5.4",
    configured_model: "gpt-5.4",
    observed_model: "gpt-5.4",
    effort: "medium",
    billing_mode: "subscription",
    plan: "codex-pro",
    started_at: "2026-06-30T11:00:00Z",
    finished_at: "2026-06-30T11:01:00Z",
    duration_seconds: 60,
    input_tokens: 10,
    output_tokens: 5,
    cached_input_tokens: 0,
    total_tokens: 15,
    turns: 1,
    estimated_api_cost_usd: null,
    allocated_subscription_cost_usd: 12,
    governance_mode: null,
    role_contract: null,
    role_contract_hash: null,
    routing_reason: "x",
    transcript_path: "t.md",
    codex_session: "s1",
    success: true,
    ...overrides,
  };
}

const defaultFilters: RunFilterState = {
  month: "current",
  role: "all",
  tier: "all",
  adapter: "all",
  provider: "all",
  model: "all",
  success: "all",
  branch: "all",
  governanceMode: "all",
};

describe("governance run helpers", () => {
  it("counts runs with role_contract as governed", () => {
    const runs = [
      makeRun({
        run_id: "contract",
        role_contract: ".engrama/memory/governance/roles/execute.md",
        role_contract_hash: "abc",
        governance_mode: "role-contract",
      }),
      makeRun({ run_id: "legacy", governance_mode: "legacy/defaulted" }),
    ];

    expect(summarizeGovernance(runs)).toEqual({
      governedRuns: 1,
      governedShare: 50,
      legacyDefaultedRuns: 1,
    });
  });

  it("treats older ledgers without governance fields as unknown, not broken", () => {
    const runs = [makeRun({ governance_mode: null, role_contract: null })];

    expect(summarizeGovernance(runs)).toEqual({
      governedRuns: 0,
      governedShare: 0,
      legacyDefaultedRuns: 0,
    });
    expect(getGovernanceIndicator(runs[0]!)).toBe("unknown");
  });

  it("labels legacy/defaulted runs as legacy", () => {
    const run = makeRun({
      governance_mode: "legacy/defaulted",
      role_contract: null,
      role_contract_hash: null,
    });

    expect(getGovernanceIndicator(run)).toBe("legacy");
  });

  it("filters runs by governance_mode when requested", () => {
    const runs = [
      makeRun({
        run_id: "contract",
        governance_mode: "role-contract",
        role_contract: ".engrama/memory/governance/roles/execute.md",
      }),
      makeRun({
        run_id: "legacy",
        governance_mode: "legacy/defaulted",
        role_contract: null,
      }),
      makeRun({
        run_id: "unknown",
        governance_mode: null,
        role_contract: null,
      }),
    ];

    expect(
      filterRuns(runs, { ...defaultFilters, governanceMode: "legacy/defaulted" }).map(
        (run) => run.run_id,
      ),
    ).toEqual(["legacy"]);
    expect(
      filterRuns(runs, { ...defaultFilters, governanceMode: "unknown" }).map(
        (run) => run.run_id,
      ),
    ).toEqual(["unknown"]);
  });
});
