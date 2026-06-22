---
type: decision
status: active
touches: [memory/governance/cadeia-de-comando, memory/governance/papeis-e-alcadas, memory/decisions/0002-orquestrador-dono-do-git-executor-escreve, memory/decisions/0004-executor-critica-ativa-discordancia-escala-a-autoridade]
date: 2026-06-20
source_refs:
  - CLAUDE.md
---

O **Orquestrador invoca o Executor diretamente** (`codex exec`), fechando o loop de execução **sem relay humano de rotina**. É a peça que torna o handoff autônomo até a fronteira de produção.

## Contexto
Num modelo de handoff mediado, a passagem Orquestrador→Executor dependia da Autoridade repassar a ordem manualmente — gargalo humano em cada ciclo. Neste ambiente, foi **comprovado** que o harness do Orquestrador consegue invocar o Executor headless via shell, passar a ordem e ler a saída — inclusive com `--output-schema` para resposta estruturada.

> Nota: se este modelo for portado de um projeto anterior cujo handoff era mediado pela Autoridade, o executor-bridge é exatamente a mudança que elimina esse relay de rotina.

## Decisão
- O Orquestrador monta a **ordem mínima** (ver [[memory/governance/continuidade-de-sessao]]) e chama `codex exec --model <tier> [--output-schema]`.
- **Roteamento pesado/leve = modelo do Executor**, não se o Executor participa: **não existe caminho de código sem o Executor** (o Orquestrador nunca executa). Leve → modelo barato (ex.: `gpt-5.4-mini`); pesado → modelo full (ex.: `gpt-5.4`).
- A Autoridade fica **fora do handoff de rotina**; entra só em (a) discordância material do Executor e (b) fronteira de produção.
- O Orquestrador **sempre audita** a devolutiva (ver [[memory/decisions/0005-orquestrador-qa-reexecucao-e-metricas]]) antes de comitar.

## Consequências
- Loop autônomo até staging; a Autoridade como Autoridade de Mudança nas fronteiras.
- Custo: cada invocação do `codex exec` é um turno do Executor — o roteamento manda só o **pesado** ao modelo caro.
- Confiabilidade: usar saída em JSON (progresso ao vivo) + timeout de boot generoso + perfil de tooling enxuto para não pagar o boot de todos os servidores auxiliares a cada chamada.
- A validação cruzada se mantém: o Executor é processo/modelo independente mesmo quando o Orquestrador o invoca.

## Break-glass: ausência do Executor (ADR 0006)

Como "não existe caminho de código sem o Executor", se não houver Executor disponível o desenvolvimento de código **para por definição** (default seguro). Exceção **break-glass**, só sob **ordem explícita da Autoridade**: escopo mínimo declarado + **log obrigatório** em `log.md` + **revisão retroativa obrigatória do Executor** quando voltar (auditoria a posteriori do que foi feito sem ele). Sem ordem da Autoridade, código sem Executor **aguarda** — não vira "o Orquestrador escreve a fatia".

## Notas operacionais da invocação do `codex exec`

- **Fechar o stdin: `< /dev/null`.** Em background, a invocação pode bloquear lendo stdin esperando EOF que não chega → trava indefinida. Sempre redirecionar stdin.
- **Timeout generoso.** O modelo executor pesado com esforço de raciocínio alto + leitura de muitos arquivos pode passar de vários minutos; usar watchdog folgado (≥600s) e nunca matar mid-trabalho.
- **Saída em JSON** para ver progresso ao vivo (eventos de item) e distinguir "trabalhando" de "travado".
- **Prompt focado + esforço de raciocínio proporcional** (flag de `model_reasoning_effort`): escopo enxuto converge muito mais rápido; não pedir auditoria exaustiva quando o que se quer é julgamento.

## Escalonamento de força (decisão da Autoridade)

Para ganhar throughput (ex.: uma frente com muitas fatias independentes), a força vem de **concorrência de executores + auditoria paralela DENTRO do modelo provado** — não de um swarm de subagentes:
- **N invocações do `codex exec` em paralelo**, uma por **fatia independente** (executores independentes; cada um auditado pelo Orquestrador → cross-validation preservada).
- **Subagentes nativos do Orquestrador em paralelo** apenas na **lane do Orquestrador** (auditoria/pesquisa/codemod/análise) — nunca como executores de código (reafirma [[memory/decisions/0008-subagentes-so-na-lane-do-orquestrador]]).
- **Swarm de subagentes NÃO adotado** como modelo de execução: os "agentes" de qualquer tooling de swarm/orquestração de subagentes são camada de coordenação/prompts backed pelos mesmos modelos (não engines a mais) e colidiriam com a tríade (um subagente backed pelo mesmo modelo do Orquestrador escrevendo código quebra escritor≠auditor). Esse tooling permanece **opcional e subordinado** — nunca o canal de governança.

> **Template:** decida no seu projeto qual tooling de swarm/orquestração de subagentes (se algum) fica disponível como auxiliar inerte, e deixe explícito que ele **não** é o canal de governança — o canal é o engrama versionado + `codex exec`.

## Transparência para a Autoridade

Todo I/O do executor-bridge continua **exposto à Autoridade**, mas agora isso é
**mecanizado**:
- `.engrama/engine/scripts/exec-bridge.sh` invoca `codex exec --json`, salva a **ordem verbatim** em
  `.engrama/evidence/transcripts/<data>-<label>-order.md` e a **resposta íntegra** em
  `.engrama/evidence/transcripts/<data>-<label>-response.md`.
- O transcript da resposta registra `codex-session`, modelo, sandbox e `label`
  no cabeçalho YAML.
- O wrapper imprime `codex-session:<id>` para que o Orquestrador o cole no
  ledger como rastro de execução; quando o stream do `codex exec` não expõe um
  id de sessão, o wrapper deriva um identificador determinístico da resposta e o
  marca como `derived`.

Isto reforça a "apresentação fiel"
([[memory/decisions/0004-executor-critica-ativa-discordancia-escala-a-autoridade]]): a
Autoridade audita o que o Executor recebeu e devolveu por artefato versionado,
sem depender de `/tmp` nem de relay manual do Orquestrador.

## Pendência de design (a confirmar ao construir o harness)
- Flag exata de modelo por invocação (`--model` vs `-c model=`) — o esforço de raciocínio por flag (`model_reasoning_effort`) é o caminho confirmado.
- Schema de saída para os itens da resposta do Executor.

> **Template:** ao instanciar este modelo, fixe a sintaxe real do seu `codex exec` (flag de modelo, flag de esforço, formato de `--output-schema`) e o schema dos itens que o Executor deve devolver.
