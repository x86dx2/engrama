---
type: decision
status: proposed
touches: [memory/decisions/0002-orquestrador-dono-do-git-executor-escreve, memory/decisions/0006-governanca-nao-se-autoaprova, memory/decisions/0008-subagentes-so-na-lane-do-orquestrador, memory/decisions/0005-orquestrador-qa-reexecucao-e-metricas, memory/specs/tdd-red-green-refactor, memory/specs/planejamento-de-fatia, memory/specs/depuracao-sistematica]
date: 2026-06-27
source_refs:
  - .engrama/memory/specs/README.md
  - .engrama/memory/specs/test-writing.md
  - .engrama/memory/specs/executor-order.md
  - .engrama/memory/specs/licao-aprendida.md
  - .engrama/CLAUDE.md
reconcilia: ADD
---

**Absorver do [Superpowers](https://github.com/obra/Superpowers) (obra) apenas a camada de MÉTODO, como specs markdown — nunca como runtime/plugin — e rejeitar explicitamente os pontos que colidem com a governança.** Mesma manobra da absorção mem0/Honcho ([[memory/decisions/0012-reconciliacao-de-memoria]]): o padrão nomeado vira doc; a ferramenta não entra.

## Contexto

O Superpowers é uma **metodologia de desenvolvimento para agentes** entregue como biblioteca de skills auto-disparáveis + plugins cross-platform (Claude Code, Cursor, Codex, Gemini, etc.). Fluxo de 7 fases: brainstorm → git worktree → plano (tarefas de 2-5 min) → subagent-driven development → TDD (RED-GREEN-REFACTOR) → code review → fechar branch.

Avaliado quanto a **agregar valor à governança** deste repo. Diagnóstico:

- O Superpowers é sistema de **craft/workflow** (o "como" da engenharia), não de **governança** (não tem árbitro/Autoridade, não tem gate que bloqueia commit, não tem diff-binding nem memória institucional reconciliada).
- Onde ele toca governança, **o Engrama já é mais forte**: `requesting-code-review` ≈ crítica do Executor, mas a do Engrama é **mecanicamente imposta** ([[memory/decisions/0006-governanca-nao-se-autoaprova]] + `critique-gate.sh`), com **separação de papéis** e **diff-binding** ([[memory/decisions/0011-diff-binding-atestacao-verificavel]]); `verification-before-completion` ≈ [[memory/decisions/0005-orquestrador-qa-reexecucao-e-metricas]].
- O valor real está na **camada de método** (o "como" do Executor / `memory/specs/`), que o Engrama hoje não formaliza por completo.

## Decisão

### Absorver (como specs markdown, `status: proposed` → `active` na aprovação)

1. **TDD RED-GREEN-REFACTOR** → [[memory/specs/tdd-red-green-refactor]] (complementa [[memory/specs/test-writing]], que já cita o ciclo RED→GREEN, formalizando o REFACTOR e a ordem test-first).
2. **Planejamento de fatia (brainstorming + writing-plans)** → [[memory/specs/planejamento-de-fatia]] (alimenta o [[memory/specs/executor-order]]: refinar requisitos e quebrar em tarefas pequenas ANTES da ordem ao Executor).
3. **Depuração sistemática (RCA em fases)** → [[memory/specs/depuracao-sistematica]] (complementa o loop falha→regra de [[memory/specs/licao-aprendida]]).
4. **verification-before-completion** → **sem spec nova**: reforça [[memory/decisions/0005-orquestrador-qa-reexecucao-e-metricas]] (Orquestrador QA re-executa gates). Citado aqui, não duplicado.

### Rejeitar (incompatível com a governança — reafirma ADRs existentes)

- **subagent-driven-development que ESCREVE código** — quebra [[memory/decisions/0002-orquestrador-dono-do-git-executor-escreve]] e [[memory/decisions/0008-subagentes-so-na-lane-do-orquestrador]] e a **validação cruzada estrutural** (escritor ≠ auditor; [[memory/domain/validacao-cruzada-estrutural]]). Só o Executor escreve código de fatia, via bridge. Subagentes do Orquestrador ficam na lane de análise.
- **Plano que carrega código/patch aplicável** — o `writing-plans` do Superpowers descreve tarefas **com código pronto**. Absorvemos só o plano (requisito + fatia + critério de aceite + arquivos prováveis); plano-com-código seria **autoria indireta pelo Orquestrador**, vedada por [[memory/decisions/0008-subagentes-so-na-lane-do-orquestrador]] (código/patch é exclusivo do Executor). Ver fronteira em [[memory/specs/planejamento-de-fatia]].
- **Iteração autônoma "por horas" sem checkpoints** — colide com o núcleo **ATIVO**: ordem por fatia + **freio ativo do Executor sem overrule** ([[memory/decisions/0004-executor-critica-ativa-discordancia-escala-a-autoridade]]) e menor fatia possível ([[memory/specs/orquestrador]]). (Quando houver deploy, soma-se [[memory/decisions/0009-producao-intocavel-dupla-confirmacao]], hoje `proposed`/inativa — por isso não é a âncora principal.)
- **Fluidez de papéis / runtime que apaga o bridge** — **NÃO** rejeitamos portabilidade entre ferramentas: papéis são **por função, não por vendor**, e o mapeamento é mutável ([[memory/governance/papeis-e-alcadas]]). O que se rejeita é "qualquer agente faz qualquer papel" e qualquer runtime que dissolva a **separação escritor↔auditor** ou o **executor-bridge** ([[memory/domain/escopo-e-identidade]], [[memory/decisions/0003-executor-bridge-orquestrador-invoca-executor]]) — é a independência estrutural, não o vendor, que dá sentido ao cross-check.
- **Incorporar como runtime/plugin** — fere o princípio do `.engrama/CLAUDE.md`: canônico = **markdown versionado**; tooling de swarm/orquestração = **descartável**, "sobrevive a desinstalar qualquer tooling". Reafirma o princípio "spec ≠ subagente" do [[memory/specs/README]].

## Alternativas consideradas

- **Incorporar o Superpowers inteiro (runtime/plugin).** Rejeitado: traz o subagent-escreve-código e a abstração cross-platform, que quebram o núcleo; e adiciona runtime contra o princípio markdown-puro.
- **Ignorar.** Rejeitado: perde método útil (TDD estrito, planejamento, RCA) que hoje é informal.
- **Fork/adaptar o runtime.** Rejeitado: custo de manutenção de tooling + mesma colisão de princípio (canônico = markdown).

## Consequências

- +3 specs (`tdd-red-green-refactor`, `planejamento-de-fatia`, `depuracao-sistematica`); reforço a ADR 0005; **zero** mudança em papéis, alçadas ou no gate.
- A rejeição explícita **reafirma** ADR 0002/0008/0004/0009 e o princípio "spec ≠ subagente" — vira referência citável quando alguém propuser swarm que escreve código.
- Nenhuma dependência, plugin ou ferramenta externa entra no repo. As specs são agnósticas de stack como as demais.

## Atribuição

Inspiração: **Superpowers** (obra / Jesse Vincent), <https://github.com/obra/Superpowers>. Absorvemos o **padrão nomeado**, não o código — mesmo critério da absorção mem0/Honcho ([[memory/decisions/0012-reconciliacao-de-memoria]]).

## Status

`proposed`. Por ser mudança de governança/processo, depende da **crítica do Executor** ([[memory/decisions/0006-governanca-nao-se-autoaprova]]) e da **aprovação da Autoridade** antes do commit. Na aprovação: ADR → `active`, specs → `active`.
