# Índice do Engrama

Catálogo navegável. Ler primeiro ao abrir o projeto: [[governance/index]] → topo de [[log]].

## Bootstrap do projeto
- [[project/bootstrap-do-projeto]] — finalidade, stack, comandos, superfícies sensíveis e checklist da primeira abertura.

## Governança (processo entre agentes)
- [[governance/index]] — porta de entrada; ordem de leitura.
- [[governance/modelo-operacional]] — princípios inegociáveis + separação de funções.
- [[governance/papeis-e-alcadas]] — tríade de papéis + matriz de alçadas.
- [[governance/cadeia-de-comando]] — protocolo Orquestrador ↔ Executor ↔ Autoridade + executor-bridge.
- [[governance/continuidade-de-sessao]] — abrir/trabalhar/encerrar/handoff.

## Decisões (ADRs)
- [[decisions/0001-governanca-tres-papeis]] — tríade Orquestrador/Executor/Autoridade + validação cruzada.
- [[decisions/0002-orquestrador-dono-do-git-executor-escreve]] — Orquestrador dono do git; Executor escreve código; Orquestrador não escreve fatia.
- [[decisions/0003-executor-bridge-orquestrador-invoca-executor]] — Orquestrador invoca Executor direto (`codex exec`); sem relay da Autoridade de rotina.
- [[decisions/0004-executor-critica-ativa-discordancia-escala-a-autoridade]] — Executor critica toda ordem; discordância → Autoridade decide.
- [[decisions/0005-orquestrador-qa-reexecucao-e-metricas]] — Orquestrador é QA; re-executa gates; dono das métricas.
- [[decisions/0006-governanca-nao-se-autoaprova]] — governança exige crítica do Executor antes do commit.
- [[decisions/0007-computer-use-duas-fases]] — computer-use: reconhecimento → aprovação → execução.
- [[decisions/0008-subagentes-so-na-lane-do-orquestrador]] — subagentes não executam código de fatia.
- [[decisions/0009-producao-intocavel-dupla-confirmacao]] — produção intocável (inativo até existir deploy).
- [[decisions/0010-roteamento-modelo-effort-do-executor]] — Orquestrador decide modelo+effort do Executor por tarefa (tiers T1–T4; conservador-pra-cima; risco=piso).
- [[decisions/0011-diff-binding-atestacao-verificavel]] — ledger pode vincular a crítica ao diff staged por `sha256`, com modo estrito opt-in/CI.

## Specs (playbooks operacionais — o "como")
- [[specs/README]] — índice + princípio (spec ≠ subagente).
- [[specs/orquestrador]] · [[specs/executor]] — papéis (Orquestrador / Executor nas variações).
- [[specs/executor-order]] — template da ordem ao Executor · [[specs/commit]] — checklist de commit.
- [[specs/test-writing]] — convenções do harness · [[specs/infra-runbook]] — infra/stack/N/A (sem servidor local).
- [[specs/licao-aprendida]] — loop falha→regra (a memória que compõe).

## Processo
- [[qa/criticas-do-executor]] — ledger de críticas do Executor (gpt-5.5) + gate mecânico de commit (ADR 0006/0010).

## Páginas do seu projeto (domínio · roadmap · QA · gaps)

> Template: aqui entram as páginas de `domain/`, `roadmap/`, `gaps/` e `qa/` DO SEU PROJETO (criadas conforme o trabalho avança). Este pack entrega só o esqueleto de governança/processo; o conteúdo de domínio, sequenciamento e cobertura é específico de cada projeto. Ao criá-las, registre-as nesta seção com um blurb curto e mantenha os cross-links (`touches`) em dia.
