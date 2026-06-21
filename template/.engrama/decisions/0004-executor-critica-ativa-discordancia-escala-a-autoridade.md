---
type: decision
status: active
touches: [governance/cadeia-de-comando, governance/papeis-e-alcadas, governance/modelo-operacional, decisions/0003-executor-bridge-orquestrador-invoca-executor]
date: {{DATA}}
source_refs:
  - CLAUDE.md
  - .engrama/governance/cadeia-de-comando.md
---

O **Executor critica ativamente toda ordem** antes de executar. **Discordância material → o Executor não executa, devolve objeção + justificativas ao Orquestrador, e o Orquestrador apresenta o conflito à Autoridade, que decide. O Orquestrador NÃO tem overrule.**

## Contexto
Sem este endurecimento, a discordância do Executor poderia "voltar ao Orquestrador **ou** à Autoridade" — o Orquestrador podia redecidir sozinho. Decisão da Autoridade: **endurecer** — toda discordância material vai à Autoridade, para que o Orquestrador não racionalize por cima da objeção do Executor. O Executor vira um **freio ativo** sobre as ordens do Orquestrador.

> Template: se este modelo for portado de um projeto anterior em que a discordância podia ser reabsorvida pelo orquestrador sozinho, trate aquilo como o estado a ser **superado** — o contrato deste pack é o endurecimento descrito aqui.

## Decisão
- O Executor avalia a ordem e devolve veredito: `concordo` | `ajuste-menor` (assume e segue) | `discordo`.
- `ajuste-menor` → o Orquestrador incorpora e segue.
- `discordo` (material) → o Executor **não executa**; o Orquestrador **apresenta à Autoridade** a ordem **e** a objeção do Executor (fielmente, como ele escreveu) + sua própria leitura; **a Autoridade decide**, e a decisão vira nova ordem.
- Vale para **ordem de execução de código** e para **mudança de governança** (ver [[decisions/0006-governanca-nao-se-autoaprova]]) — colapsa numa regra única.

## Consequências
- A Autoridade é a **árbitra de toda discordância Orquestrador↔Executor** — entra automaticamente no conflito, não na rotina.
- O Orquestrador perde o poder de overrule sobre objeções do Executor; ganha o dever de **apresentação fiel**.
- Custo: discordâncias param o loop e exigem a Autoridade — aceitável, pois discordância material é rara e é exatamente onde o julgamento humano agrega.

## Ajustes incorporados (crítica do Executor via ADR 0006)

A crítica independente do Executor (veredito `ajuste-menor`) apontou que "material" estava sem contrato, faltava resolver "Autoridade decide × Executor ainda recusa", e havia risco de loop infinito. Incorporado:

- **Definição de "discordância material" — 4 gatilhos fechados:** (1) risco de perda de dados; (2) quebra do fluxo principal; (3) ação irreversível sem aprovação; (4) contradição séria com o estado real ou com a governança/alçada. (Quando houver deploy, somam-se: contaminação staging/prod, deploy no ambiente errado.) Fora desses gatilhos = `ajuste-menor`, não discordância material.
- **Quem marca a materialidade:** o **Executor** marca, com justificativa objetiva apontando qual gatilho. A **Autoridade arbitra o mérito**, não a existência da objeção (não cabe ao Orquestrador descartar a objeção como "não-material").
- **Override com dupla confirmação (decisão da Autoridade):** a Autoridade continua sendo a palavra final, **mas** para passar por cima de uma objeção material do Executor precisa de uma **2ª confirmação explícita reconhecendo o gatilho específico** (espelha "produção intocável", [[decisions/0009-producao-intocavel-dupla-confirmacao]]). A objeção do Executor fica **sempre logada** em `log.md`/páginas de `gaps/` do seu projeto, mesmo quando sobreposta.
- **Regra anti-loop:** se o **mesmo conflito** repetir após **2 rodadas** (`ordem → objeção → Autoridade → mesma ordem → mesma objeção`), as únicas saídas permitidas são: **waiver da Autoridade registrado**, **reformular a fatia**, ou **bloqueio formal** nas páginas de `gaps/` do seu projeto. Não se admite uma 3ª rodada idêntica.
