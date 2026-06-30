import { type ReactNode, useEffect, useMemo, useState } from "react";
import {
  Bar,
  BarChart,
  CartesianGrid,
  Legend,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

import type {
  BreakdownItem,
  ConfigEvent,
  ModelsConfigDraft,
  ModelsConfigResponse,
  ModelsSaveResponse,
  ModelsValidationResponse,
  TierConfig,
  UsageRecord,
  UsageSummary,
} from "../shared/types";
import { filterRuns, type RunFilterState, valueOrUnknown } from "./runs";

type LoadState = {
  summary: UsageSummary | null;
  models: ModelsConfigResponse | null;
  configEvents: ConfigEvent[];
  configEventsMonth: string;
  configEventsInvalidLines: number;
  error: string | null;
  loading: boolean;
};

type TabId = "overview" | "usage" | "billing" | "runs" | "models" | "events";

type InsightState = {
  t4Runs: number;
  t4Share: number | null;
  t4FailureShare: number | null;
  runsWithoutTier: number;
  driftRuns: number;
  rolesAboveExpected: string[];
  effectiveCostPerRun: number | null;
  effectiveCostPerTurn: number | null;
  effectiveCostPerKnownToken: number | null;
};

const initialState: LoadState = {
  summary: null,
  models: null,
  configEvents: [],
  configEventsMonth: "current",
  configEventsInvalidLines: 0,
  error: null,
  loading: true,
};

const initialFilters: RunFilterState = {
  month: "current",
  role: "all",
  tier: "all",
  adapter: "all",
  provider: "all",
  model: "all",
  success: "all",
  branch: "all",
};

const TABS: Array<{ id: TabId; label: string }> = [
  { id: "overview", label: "Overview" },
  { id: "usage", label: "Usage" },
  { id: "billing", label: "Billing" },
  { id: "runs", label: "Runs" },
  { id: "models", label: "Models & Tiers" },
  { id: "events", label: "Config Events" },
];

function isTabId(value: string): value is TabId {
  return TABS.some((tab) => tab.id === value);
}

function getInitialTab(): TabId {
  const hash = window.location.hash.replace(/^#/, "");
  return isTabId(hash) ? hash : "overview";
}

const TIER_DESCRIPTIONS: Record<string, string> = {
  T1: "Tarefas mecânicas triviais",
  T2: "Execução padrão",
  T3: "Execução complexa e revisão",
  T4: "Crítica e auditoria",
  "T4+": "Autoridade e raciocínio máximo",
};

const ROLE_DESCRIPTIONS: Record<string, string> = {
  orchestrate: "Direção, decomposição e QA",
  execute: "Implementação padrão",
  critique: "Crítica técnica independente",
  review: "Revisão aprofundada",
  audit: "Auditoria e verificação",
  authority: "Arbitragem e mudança",
};

function formatNumber(value: number | null): string {
  if (value === null) {
    return "unknown";
  }
  return new Intl.NumberFormat("pt-BR").format(value);
}

function formatMoney(value: number | null): string {
  if (value === null) {
    return "unknown";
  }
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
    minimumFractionDigits: 2,
    maximumFractionDigits: 4,
  }).format(value);
}

function formatConfiguredMoney(value: number | null): string {
  if (value === null) {
    return "not configured";
  }
  return formatMoney(value);
}

function formatPercent(value: number | null): string {
  if (value === null) {
    return "unknown";
  }
  return `${value.toFixed(1)}%`;
}

