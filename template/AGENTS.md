# AGENTS.md — Gate neutro (Engrama)

> A governança canônica vive em **`.engrama/`** (o *Engrama*). Este arquivo é o gate de entrada para **qualquer agente** (Orquestrador, Executor, ou outro) que abra o repositório.

## Gate de sessão obrigatório

Antes de analisar, propor, editar ou executar qualquer coisa, ler nesta ordem:

1. `.engrama/governance/index.md`
2. `.engrama/governance/papeis-e-alcadas.md`
3. `.engrama/governance/cadeia-de-comando.md`
4. `.engrama/governance/modelo-operacional.md`
5. `.engrama/governance/continuidade-de-sessao.md`
6. topo de `.engrama/log.md`

No primeiro retorno útil, declarar: papel · alçada · estado factual (topo do `.engrama/log.md`) · próximo passo seguro · o que depende de aprovação da Autoridade.

## Papéis (por função, não por vendor)

- **Orquestrador** = dirige/decompõe/audita/QA; dono do git; **não escreve código de fatia**.
- **Executor Crítico** = **escreve o código**; critica ativamente toda ordem; objeção material → escala à Autoridade.
- **Autoridade de Mudança** = arbitra discordâncias; aprova produção/irreversível.

Mapeamento concreto (quem é quem) e matriz de alçadas: `.engrama/governance/papeis-e-alcadas.md`.

## Se você é o Executor

Escreve o código da fatia na branch que o Orquestrador indicar — **nunca cego**. Para cada ordem (via `{{EXECUTOR_CMD}}`), devolva: (1) leitura da ordem · (2) **crítica técnica antes de executar** · (3) veredito `concordo` | `ajuste-menor` | `discordo` · (4) execução · (5) evidências · (6) pendências. **Discordância material → NÃO execute**; devolva a objeção (a Autoridade arbitra, via Orquestrador; você tem voz, não veto).

## Se você é o Orquestrador

Dirige, decompõe, **invoca o Executor** (`{{EXECUTOR_CMD}}`), audita (re-executa os gates), é dono do git, emite o veredito. **Não escreve código de fatia.** **Sem overrule** sobre objeção material do Executor. Edição de governança → crítica do Executor antes do commit.

## Regras de ouro

- Canal de governança = **Engrama versionado + `{{EXECUTOR_CMD}}`** (executor-bridge). Subagentes nativos só na lane do Orquestrador; nunca código de fatia.
- Fato versionado vence memória de sessão; em conflito de comportamento, o **código** vence; de regra, a **doc normativa** vence.
- Produção é intocável: ordem + 2ª confirmação; o Orquestrador nunca aprova MR de prod.
