# Índice do Engrama

Catálogo navegável. Ler primeiro ao abrir o projeto: [[memory/governance/index]] → topo de [[log]].

## Bootstrap do projeto
- [[memory/project/bootstrap-do-projeto]] — finalidade, stack, comandos, superfícies sensíveis e checklist da primeira abertura.

## Governança (processo entre agentes)
- [[memory/governance/index]] — porta de entrada; ordem de leitura.
- [[memory/governance/modelo-operacional]] — princípios inegociáveis + separação de funções.
- [[memory/governance/papeis-e-alcadas]] — tríade de papéis + matriz de alçadas.
- [[memory/governance/cadeia-de-comando]] — protocolo Orquestrador ↔ Executor ↔ Autoridade + executor-bridge.
- [[memory/governance/continuidade-de-sessao]] — abrir/trabalhar/encerrar/handoff.

## Decisões (ADRs)
- [[memory/decisions/0001-governanca-tres-papeis]] — tríade Orquestrador/Executor/Autoridade + validação cruzada.
- [[memory/decisions/0002-orquestrador-dono-do-git-executor-escreve]] — Orquestrador dono do git; Executor escreve código; Orquestrador não escreve fatia.
- [[memory/decisions/0003-executor-bridge-orquestrador-invoca-executor]] — Orquestrador invoca Executor direto (`codex exec`); sem relay da Autoridade de rotina.
- [[memory/decisions/0004-executor-critica-ativa-discordancia-escala-a-autoridade]] — Executor critica toda ordem; discordância → Autoridade decide.
- [[memory/decisions/0005-orquestrador-qa-reexecucao-e-metricas]] — Orquestrador é QA; re-executa gates; dono das métricas.
- [[memory/decisions/0006-governanca-nao-se-autoaprova]] — governança exige crítica do Executor antes do commit.
- [[memory/decisions/0007-computer-use-duas-fases]] — computer-use: reconhecimento → aprovação → execução.
- [[memory/decisions/0008-subagentes-so-na-lane-do-orquestrador]] — subagentes não executam código de fatia.
- [[memory/decisions/0009-producao-intocavel-dupla-confirmacao]] — produção intocável (inativo até existir deploy).
- [[memory/decisions/0010-roteamento-modelo-effort-do-executor]] — Orquestrador decide modelo+effort do Executor por tarefa (tiers T1–T4; conservador-pra-cima; risco=piso).
- [[memory/decisions/0011-diff-binding-atestacao-verificavel]] — ledger pode vincular a crítica ao diff staged por `sha256`, com modo estrito opt-in/CI.
- [[memory/decisions/0012-reconciliacao-de-memoria]] — `reconcilia:` explicita ADD/UPDATE/DELETE/NOOP contra a memória já versionada.
- [[memory/decisions/0013-bridge-resiliente-a-version-drift-do-codex]] — bridge parseia múltiplos schemas do `codex --json` + teste de contrato com o stream real (E3A não-vácuo).
- [[memory/decisions/0014-gate-de-release-repo-central]] — gate de release repo-central-only (CI derruba o job `test`; manifest explícito; escape `sem-release` bound-by-hash).
- [[memory/decisions/0015-absorcao-seletiva-metodologia-superpowers]] — absorve do Superpowers só a camada de método (TDD/planejamento/depuração) como specs; rejeita subagent-escreve-código + fluidez de papéis/runtime que apaga o bridge.
- [[memory/decisions/0016-runtime-model-router-usage-ledger]] — role+tier viram runtime via model-router; bridge registra rota e usage ledger local.

## Specs (playbooks operacionais — o "como")
- [[memory/specs/README]] — índice + princípio (spec ≠ subagente).
- [[memory/specs/orquestrador]] · [[memory/specs/executor]] — papéis (Orquestrador / Executor nas variações).
- [[memory/specs/executor-order]] — template da ordem ao Executor · [[memory/specs/commit]] — checklist de commit.
- [[memory/specs/ingestao-memoria-dois-fases]] — ingestão durável: candidato → reconciliação explícita com `reconcilia:`.
- [[memory/specs/test-writing]] — convenções do harness · [[memory/specs/infra-runbook]] — infra/stack/N/A (sem servidor local).
- [[memory/specs/licao-aprendida]] — loop falha→regra (a memória que compõe).
- [[memory/specs/tdd-red-green-refactor]] — disciplina test-first em loop estrito (RED→GREEN→REFACTOR). (ADR 0015)
- [[memory/specs/planejamento-de-fatia]] — brainstorming + plano em fatias pequenas antes da ordem ao Executor. (ADR 0015)
- [[memory/specs/depuracao-sistematica]] — RCA em 4 fases antes de corrigir; alimenta o loop falha→regra. (ADR 0015)

## Domain (padrões nomeados desta instância)
- [[memory/domain/validacao-cruzada-estrutural]] — separação estrutural entre escritor, auditor e árbitro; o gate prova cobertura, não identidade do crítico.
- [[memory/domain/escopo-e-identidade]] — namespacing de papel/agente/sessão/repo/branch+categoria que delimita memória e crítica.
- [[memory/domain/ponto-de-vista-e-representacao]] — auto-representação do sistema vs observação externa do Executor sobre a fatia.

## Workflows (narrativas end-to-end)
- [[memory/workflows/fluxo-operacional]] — fluxograma do Engrama com todos os caminhos (sessão · fatia código/governança/computer-use · gate · escalonamento · PR/CI/merge/release) + ingestão em duas fases. Mermaid inline + PNG/`.mmd` em `assets/`.

## Processo
- [[evidence/qa/criticas-do-executor]] — ledger de críticas do Executor (modelo configurado de crítica) + gate mecânico de commit (ADR 0006/0010/0016).
- `evidence/usage/` — ledger JSONL local de uso/billing gerado pelo executor-bridge (ADR 0016).

## Páginas do seu projeto (domínio · roadmap · QA · gaps)

- [[memory/gaps/metricas-de-engrama]] — estado das métricas mecanizadas do Engrama (densidade de enlaces, staleness) e pesquisas futuras sem runtime extra.
- [[memory/gaps/auditoria-e-plano-de-remediacao]] — registro histórico resolvido da auditoria inicial e do plano que originou gate/diff-binding/CI/sync.
- [[memory/gaps/follow-ups-pos-0.2.0]] — registro histórico fechado no PR #21 (release-gate sem heredoc; exemplos `ENGRAMA_VERSION=0.3.0`).

> Template: aqui entram as páginas de `memory/domain/`, `memory/roadmap/`, `memory/gaps/` e `evidence/qa/` DO SEU PROJETO (criadas conforme o trabalho avança). Este pack entrega só o esqueleto de governança/processo; o conteúdo de domínio, sequenciamento e cobertura é específico de cada projeto. Ao criá-las, registre-as nesta seção com um blurb curto e mantenha os cross-links (`touches`) em dia.