function formatDate(value: string | null): string {
  if (!value) {
    return "unknown";
  }
  return new Date(value).toLocaleString("pt-BR", { hour12: false });
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

function createDraftFromModels(models: ModelsConfigResponse): ModelsConfigDraft {
  return {
    critiqueNoFallback: models.critiqueNoFallback,
    tiers: models.tiers.map((tier) => ({ ...tier })),
  };
}

function hasModelDrift(run: UsageRecord): boolean {
  return Boolean(
    run.observed_model &&
      run.configured_model &&
      run.observed_model !== run.configured_model,
  );
}

function MetricCard({
  label,
  value,
  tone,
  detail,
}: {
  label: string;
  value: string;
  tone?: "danger" | "warning" | "success" | "muted";
  detail?: string;
}) {
  return (
    <article className={`metric-card ${tone ? `metric-${tone}` : ""}`}>
      <span>{label}</span>
      <strong>{value}</strong>
      {detail && <small>{detail}</small>}
    </article>
  );
}

function EmptyState({ title, detail }: { title: string; detail: string }) {
  return (
    <div className="empty-state">
      <strong>{title}</strong>
      <span>{detail}</span>
    </div>
  );
}

function BreakdownCard({
  title,
  data,
  totalRuns,
  barColor,
  limit = 6,
}: {
  title: string;
  data: BreakdownItem[];
  totalRuns: number;
  barColor: string;
  limit?: number;
}) {
  return (
    <section className="panel">
      <div className="panel-header">
        <h2>{title}</h2>
        <span>{data.length} grupos</span>
      </div>
      {data.length === 0 ? (
        <EmptyState title="Sem dados" detail="Nenhum registro no mês selecionado." />
      ) : (
        <>
          <div className="chart-wrap">
            <ResponsiveContainer width="100%" height={220}>
              <BarChart data={data.slice(0, limit)}>
                <CartesianGrid strokeDasharray="2 4" stroke="rgba(255,255,255,0.08)" />
                <XAxis dataKey="key" stroke="#98a4b3" />
                <YAxis stroke="#98a4b3" />
                <Tooltip />
                <Legend />
                <Bar dataKey="count" name="runs" fill={barColor} radius={[6, 6, 0, 0]} />
                <Bar dataKey="failures" name="falhas" fill="#f97316" radius={[6, 6, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
          <div className="mini-table compact-list">
            {data.slice(0, limit).map((item) => (
              <div className="mini-row" key={item.key}>
                <span>{item.key}</span>
                <span>
                  {item.count} runs ·{" "}
                  {formatPercent(totalRuns > 0 ? (item.count / totalRuns) * 100 : null)}
                </span>
              </div>
            ))}
          </div>
        </>
      )}
    </section>
  );
}

function BreakdownDetailsSection({
  title,
  subtitle,
  data,
  totalRuns,
  descriptions,
}: {
  title: string;
  subtitle: string;
  data: BreakdownItem[];
  totalRuns: number;
  descriptions?: Record<string, string>;
}) {
  return (
    <section className="panel">
      <div className="panel-header">
        <h2>{title}</h2>
        <span>{data.length} grupos</span>
      </div>
      <p className="section-copy">{subtitle}</p>
      {descriptions && (
        <div className="tag-grid">
          {data.map((item) => (
            <div className="tag" key={item.key}>
              <strong>{item.key}</strong>
              <span>{descriptions[item.key] || "Sem descrição adicional"}</span>
            </div>
          ))}
        </div>
      )}
      <div className="table-wrap compact-table">
        <table>
          <thead>
            <tr>
              <th>Grupo</th>
              <th>Runs</th>
              <th>Share</th>
              <th>Falhas</th>
              <th>Turns</th>
              <th>Tokens</th>
              <th>API est.</th>
              <th>Sub alloc.</th>
            </tr>
          </thead>
          <tbody>
            {data.length === 0 && (
              <tr>
                <td colSpan={8}>Sem dados no mês selecionado.</td>
              </tr>
            )}
            {data.map((item) => (
              <tr key={item.key}>
                <td>{item.key}</td>
                <td>{item.count}</td>
                <td>{formatPercent(totalRuns > 0 ? (item.count / totalRuns) * 100 : null)}</td>
                <td>{item.failures}</td>
                <td>{formatNumber(item.turns)}</td>
                <td>{formatNumber(item.knownTokens)}</td>
                <td>{formatMoney(item.estimatedApiCostUsd)}</td>
                <td>{formatMoney(item.allocatedSubscriptionCostUsd)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}

function TimelinePanel({ summary }: { summary: UsageSummary }) {
  return (
    <section className="panel panel-large">
      <div className="panel-header">
        <h2>Runs por dia</h2>
        <span>{summary.breakdowns.timeline.length} dias</span>
      </div>
      {summary.breakdowns.timeline.length === 0 ? (
        <EmptyState title="Sem timeline" detail="Nenhum run encontrado para montar a série." />
      ) : (
        <div className="chart-wrap timeline-chart">
          <ResponsiveContainer width="100%" height={280}>
            <LineChart data={summary.breakdowns.timeline}>
              <CartesianGrid strokeDasharray="2 4" stroke="rgba(255,255,255,0.08)" />
              <XAxis dataKey="day" stroke="#98a4b3" />
              <YAxis stroke="#98a4b3" />
              <Tooltip />
              <Legend />
              <Line type="monotone" dataKey="runs" name="Runs" stroke="#58d6ff" strokeWidth={2} />
              <Line
                type="monotone"
                dataKey="failures"
                name="Falhas"
                stroke="#ff9b5e"
                strokeWidth={2}
              />
              <Line
                type="monotone"
                dataKey="t4OrHigher"
                name="T4/T4+"
                stroke="#8b9bff"
                strokeWidth={2}
              />
            </LineChart>
          </ResponsiveContainer>
        </div>
      )}
    </section>
  );
}

function AttentionPanel({
  items,
}: {
  items: Array<{ tone: "danger" | "warning" | "success" | "muted"; text: string }>;
}) {
  return (
    <section className="panel attention-panel">
      <div className="panel-header">
        <h2>Atenção</h2>
        <span>{items.length} sinais</span>
      </div>
      <div className="attention-list">
        {items.map((item) => (
          <div className={`attention-item attention-${item.tone}`} key={item.text}>
            <span aria-hidden="true" />
            <p>{item.text}</p>
          </div>
        ))}
      </div>
    </section>
  );
}

function BillingSection({
  models,
  summary,
  effectiveCostPerKnownToken,
}: {
  models: ModelsConfigResponse;
  summary: UsageSummary;
  effectiveCostPerKnownToken: number | null;
}) {
  const enabledPlans = models.subscriptions.filter((plan) => plan.enabled);

  return (
    <section className="section-stack">
      <div className="cards-grid priority-grid">
        <MetricCard
          label="Assinatura mensal"
          value={formatConfiguredMoney(summary.subscription.totalMonthlyUsd)}
          tone={summary.subscription.totalMonthlyUsd === null ? "muted" : undefined}
        />
        <MetricCard
          label="Custo efetivo/run"
          value={formatMoney(summary.subscription.effectiveCostPerRunUsd)}
        />
        <MetricCard
          label="Custo efetivo/turn"
          value={formatMoney(summary.subscription.effectiveCostPerTurnUsd)}
        />
        <MetricCard
          label="Custo/token conhecido"
          value={formatMoney(effectiveCostPerKnownToken)}
          tone={effectiveCostPerKnownToken === null ? "muted" : undefined}
        />
        <MetricCard
          label="API estimada"
          value={formatMoney(summary.apiEstimate.totalUsd)}
          detail={`${summary.apiEstimate.knownRuns} runs com preço`}
          tone={summary.apiEstimate.totalUsd === null ? "muted" : undefined}
        />
      </div>

      <div className="dual-grid">
        <section className="panel">
          <div className="panel-header">
            <h2>Assinaturas</h2>
            <span>{enabledPlans.length} habilitada(s)</span>
          </div>
          <div className="surface-grid">
            {models.subscriptions.map((plan) => (
              <article className="card dense surface-item" key={plan.key}>
                <p>{plan.key}</p>
                <strong>{plan.enabled ? "enabled" : "disabled"}</strong>
                <div className="mini-table dense-list">
                  <div className="mini-row">
                    <span>Mensalidade</span>
                    <span>{formatConfiguredMoney(plan.monthlyUsd)}</span>
                  </div>
                  <div className="mini-row">
                    <span>Billing unit</span>
                    <span>{valueOrUnknown(plan.billingUnit)}</span>
                  </div>
                  <div className="mini-row">
                    <span>Provider</span>
                    <span>{valueOrUnknown(plan.provider)}</span>
                  </div>
                  <div className="mini-row">
                    <span>Model pattern</span>
                    <span>{valueOrUnknown(plan.modelPattern)}</span>
                  </div>
                </div>
              </article>
            ))}
          </div>
        </section>

        <section className="panel">
          <div className="panel-header">
            <h2>API estimate</h2>
            <span>{models.prices.length} price point(s)</span>
          </div>
          <div className="surface-grid">
            {models.prices.map((price) => (
              <article className="card dense surface-item" key={price.key}>
                <p>{price.key}</p>
                <strong>
                  {price.inputPer1MUsd !== null || price.outputPer1MUsd !== null
                    ? "configured"
                    : "unknown"}
                </strong>
                <div className="mini-table dense-list">
                  <div className="mini-row">
                    <span>Input / 1M</span>
                    <span>{formatMoney(price.inputPer1MUsd)}</span>
                  </div>
                  <div className="mini-row">
                    <span>Output / 1M</span>
                    <span>{formatMoney(price.outputPer1MUsd)}</span>
                  </div>
                </div>
              </article>
            ))}
          </div>
        </section>
      </div>
    </section>
  );
}

function RunsFilters({
  filters,
  roleOptions,
  tierOptions,
  adapterOptions,
  modelOptions,
  branchOptions,
  onChange,
}: {
  filters: RunFilterState;
  roleOptions: string[];
  tierOptions: string[];
  adapterOptions: string[];
  modelOptions: string[];
  branchOptions: string[];
  onChange: <Key extends keyof RunFilterState>(key: Key, value: RunFilterState[Key]) => void;
}) {
  return (
    <div className="filter-bar">
      <label>
        Role
        <select value={filters.role} onChange={(event) => onChange("role", event.target.value)}>
          {roleOptions.map((option) => (
            <option key={option} value={option}>
              {option}
            </option>
          ))}
        </select>
      </label>
      <label>
        Tier
        <select value={filters.tier} onChange={(event) => onChange("tier", event.target.value)}>
          {tierOptions.map((option) => (
            <option key={option} value={option}>
              {option}
            </option>
          ))}
        </select>
      </label>
      <label>
        Adapter
        <select value={filters.adapter} onChange={(event) => onChange("adapter", event.target.value)}>
          {adapterOptions.map((option) => (
            <option key={option} value={option}>
              {option}
            </option>
          ))}
        </select>
      </label>
      <label>
        Model
        <select value={filters.model} onChange={(event) => onChange("model", event.target.value)}>
          {modelOptions.map((option) => (
            <option key={option} value={option}>
              {option}
            </option>
          ))}
        </select>
      </label>
      <label>
        Success
        <select value={filters.success} onChange={(event) => onChange("success", event.target.value)}>
          <option value="all">all</option>
          <option value="success">success</option>
          <option value="failed">failed</option>
        </select>
      </label>
      <label>
        Branch
        <select value={filters.branch} onChange={(event) => onChange("branch", event.target.value)}>
          {branchOptions.map((option) => (
            <option key={option} value={option}>
              {option}
            </option>
          ))}
        </select>
      </label>
    </div>
  );
}

function RunsTable({
  runs,
  filters,
  roleOptions,
  tierOptions,
  adapterOptions,
  modelOptions,
  branchOptions,
  onFilterChange,
}: {
  runs: UsageRecord[];
  filters: RunFilterState;
  roleOptions: string[];
  tierOptions: string[];
  adapterOptions: string[];
  modelOptions: string[];
  branchOptions: string[];
  onFilterChange: <Key extends keyof RunFilterState>(
    key: Key,
    value: RunFilterState[Key],
  ) => void;
}) {
  const filteredRuns = useMemo(() => filterRuns(runs, filters), [filters, runs]);

  return (
    <section className="panel table-panel">
      <div className="panel-header">
        <h2>Auditoria de runs</h2>
        <span>{filteredRuns.length} linhas</span>
      </div>
      <RunsFilters
        filters={filters}
        roleOptions={roleOptions}
        tierOptions={tierOptions}
        adapterOptions={adapterOptions}
        modelOptions={modelOptions}
        branchOptions={branchOptions}
        onChange={onFilterChange}
      />
      <div className="table-wrap">
        <table className="runs-table">
          <thead>
            <tr>
              <th>Started</th>
              <th>Role</th>
              <th>Tier</th>
              <th>Adapter</th>
              <th>Model</th>
              <th>Duration</th>
              <th>Turns</th>
              <th>Tokens</th>
              <th>Cost</th>
              <th>Success</th>
              <th>Transcript</th>
              <th>Detalhes</th>
            </tr>
          </thead>
          <tbody>
            {filteredRuns.length === 0 && (
              <tr>
                <td colSpan={12}>Nenhum run combina com os filtros atuais.</td>
              </tr>
            )}
            {filteredRuns.map((run) => (
              <tr key={run.run_id}>
                <td>{formatDate(run.started_at)}</td>
                <td>{valueOrUnknown(run.role)}</td>
                <td>{valueOrUnknown(run.tier)}</td>
                <td>{valueOrUnknown(run.adapter)}</td>
                <td>{valueOrUnknown(run.model)}</td>
                <td>{formatNumber(run.duration_seconds)}s</td>
                <td>{formatNumber(run.turns)}</td>
                <td>{formatNumber(run.total_tokens)}</td>
                <td>{formatMoney(run.allocated_subscription_cost_usd ?? run.estimated_api_cost_usd)}</td>
                <td>
                  <span
                    className={`pill ${
                      run.success === true
                        ? "pill-ok"
                        : run.success === false
                          ? "pill-fail"
                          : "pill-unknown"
                    }`}
                  >
                    {run.success === true ? "ok" : run.success === false ? "fail" : "unknown"}
                  </span>
                </td>
                <td>
                  <button
                    className="ghost-button"
                    type="button"
                    onClick={() => {
                      if (run.transcript_path) {
                        navigator.clipboard.writeText(run.transcript_path).catch(() => {});
                      }
                    }}
                  >
                    copiar path
                  </button>
                </td>
                <td>
                  <details className="run-details">
                    <summary>abrir</summary>
                    <dl>
                      <dt>Configured</dt>
                      <dd className={hasModelDrift(run) ? "drift-cell" : undefined}>
                        {valueOrUnknown(run.configured_model)}
                      </dd>
                      <dt>Observed</dt>
                      <dd className={hasModelDrift(run) ? "drift-cell" : undefined}>
                        {valueOrUnknown(run.observed_model)}
                      </dd>
                      <dt>Provider</dt>
                      <dd>{valueOrUnknown(run.provider)}</dd>
                      <dt>Effort</dt>
                      <dd>{valueOrUnknown(run.effort)}</dd>
                      <dt>Branch</dt>
                      <dd>{run.branch}</dd>
                      <dt>Routing</dt>
                      <dd>{run.routing_reason || "unknown"}</dd>
                      <dt>Transcript</dt>
                      <dd>{run.transcript_path || "unknown"}</dd>
                      <dt>Run id</dt>
                      <dd>{run.run_id}</dd>
                    </dl>
                  </details>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}

function Field({
  label,
  value,
  onChange,
}: {
  label: string;
  value: string | null;
  onChange: (value: string) => void;
}) {
  return (
    <label className="field">
      <span>{label}</span>
      <input value={value ?? ""} onChange={(event) => onChange(event.target.value)} />
    </label>
  );
}

function ModelsMatrix({
  models,
  summary,
}: {
  models: ModelsConfigResponse;
  summary: UsageSummary;
}) {
  return (
    <section className="panel">
      <div className="panel-header">
        <h2>Matriz atual</h2>
        <span>read-only</span>
      </div>
      <div className="tier-grid">
        {models.tiers.map((tier) => {
          const tierRuns = summary.runs.filter((run) => run.tier === tier.tier);
          const failures = tierRuns.filter((run) => run.success === false).length;
          const lastUse = [...tierRuns]
            .sort((left, right) => (right.started_at || "").localeCompare(left.started_at || ""))
            .at(0);
          const fallbackLabel =
            rankTier(tier.tier) >= 4 && models.critiqueNoFallback ? "bloqueado" : "n/a";

          return (
            <article className="tier-card" key={tier.tier}>
              <div>
                <strong>{tier.tier}</strong>
                <span>{TIER_DESCRIPTIONS[tier.tier] || "Tier customizado"}</span>
              </div>
              <dl>
                <dt>Adapter</dt>
                <dd>{valueOrUnknown(tier.adapter)}</dd>
                <dt>Provider</dt>
                <dd>{valueOrUnknown(tier.provider)}</dd>
                <dt>Model</dt>
                <dd>{valueOrUnknown(tier.model)}</dd>
                <dt>Effort</dt>
                <dd>{valueOrUnknown(tier.effort)}</dd>
                <dt>Fallback</dt>
                <dd>{fallbackLabel}</dd>
                <dt>Runs mês</dt>
                <dd>{tierRuns.length}</dd>
                <dt>Falhas</dt>
                <dd>{failures}</dd>
                <dt>Último uso</dt>
                <dd>{lastUse ? formatDate(lastUse.started_at) : "sem uso"}</dd>
              </dl>
            </article>
          );
        })}
      </div>
    </section>
  );
}

function ControlPlaneEditor({
  draft,
  validation,
  saveResult,
  busy,
  actionError,
  onTierChange,
  onToggleFallback,
  onValidate,
  onSave,
}: {
  draft: ModelsConfigDraft;
  validation: ModelsValidationResponse | null;
  saveResult: ModelsSaveResponse | null;
  busy: boolean;
  actionError: string | null;
  onTierChange: (tier: string, field: keyof TierConfig, value: string) => void;
  onToggleFallback: (value: boolean) => void;
  onValidate: () => void;
  onSave: () => void;
}) {
  return (
    <section className="panel">
      <div className="panel-header">
        <h2>Editor de models.conf</h2>
        <span>backup antes de salvar</span>
      </div>

      <div className="toggle-row">
        <label className="toggle">
          <input
            type="checkbox"
            checked={draft.critiqueNoFallback}
            onChange={(event) => onToggleFallback(event.target.checked)}
          />
          <span>Critique/Audit/Authority sem fallback silencioso</span>
        </label>
      </div>

      <div className="edit-grid">
        {draft.tiers.map((tier) => (
          <article className="card matrix editor" key={tier.tier}>
            <p>{tier.tier}</p>
            <span className="tier-description">
              {TIER_DESCRIPTIONS[tier.tier] || "Custom tier"}
            </span>
            <Field
              label="Adapter"
              value={tier.adapter}
              onChange={(value) => onTierChange(tier.tier, "adapter", value)}
            />
            <Field
              label="Provider"
              value={tier.provider}
              onChange={(value) => onTierChange(tier.tier, "provider", value)}
            />
            <Field
              label="Model"
              value={tier.model}
              onChange={(value) => onTierChange(tier.tier, "model", value)}
            />
            <Field
              label="Effort"
              value={tier.effort}
              onChange={(value) => onTierChange(tier.tier, "effort", value)}
            />
          </article>
        ))}
      </div>

      <div className="button-row">
        <button className="action-button" type="button" disabled={busy} onClick={onValidate}>
          {busy ? "Validando..." : "Preview diff"}
        </button>
        <button className="action-button secondary" type="button" disabled={busy} onClick={onSave}>
          {busy ? "Salvando..." : "Salvar com backup"}
        </button>
      </div>

      {actionError && <div className="notice notice-error">{actionError}</div>}

      {validation && (
        <details className="details-panel" open={!validation.valid}>
          <summary>
            Validação: {validation.valid ? "passed" : "blocked"} ·{" "}
            {validation.changedKeys.length} chave(s)
          </summary>
          {validation.errors.length > 0 && (
            <div className="warning-list">
              {validation.errors.map((error) => (
                <div className="notice notice-error" key={error}>
                  {error}
                </div>
              ))}
            </div>
          )}
          {validation.warnings.length > 0 && (
            <div className="warning-list">
              {validation.warnings.map((warning) => (
                <div className="warning-item" key={warning}>
                  {warning}
                </div>
              ))}
            </div>
          )}
          <pre className="diff-preview">{validation.diff}</pre>
          <div className="command-list">
            {validation.suggestedCommands.map((command) => (
              <code key={command}>{command}</code>
            ))}
          </div>
        </details>
      )}

      {saveResult && (
        <details className="details-panel" open>
          <summary>Último save · {formatDate(saveResult.savedAt)}</summary>
          <div className="mini-table">
            <div className="mini-row">
              <span>Backup</span>
              <span>{saveResult.backupPath}</span>
            </div>
            <div className="mini-row">
              <span>Config event</span>
              <span>{saveResult.eventPath}</span>
            </div>
          </div>
        </details>
      )}
    </section>
  );
}

function ConfigEventsSection({
  events,
  month,
  invalidLines,
}: {
  events: ConfigEvent[];
  month: string;
  invalidLines: number;
}) {
  return (
    <section className="panel table-panel">
      <div className="panel-header">
        <h2>Config Events</h2>
        <span>
          {events.length} evento(s) · {month}
        </span>
      </div>
      {invalidLines > 0 && (
        <div className="warning-item">{invalidLines} line(s) invalidas foram ignoradas</div>
      )}
      {events.length === 0 ? (
        <EmptyState
          title="Sem eventos de configuração"
          detail="Nenhum save de models.conf foi registrado neste mês."
        />
      ) : (
        <div className="table-wrap compact-table">
          <table>
            <thead>
              <tr>
                <th>Data</th>
                <th>Actor</th>
                <th>Arquivo</th>
                <th>Changed keys</th>
                <th>Backup</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {events.map((event, index) => (
                <tr key={`${event.created_at ?? "unknown"}-${index}`}>
                  <td>{formatDate(event.created_at)}</td>
                  <td>{event.actor || "unknown"}</td>
                  <td>{event.file || "unknown"}</td>
                  <td>{event.changed_keys.join(", ") || "sem changed_keys"}</td>
                  <td>{event.backup_path || "sem backup_path"}</td>
                  <td>{event.validation_status || "unknown"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </section>
  );
}

function TabPanel({ active, children }: { active: boolean; children: ReactNode }) {
  if (!active) {
    return null;
  }
  return <div className="tab-panel">{children}</div>;
}

export function App() {
  const [state, setState] = useState<LoadState>(initialState);
  const [filters, setFilters] = useState<RunFilterState>(initialFilters);
  const [activeTab, setActiveTab] = useState<TabId>(getInitialTab);
  const [reloadKey, setReloadKey] = useState(0);
  const [draft, setDraft] = useState<ModelsConfigDraft | null>(null);
  const [validation, setValidation] = useState<ModelsValidationResponse | null>(null);
  const [saveResult, setSaveResult] = useState<ModelsSaveResponse | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    const controller = new AbortController();

    async function load() {
      try {
        setState((current) => ({ ...current, loading: true, error: null }));

        const [summaryResponse, modelsResponse, eventsResponse] = await Promise.all([
          fetch(`/api/usage/summary?month=${encodeURIComponent(filters.month)}`, {
            signal: controller.signal,
          }),
          fetch("/api/models", { signal: controller.signal }),
          fetch(`/api/config-events?month=${encodeURIComponent(filters.month)}`, {
            signal: controller.signal,
          }),
        ]);

        if (!summaryResponse.ok || !modelsResponse.ok || !eventsResponse.ok) {
          throw new Error("Failed to load observability data");
        }

        const [summary, models, events] = await Promise.all([
          summaryResponse.json() as Promise<UsageSummary>,
          modelsResponse.json() as Promise<ModelsConfigResponse>,
          eventsResponse.json() as Promise<{
            month: string;
            events: ConfigEvent[];
            invalidLines: number;
          }>,
        ]);

        setState({
          summary,
          models,
          configEvents: events.events,
          configEventsMonth: events.month,
          configEventsInvalidLines: events.invalidLines,
          error: null,
          loading: false,
        });
        setDraft(createDraftFromModels(models));
      } catch (error) {
        if (controller.signal.aborted) {
          return;
        }

        setState((current) => ({
          ...current,
          loading: false,
          error: (error as Error).message,
        }));
      }
    }

    load();
    return () => controller.abort();
  }, [filters.month, reloadKey]);

  useEffect(() => {
    function syncTabFromHash() {
      const hash = window.location.hash.replace(/^#/, "");
      if (isTabId(hash)) {
        setActiveTab(hash);
      }
    }

    window.addEventListener("hashchange", syncTabFromHash);
    return () => window.removeEventListener("hashchange", syncTabFromHash);
  }, []);

  const optionSet = (picker: (run: UsageRecord) => string) =>
    ["all", ...Array.from(new Set(state.summary?.runs.map(picker) ?? [])).sort()];

  const roleOptions = useMemo(() => optionSet((run) => valueOrUnknown(run.role)), [state.summary]);
  const tierOptions = useMemo(() => optionSet((run) => valueOrUnknown(run.tier)), [state.summary]);
  const adapterOptions = useMemo(
    () => optionSet((run) => valueOrUnknown(run.adapter)),
    [state.summary],
  );
  const modelOptions = useMemo(() => optionSet((run) => valueOrUnknown(run.model)), [state.summary]);
  const branchOptions = useMemo(() => optionSet((run) => run.branch), [state.summary]);

  const insights = useMemo<InsightState | null>(() => {
    if (!state.summary || !state.models) {
      return null;
    }

    const runs = state.summary.runs;
    const t4Runs = runs.filter((run) => rankTier(run.tier) >= 4);
    const t4Failures = t4Runs.filter((run) => run.success === false);
    const missingTier = runs.filter((run) => !run.tier);
    const driftRuns = runs.filter(hasModelDrift);
    const policyMap = new Map(
      state.models.rolePolicy.map((item) => [item.role, item.minimumTier]),
    );
    const oversized = runs.filter((run) => {
      const minimumTier = policyMap.get(run.role || "");
      return minimumTier ? rankTier(run.tier) > rankTier(minimumTier) : false;
    });

    return {
      t4Runs: t4Runs.length,
      t4Share: runs.length > 0 ? (t4Runs.length / runs.length) * 100 : null,
      t4FailureShare: t4Runs.length > 0 ? (t4Failures.length / t4Runs.length) * 100 : null,
      runsWithoutTier: missingTier.length,
      driftRuns: driftRuns.length,
      rolesAboveExpected: Array.from(new Set(oversized.map((run) => run.role || "unknown"))),
      effectiveCostPerRun: state.summary.subscription.effectiveCostPerRunUsd,
      effectiveCostPerTurn: state.summary.subscription.effectiveCostPerTurnUsd,
      effectiveCostPerKnownToken:
        state.summary.subscription.allocatedMonthlyUsd &&
        state.summary.counts.knownTokens
          ? state.summary.subscription.allocatedMonthlyUsd / state.summary.counts.knownTokens
          : null,
    };
  }, [state.models, state.summary]);

  const driftRuns = useMemo(() => {
    if (!state.summary) {
      return [];
    }

    return [...state.summary.runs]
      .filter(hasModelDrift)
      .sort((left, right) =>
        (right.started_at || "").localeCompare(left.started_at || ""),
      )
      .slice(0, 8);
  }, [state.summary]);

  const attentionItems = useMemo(() => {
    if (!state.summary || !state.models || !insights) {
      return [];
    }

    const items: Array<{ tone: "danger" | "warning" | "success" | "muted"; text: string }> = [];

    if (state.summary.counts.runs === 0) {
      items.push({ tone: "muted", text: "Nenhum ledger encontrado para o mês selecionado." });
    }
    if (state.summary.counts.failures > 0) {
      items.push({
        tone: "danger",
        text: `${state.summary.counts.failures} execução(ões) falharam neste mês.`,
      });
    }
    if (state.summary.counts.unknownTokenRuns > 0) {
      items.push({
        tone: "warning",
        text: `${state.summary.counts.unknownTokenRuns} run(s) estão sem tokens conhecidos.`,
      });
    }
    if (insights.driftRuns > 0) {
      items.push({
        tone: "warning",
        text: `${insights.driftRuns} run(s) divergiram entre configured_model e observed_model.`,
      });
    }
    if ((insights.t4Share ?? 0) > 35) {
      items.push({
        tone: "warning",
        text: `${formatPercent(insights.t4Share)} das execuções estão em T4/T4+.`,
      });
    }
    if (state.summary.subscription.totalMonthlyUsd === null) {
      items.push({ tone: "muted", text: "Nenhum custo de assinatura configurado." });
    }
    if (!state.models.tiers.some((tier) => tier.tier === "T4+" && tier.model)) {
      items.push({ tone: "danger", text: "models.conf está sem T4+ configurado." });
    }
    if (state.summary.warnings.length > 0) {
      state.summary.warnings.slice(0, 3).forEach((warning) => {
        items.push({ tone: "warning", text: warning });
      });
    }
    if (items.length === 0) {
      items.push({ tone: "success", text: "Sem alertas operacionais para o mês selecionado." });
    }

    return items;
  }, [insights, state.models, state.summary]);

  function updateFilter<Key extends keyof RunFilterState>(
    key: Key,
    value: RunFilterState[Key],
  ) {
    setFilters((current) => ({ ...current, [key]: value }));
  }

  function updateTierField(tierName: string, field: keyof TierConfig, value: string) {
    setDraft((current) => {
      if (!current) {
        return current;
      }

      return {
        ...current,
        tiers: current.tiers.map((tier) =>
          tier.tier === tierName ? { ...tier, [field]: value } : tier,
        ),
      };
    });
    setValidation(null);
    setSaveResult(null);
    setActionError(null);
  }

  function toggleFallback(value: boolean) {
    setDraft((current) => (current ? { ...current, critiqueNoFallback: value } : current));
    setValidation(null);
    setSaveResult(null);
    setActionError(null);
  }

  async function requestValidation(): Promise<ModelsValidationResponse | null> {
    if (!draft) {
      return null;
    }

    setBusy(true);
    setActionError(null);
    try {
      const response = await fetch("/api/models/validate", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(draft),
      });
      const payload = (await response.json()) as ModelsValidationResponse | { error: string };
      if (!response.ok || "error" in payload) {
        throw new Error("error" in payload ? payload.error : "Validation failed");
      }
      setValidation(payload);
      return payload;
    } catch (error) {
      setActionError((error as Error).message);
      return null;
    } finally {
      setBusy(false);
    }
  }

  async function requestSave() {
    if (!draft) {
      return;
    }

    const latestValidation = await requestValidation();
    if (!latestValidation || !latestValidation.valid) {
      return;
    }

    if (!window.confirm("Salvar models.conf com o diff validado?")) {
      return;
    }

    setBusy(true);
    setActionError(null);
    try {
      const response = await fetch("/api/models/save", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(draft),
      });
      const payload = (await response.json()) as ModelsSaveResponse | { error: string };
      if (!response.ok || "error" in payload) {
        throw new Error("error" in payload ? payload.error : "Save failed");
      }
      setSaveResult(payload);
      setValidation(payload);
      setReloadKey((current) => current + 1);
    } catch (error) {
      setActionError((error as Error).message);
    } finally {
      setBusy(false);
    }
  }

  const summary = state.summary;
  const models = state.models;
  const ledgerStatus = state.error
    ? "ausente"
    : summary && summary.counts.runs > 0
      ? "encontrado"
      : summary
        ? "vazio"
        : "carregando";

  return (
    <div className="app-shell">
      <header className="topbar">
        <div className="topbar-copy">
          <p className="product-label">Engrama</p>
          <h1>Observabilidade Cognitiva</h1>
          <p className="hero-copy">Uso, custo, roteamento e governança dos agentes.</p>
        </div>
        <div className="topbar-controls">
          <label>
            Mês
            <input
              value={filters.month}
              onChange={(event) => updateFilter("month", event.target.value)}
              placeholder="current ou YYYY-MM"
            />
          </label>
          <div className={`ledger-status ledger-${ledgerStatus}`}>
            <span>Ledger</span>
            <strong>{ledgerStatus}</strong>
          </div>
        </div>
      </header>

      <nav className="tabbar" aria-label="Seções da observabilidade">
        {TABS.map((tab) => (
          <button
            key={tab.id}
            type="button"
            className={activeTab === tab.id ? "active" : undefined}
            onClick={() => {
              setActiveTab(tab.id);
              window.history.replaceState(null, "", `#${tab.id}`);
            }}
          >
            {tab.label}
          </button>
        ))}
      </nav>

      <main className="content">
        {state.loading && <div className="notice">Carregando telemetria local...</div>}
        {state.error && <div className="notice notice-error">{state.error}</div>}

        {summary && models && insights && (
          <>
            <TabPanel active={activeTab === "overview"}>
              <section className="overview-layout">
                <div className="cards-grid priority-grid">
                  <MetricCard label="Runs" value={formatNumber(summary.counts.runs)} />
                  <MetricCard
                    label="Falhas"
                    value={formatNumber(summary.counts.failures)}
                    tone={summary.counts.failures > 0 ? "danger" : "success"}
                  />
                  <MetricCard
                    label="T4/T4+"
                    value={formatNumber(insights.t4Runs)}
                    detail={formatPercent(insights.t4Share)}
                    tone={(insights.t4Share ?? 0) > 35 ? "warning" : undefined}
                  />
                  <MetricCard
                    label="Custo/run"
                    value={formatMoney(insights.effectiveCostPerRun)}
                    tone={insights.effectiveCostPerRun === null ? "muted" : undefined}
                  />
                  <MetricCard
                    label="Tokens"
                    value={formatNumber(summary.counts.knownTokens)}
                    detail={`${summary.counts.unknownTokenRuns} unknown`}
                    tone={summary.counts.unknownTokenRuns > 0 ? "warning" : undefined}
                  />
                  <MetricCard label="Último run" value={formatDate(summary.counts.lastRunAt)} />
                </div>

                <AttentionPanel items={attentionItems} />

                <div className="overview-charts">
                  <TimelinePanel summary={summary} />
                  <BreakdownCard
                    title="Runs por role"
                    data={summary.breakdowns.role}
                    totalRuns={summary.counts.runs}
                    barColor="#58d6ff"
                    limit={5}
                  />
                  <BreakdownCard
                    title="Runs por tier"
                    data={summary.breakdowns.tier}
                    totalRuns={summary.counts.runs}
                    barColor="#8b9bff"
                    limit={5}
                  />
                </div>
              </section>
            </TabPanel>

            <TabPanel active={activeTab === "usage"}>
              <section className="section-stack">
                <div className="chart-grid">
                  <BreakdownCard
                    title="Uso por role"
                    data={summary.breakdowns.role}
                    totalRuns={summary.counts.runs}
                    barColor="#58d6ff"
                  />
                  <BreakdownCard
                    title="Uso por tier"
                    data={summary.breakdowns.tier}
                    totalRuns={summary.counts.runs}
                    barColor="#8b9bff"
                  />
                  <BreakdownCard
                    title="Uso por modelo"
                    data={summary.breakdowns.model}
                    totalRuns={summary.counts.runs}
                    barColor="#35c48a"
                  />
                </div>
                <div className="dual-grid">
                  <BreakdownCard
                    title="Uso por adapter"
                    data={summary.breakdowns.adapter}
                    totalRuns={summary.counts.runs}
                    barColor="#facc15"
                  />
                  <BreakdownCard
                    title="Uso por provider"
                    data={summary.breakdowns.provider}
                    totalRuns={summary.counts.runs}
                    barColor="#f472b6"
                  />
                </div>
                <BreakdownDetailsSection
                  title="Roles"
                  subtitle="Volume, falhas e custo por papel operacional."
                  data={summary.breakdowns.role}
                  totalRuns={summary.counts.runs}
                  descriptions={ROLE_DESCRIPTIONS}
                />
                <BreakdownDetailsSection
                  title="Tiers"
                  subtitle="Concentração de execuções por custo e risco operacional."
                  data={summary.breakdowns.tier}
                  totalRuns={summary.counts.runs}
                  descriptions={TIER_DESCRIPTIONS}
                />
              </section>
            </TabPanel>

            <TabPanel active={activeTab === "billing"}>
              <BillingSection
                models={models}
                summary={summary}
                effectiveCostPerKnownToken={insights.effectiveCostPerKnownToken}
              />
            </TabPanel>

            <TabPanel active={activeTab === "runs"}>
              <RunsTable
                runs={summary.runs}
                filters={filters}
                roleOptions={roleOptions}
                tierOptions={tierOptions}
                adapterOptions={adapterOptions}
                modelOptions={modelOptions}
                branchOptions={branchOptions}
                onFilterChange={updateFilter}
              />
            </TabPanel>

            <TabPanel active={activeTab === "models"}>
              <section className="section-stack">
                <ModelsMatrix models={models} summary={summary} />
                {driftRuns.length > 0 && (
                  <section className="panel">
                    <div className="panel-header">
                      <h2>Drift recente</h2>
                      <span>{driftRuns.length} run(s)</span>
                    </div>
                    <div className="table-wrap compact-table">
                      <table>
                        <thead>
                          <tr>
                            <th>Started</th>
                            <th>Role</th>
                            <th>Tier</th>
                            <th>Configured</th>
                            <th>Observed</th>
                            <th>Effort</th>
                          </tr>
                        </thead>
                        <tbody>
                          {driftRuns.map((run) => (
                            <tr key={run.run_id}>
                              <td>{formatDate(run.started_at)}</td>
                              <td>{valueOrUnknown(run.role)}</td>
                              <td>{valueOrUnknown(run.tier)}</td>
                              <td className="drift-cell">{valueOrUnknown(run.configured_model)}</td>
                              <td className="drift-cell">{valueOrUnknown(run.observed_model)}</td>
                              <td>{valueOrUnknown(run.effort)}</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  </section>
                )}
                {draft && (
                  <ControlPlaneEditor
                    draft={draft}
                    validation={validation}
                    saveResult={saveResult}
                    busy={busy}
                    actionError={actionError}
                    onTierChange={updateTierField}
                    onToggleFallback={toggleFallback}
                    onValidate={() => {
                      void requestValidation();
                    }}
                    onSave={() => {
                      void requestSave();
                    }}
                  />
                )}
              </section>
            </TabPanel>

            <TabPanel active={activeTab === "events"}>
              <ConfigEventsSection
                events={state.configEvents}
                month={state.configEventsMonth}
                invalidLines={state.configEventsInvalidLines}
              />
            </TabPanel>
          </>
        )}
      </main>
    </div>
  );
}
