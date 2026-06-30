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
  governanceMode: string;
};

export type GovernanceIndicator = "contract" | "legacy" | "unknown";

export type GovernanceSummary = {
  governedRuns: number;
  governedShare: number | null;
  legacyDefaultedRuns: number;
};

export function valueOrUnknown(value: string | null | undefined): string {
  return value || "unknown";
}

export function getGovernanceModeValue(run: UsageRecord): string {
  return valueOrUnknown(run.governance_mode);
}

export function isLegacyDefaultedGovernance(value: string | null | undefined): boolean {
  return value === "legacy/defaulted";
}

export function getGovernanceIndicator(run: UsageRecord): GovernanceIndicator {
  if (run.role_contract) {
    return "contract";
  }

  if (isLegacyDefaultedGovernance(run.governance_mode)) {
    return "legacy";
  }

  return "unknown";
}

export function summarizeGovernance(runs: UsageRecord[]): GovernanceSummary {
  const governedRuns = runs.filter((run) => Boolean(run.role_contract)).length;
  const legacyDefaultedRuns = runs.filter((run) =>
    isLegacyDefaultedGovernance(run.governance_mode),
  ).length;

  return {
    governedRuns,
    governedShare: runs.length > 0 ? (governedRuns / runs.length) * 100 : null,
    legacyDefaultedRuns,
  };
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
    if (
      filters.governanceMode !== "all" &&
      getGovernanceModeValue(run) !== filters.governanceMode
    ) {
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
