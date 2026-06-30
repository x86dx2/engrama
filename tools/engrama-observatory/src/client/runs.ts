import type { UsageRecord } from "../shared/types";

export type RunFilterState = {
  month: string;
  role: string;
  tier: string;
  adapter: string;
  provider: string;
  model: string;
  success: string;
  branch: string;
};

export function valueOrUnknown(value: string | null | undefined): string {
  return value || "unknown";
}

export function filterRuns(runs: UsageRecord[], filters: RunFilterState): UsageRecord[] {
  return runs.filter((run) => {
    if (filters.role !== "all" && valueOrUnknown(run.role) !== filters.role) {
      return false;
    }
    if (filters.tier !== "all" && valueOrUnknown(run.tier) !== filters.tier) {
      return false;
    }
    if (filters.adapter !== "all" && valueOrUnknown(run.adapter) !== filters.adapter) {
      return false;
    }
    if (filters.provider !== "all" && valueOrUnknown(run.provider) !== filters.provider) {
      return false;
    }
    if (filters.model !== "all" && valueOrUnknown(run.model) !== filters.model) {
      return false;
    }
    if (filters.branch !== "all" && run.branch !== filters.branch) {
      return false;
    }
    if (filters.success === "success" && run.success !== true) {
      return false;
    }
    if (filters.success === "failed" && run.success !== false) {
      return false;
    }
    return true;
  });
}
