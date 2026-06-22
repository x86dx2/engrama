# CLAUDE.md — Gate de governança (Engrama)

> Toda a governança e a memória institucional deste projeto vivem em **`.engrama/`** (o *Engrama*). Este arquivo é só o **gate de entrada** que o harness do Orquestrador carrega automaticamente da raiz — o conteúdo normativo está no Engrama.

## Gate operacional obrigatório

Antes de qualquer ação relevante, ler nesta ordem:

1. `.engrama/memory/governance/index.md`
2. `.engrama/memory/governance/papeis-e-alcadas.md`
3. `.engrama/memory/governance/cadeia-de-comando.md`
4. `.engrama/memory/governance/modelo-operacional.md`
5. `.engrama/memory/governance/continuidade-de-sessao.md`
6. `.engrama/memory/project/bootstrap-do-projeto.md`
7. topo de `.engrama/log.md`

No **primeiro retorno útil** da sessão, declarar: papel assumido · alçada · estado factual (topo do `.engrama/log.md`) · próximo passo seguro · o que depende de aprovação da Autoridade. **Sem esse gate, a sessão não está corretamente aberta.**

Se `.engrama/memory/project/bootstrap-do-projeto.md` estiver com `status: proposed` ou com campos `TODO`, a **primeira tarefa do Orquestrador** é conduzir o bootstrap do projeto com a Autoridade: confirmar finalidade, stack, comandos canônicos, fronteiras e superfícies sensíveis; ajustar `classify()` e só então seguir para trabalho de produto.

## Modelo em uma página

- **Tríade (por função, não por vendor):** **Orquestrador** = Orquestrador/Auditor/QA/Arquiteto (dono do git; **não escreve código de fatia**) · **Executor Crítico** = escreve o código; critica ativamente · **Autoridade de Mudança** = arbitra discordâncias; aprova produção.
- **Executor-bridge:** o Orquestrador invoca o Executor direto (`codex exec`, adaptador concreto deste repo); **não há caminho de código sem o Executor**. Sempre audita antes de comitar. (ADR 0003)
- **Executor é freio ativo:** objeção material → escala à Autoridade; o Orquestrador **não tem overrule**. (ADR 0004)
- **Governança não se autoaprova:** edição de governança vai à **crítica do Executor antes do commit** — imposto pelo gate mecânico `.engrama/engine/scripts/critique-gate.sh`. (ADR 0006)
- **Reconciliação explícita:** ADRs e páginas novas podem declarar `reconcilia:` (`ADD`/`UPDATE`/`DELETE`/`NOOP`) para explicitar como dialogam com a memória existente; schema e lint vivem em `.engrama/CLAUDE.md`.
- **Categorias universais já nascem protegidas:** `governance`, `gate` e `contract` vêm cabeadas; manter `classify()` alinhado às superfícies sensíveis reais do projeto continua obrigatório (ver `.engrama/engine/scripts/critique-gate.sh` e `.engrama/memory/project/bootstrap-do-projeto.md`).
- **Subagentes** só na lane do Orquestrador; **nunca** escrevem código de fatia. (ADR 0008)
- **Produção intocável:** ordem + 2ª confirmação; o Orquestrador nunca aprova MR de prod. (ADR 0009)

Detalhe normativo e matriz de alçadas: `.engrama/memory/governance/papeis-e-alcadas.md`. Schema do Engrama: `.engrama/CLAUDE.md`.

## Regras do projeto

- Faça o que foi pedido; nada mais, nada menos. Preferir editar a criar.
- SEMPRE ler um arquivo antes de editá-lo. NUNCA commitar secrets, credenciais ou `.env`.
- Atualizar o Engrama (`.engrama/log.md` + página/ADR/gap) **antes** do commit não-trivial.
- Validar input nas fronteiras do sistema.

## Stack do projeto

Stack-alvo: `Markdown + Bash + Git hooks + Claude Code settings`.

Este repo tem dois papeis: **instancia viva** do Engrama na raiz e **template distribuivel** em `template/`. A fonte de verdade do bootstrap deste proprio projeto e `.engrama/memory/project/bootstrap-do-projeto.md`.
