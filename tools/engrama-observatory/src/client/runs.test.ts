import { describe, expect, it } from "vitest";

import type { UsageRecord } from "../shared/types";
import { filterRuns, type RunFilterState, valueOrUnknown } from "./runs";

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
};

describe("run helpers", () => {
  it("normalizes empty values to unknown", () => {
    expect(valueOrUnknown(null)).toBe("unknown");
    expect(valueOrUnknown("")).toBe("unknown");
    expect(valueOrUnknown("execute")).toBe("execute");
  });

  it("filters runs by base dimensions without governance metadata", () => {
    const runs = [
      makeRun({
        run_id: "execute-ok",
        role: "execute",
        success: true,
      }),
      makeRun({
        run_id: "review-fail",
        role: "review",
        success: false,
        tier: "T3",
      }),
      makeRun({
        run_id: "execute-fail",
        role: "execute",
        success: false,
      }),
    ];

    expect(
      filterRuns(runs, { ...defaultFilters, role: "execute" }).map(
        (run) => run.run_id,
      ),
    ).toEqual(["execute-ok", "execute-fail"]);
    expect(
      filterRuns(runs, { ...defaultFilters, success: "failed" }).map(
        (run) => run.run_id,
      ),
    ).toEqual(["review-fail", "execute-fail"]);
  });
});
