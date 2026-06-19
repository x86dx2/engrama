---
type: decision
status: active
touches: [decisions/0003-executor-bridge-orquestrador-invoca-executor, decisions/0005-orquestrador-qa-reexecucao-e-metricas, decisions/0008-subagentes-so-na-lane-do-orquestrador]
date: {{DATA}}
critica_tecnica: incorporada
source_refs:
  - {{REPO_PATH}}/.engrama/decisions/0003-executor-bridge-orquestrador-invoca-executor.md
---

Política de **roteamento de modelo + effort** do executor-bridge: o Orquestrador decide, por tarefa, qual modelo e esforço o `{{EXECUTOR_CMD}}` usa — e qual a própria abordagem (solo/paralelo/profundidade de auditoria). Refina a "Escalonamento de força" da [[decisions/0003-executor-bridge-orquestrador-invoca-executor]]. Postura: **conservador-pra-cima** (default alto; descer exige justificativa). **Modelos de EXECUÇÃO para escrever código; o papel de CRÍTICA usa o maior modelo aprovado** (`{{MODELO_CRITICA}}`) — ver "Exceção" abaixo (decisão da Autoridade).

> **Template:** preencha os ids reais de modelo do seu projeto. Aqui usamos três faixas canônicas: `{{MODELO_EXECUTOR_LEVE}}` (barato/rápido, execução), `{{MODELO_EXECUTOR_PESADO}}` (forte, execução) e `{{MODELO_CRITICA}}` (o maior aprovado, reservado ao papel de crítica). A rubrica e a postura abaixo são portáveis; só a tabela tier→modelo precisa dos ids concretos.

## Knobs reais (executor)
- Modelo: flag de modelo do `{{EXECUTOR_CMD}}` — execução usa `{{MODELO_EXECUTOR_LEVE}}` (barato/rápido) e `{{MODELO_EXECUTOR_PESADO}}` (forte). `{{MODELO_CRITICA}}` é **reservado ao papel de crítica** (ver Exceção). Modelos não aprovados não entram sem ordem.
- Effort: flag de esforço de raciocínio (`model_reasoning_effort`) ∈ `low | medium | high | xhigh`. (Se o default global do executor for o máximo, controlar **explicitamente** por chamada.)

> **Template:** confirme a sintaxe real das flags do seu `{{EXECUTOR_CMD}}` (flag de modelo e flag de esforço) e o conjunto de níveis de effort que ele aceita.

## Rubrica (5 eixos por tarefa)
1. **Complexidade** — profundidade de raciocínio (trivial → difícil).
2. **Risco** — superfície sensível? (invariante de domínio / consistência de dados / RBAC / tenant / segurança / fluxo crítico).
3. **Ambiguidade** — spec clara → exploratório.
4. **Throughput** — fatia de lote paralelo (pressiona pra baixo) vs one-off.
5. **Verificabilidade** — quão fácil é falsificar/auditar o resultado? Teste fraco, difícil de observar ou pouca evidência independente → **sobe** (mesmo sem grande complexidade de domínio). (eixo acrescido pela crítica do Executor)

## Matriz do Executor (postura conservador-pra-cima)

**Default = T3 (`{{MODELO_EXECUTOR_PESADO}}` / high).** Descer para T1/T2 exige justificativa afirmativa; em dúvida, fica em T3 ou sobe.

| Tier | Quando (tem que se aplicar claramente) | Modelo | Effort |
|---|---|---|---|
| **T1** | trivial mecânico inequívoco: rename, format, port literal, mensagem, 1–2 linhas, regen de template determinístico | `{{MODELO_EXECUTOR_LEVE}}` | low |
| **T2** | simples mas não-trivial, spec 100% clara, zero nuance de domínio, baixo risco | `{{MODELO_EXECUTOR_PESADO}}` | medium |
| **T3 (default)** | qualquer fatia padrão: lógica de negócio, contrato HTTP, e2e, refactor não-trivial; **dúvida cai aqui** | `{{MODELO_EXECUTOR_PESADO}}` | high |
| **T4** | governança/arquitetura/incidente · debugging com evidência conflitante · **sensível + agravante** (ver "risco define piso") | `{{MODELO_EXECUTOR_PESADO}}` *(salvo crítica → modelo máximo)* | **high** (default) |
| **T4+ (xhigh, só por gatilho)** | xhigh **só** quando: arquitetura nova, debugging com evidência contraditória, **ou 2 auditorias falhadas** no mesmo item | `{{MODELO_EXECUTOR_PESADO}}` | xhigh |

> **"Leve" estreitado (vs ADR 0003):** a postura conservador-pra-cima **restringe o caminho barato (`{{MODELO_EXECUTOR_LEVE}}`) ao trivial mecânico (T1)**. A 0003 dizia "leve → modelo barato" de forma ampla; aqui só T1 cai no modelo leve, o resto é `{{MODELO_EXECUTOR_PESADO}}`.

## Exceção: crítica SEMPRE no modelo máximo (diretiva da Autoridade)

Quando o Executor é acionado no **papel de crítica**, o **modelo é sempre o maior aprovado pela Autoridade** (`{{MODELO_CRITICA}}`), independente do tier/postura. Motivo: a crítica é o **gate de qualidade** (pega falsos-verdes e falhas de governança); ali queremos o máximo poder de modelo. Sobrepõe a regra geral "execução = modelos de execução".

