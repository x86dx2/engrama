export type UsageRecord = {
  schema: string;
  run_id: string;
  project: string;
  branch: string;
  role: string | null;
  tier: string | null;
  adapter: string | null;
  provider: string | null;
  surface: string | null;
  model: string | null;
  configured_model: string | null;
  observed_model: string | null;
  effort: string | null;
  billing_mode: string | null;
  plan: string | null;
  started_at: string | null;
  finished_at: string | null;
  duration_seconds: number | null;
  input_tokens: number | null;
  output_tokens: number | null;
  cached_input_tokens: number | null;
  total_tokens: number | null;
  turns: number | null;
  estimated_api_cost_usd: number | null;
  allocated_subscription_cost_usd: number | null;
  routing_reason: string | null;
  transcript_path: string | null;
  codex_session: string | null;
  success: boolean | null;
};

export type UsageSummary = {
  month: string;
  runs: UsageRecord[];
  invalidLines: number;
  counts: {
    runs: number;
    turns: number;
    knownTokens: number | null;
    unknownTokenRuns: number;
    failures: number;
    lastRunAt: string | null;
  };
  breakdowns: {
    role: BreakdownItem[];
    tier: BreakdownItem[];
    model: BreakdownItem[];
    adapter: BreakdownItem[];
    provider: BreakdownItem[];
    timeline: TimelinePoint[];
  };
  subscription: {
    totalMonthlyUsd: number | null;
    allocatedMonthlyUsd: number | null;
    effectiveCostPerRunUsd: number | null;
    effectiveCostPerTurnUsd: number | null;
  };
  apiEstimate: {
    knownRuns: number;
    totalUsd: number | null;
  };
  warnings: string[];
};

export type BreakdownItem = {
  key: string;
  count: number;
  failures: number;
  turns: number;
  knownTokens: number | null;
  estimatedApiCostUsd: number | null;
  allocatedSubscriptionCostUsd: number | null;
};

export type TimelinePoint = {
  day: string;
  runs: number;
  failures: number;
  t4OrHigher: number;
  knownTokens: number | null;
  estimatedApiCostUsd: number | null;
  allocatedSubscriptionCostUsd: number | null;
};

export type TierConfig = {
  tier: string;
  adapter: string | null;
  provider: string | null;
  model: string | null;
  effort: string | null;
};

export type ModelsConfigResponse = {
  defaults: {
    adapter: string | null;
    provider: string | null;
  };
  critiqueNoFallback: boolean;
  rolePolicy: Array<{ role: string; minimumTier: string }>;
  tiers: TierConfig[];
  subscriptions: SubscriptionPlan[];
  prices: PricePoint[];
};

export type ModelsConfigDraft = {
  critiqueNoFallback: boolean;
  tiers: TierConfig[];
};

export type ModelsValidationResponse = {
  valid: boolean;
  errors: string[];
  warnings: string[];
  diff: string;
  changedKeys: string[];
  suggestedCommands: string[];
};

export type ModelsSaveResponse = ModelsValidationResponse & {
  saved: boolean;
  backupPath: string;
  eventPath: string;
  savedAt: string;
};

export type SubscriptionPlan = {
  key: string;
  enabled: boolean;
  monthlyUsd: number | null;
  billingUnit: string | null;
  provider: string | null;
  modelPattern: string | null;
};

export type PricePoint = {
  key: string;
  inputPer1MUsd: number | null;
  outputPer1MUsd: number | null;
};

export type ConfigEvent = {
  raw: Record<string, unknown>;
  created_at: string | null;
  event_type: string | null;
  actor: string | null;
  file: string | null;
  backup_path: string | null;
  changed_keys: string[];
  validation_status: string | null;
  notes: string | null;
};