**Definição de "papel de crítica" (escopo fechado — ajuste da própria crítica):** invocação cujo **entregável primário é avaliar/refutar/validar**, read-only, **sem produzir patch/código aplicável**.

| Conta como crítica → `{{MODELO_CRITICA}}` | NÃO conta (segue a matriz de execução) |
|---|---|
| Crítica de governança (ADR 0006) | A **crítica obrigatória que o Executor faz antes de executar** uma ordem (parte de toda execução — senão TUDO viraria crítica máxima) |
| Crítica de análise de causa-raiz (ADR 0006 item 7) | Ordem de execução de código/teste |
| Code review read-only · refutação adversarial de findings | Auditoria normal do Orquestrador (a menos que o Executor seja invocado p/ refutar essa auditoria) |
| Ordem **híbrida** "critique e implemente" → **separar em 2 chamadas**: crítica em `{{MODELO_CRITICA}}`, execução em modelo de execução conforme tier | |

- **Effort** segue o tier da crítica (governança/sensível = T4 → `high`; `xhigh` por gatilho). A diretiva fixa o **modelo**, não o effort.
- **Fallback se `{{MODELO_CRITICA}}` indisponível:** NÃO cair silenciosamente para um modelo de execução (violaria a regra) → **escalar à Autoridade** (waiver explícito ou aguardar).
- **Guardrail:** qualquer lote com `{{MODELO_CRITICA}}` concorrente acima do cap, ou qualquer `{{MODELO_CRITICA}}/xhigh`, **avisa a Autoridade** antes (custo).
- **Calibração:** após 10–20 críticas em `{{MODELO_CRITICA}}`, medir custo/latência/taxa de achados acionáveis/falso-positivo/consenso vs `{{MODELO_EXECUTOR_PESADO}}/high`, e reavaliar.

## Matriz do Orquestrador (auto-roteamento — modelo fixo; alavancas de esforço)

| Situação | Abordagem |
|---|---|
| Código de fatia | → **sempre Executor** (nunca o Orquestrador — ADR 0008) |
| Análise ampla/paralelizável (mapear, multi-lente, auditar muitos) | → **subagentes nativos do Orquestrador em paralelo** |
| Análise/decisão/git/docs focada | → **solo** |
| Auditoria de fatia T3/T4 | → re-rodar gates **2–3×** (idempotência) + checagem adversarial |
| Auditoria de fatia T1/T2 | → 1 re-execução |

## Regras operacionais
- **Declarar o tier em cada ordem** ao Executor (transparência): "T_n: `modelo`/`effort` porque…". A Autoridade vê e pode sobrepor.
- **Risco define PISO, não teto** (ajuste-chave da crítica do Executor): superfície sensível (RBAC/invariante/fluxo crítico) põe a tarefa em **mínimo T3** — vira **T4 só se houver agravante** (ambiguidade alta, irreversibilidade, baixa verificabilidade, ou debugging difícil). Isso evita "tudo vira T4" e preserva o poder discriminatório da rubrica.
- **xhigh é exceção por gatilho**, não default de T4: só arquitetura nova, debugging com evidência contraditória, ou **2 auditorias falhadas** no mesmo item.
- **Retry upshifta:** auditoria reprovada (falso-verde, flakiness) → a re-tentativa sobe ≥1 tier (2ª falha → xhigh).
- **Throughput não rebaixa risco:** num lote paralelo, o trivial vai pra T1, mas o sensível segue seu piso — paralelizar não é desculpa pra baixar effort no que importa.
- **Guardrail de custo/paralelização:** lote com **> 6 chamadas concorrentes em `{{MODELO_EXECUTOR_PESADO}}/high`+** (ou qualquer `xhigh`) → **avisar a Autoridade antes** (apetite de custo é decisão dela). Cap default tunável.
- **Autoridade sobrepõe** qualquer escolha.

> **Template:** calibre o cap de concorrência (aqui, 6 chamadas em `{{MODELO_EXECUTOR_PESADO}}/high`+) ao apetite de custo e aos limites de rate/quota do seu projeto.

## Anti-drift (reavaliar com dado)
A cada **20–30 chamadas** (ou fim de ciclo), medir e logar: **distribuição T1–T4**, **taxa de falso-verde** (auditorias reprovadas), e **custo por fatia**. Se quase tudo cair em T3/T4, recalibrar as fronteiras (a postura conservador-pra-cima não pode degenerar em "tudo full/high").

## Consequências
- Custo/latência por chamada maior que "conservador-pra-baixo", mas qualidade máxima por chamada — alinhado a "errar sai caro". Paralelização ganha wall-clock; economia vem do T1 (trivial → modelo leve).
- "Risco define piso" + "xhigh só por gatilho" mantêm a postura **conservador-pra-cima sem degenerar** em T4-universal.
- A política **se auto-aplica**: a crítica desta própria ADR (e da governança inicial) já roda sob ela — no papel de crítica, modelo máximo (`{{MODELO_CRITICA}}`), pegando contradições internas e guardrails ausentes antes do commit.
