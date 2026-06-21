---
type: spec
status: active
touches: [governance/continuidade-de-sessao, decisions/0003-executor-bridge-orquestrador-invoca-executor, decisions/0010-roteamento-modelo-effort-do-executor]
date: 2026-06-20
source_refs:
  - .engrama/governance/continuidade-de-sessao.md
  - .engrama/decisions/0010-roteamento-modelo-effort-do-executor.md
---

Template da **ordem ao Executor** (executor-bridge). Toda invocação `codex exec` segue isto. Detalhe normativo: [[governance/continuidade-de-sessao]] (ordem mínima) + [[decisions/0010-roteamento-modelo-effort-do-executor]] (tier).

## Cabeçalho obrigatório (o Orquestrador declara)
- **Tier + modelo + effort + porquê** (ADR 0010): ex. "T3: `gpt-5.4`/high — fatia de contrato, risco médio". Crítica → sempre `gpt-5.5`.
- Papel: "Você é o Executor, Executor Crítico."

## Corpo (10 itens mínimos)
1. objetivo da fatia · 2. estado factual conhecido · 3. escopo · 4. **fronteiras** (o que NÃO tocar: ambiente/serviço legado/prod/app-novo conforme o caso) · 5. critérios de aceite · 6. validações esperadas · 7. riscos conhecidos · 8. o que depende de aprovação da Autoridade · 9. próximo passo seguro · 10. tier/modelo escolhido.

> Exemplo (troque pelo do seu projeto): o item 4 (fronteiras) é onde o Orquestrador isola o sistema legado e a produção. Num projeto que migra de uma base anterior, valeria escrever algo como "não tocar no app legado em `N/A (sem servidor local)`, não tocar em código de produção, não tocar fora da fatia X" — adapte os alvos concretos ao seu layout.

## Resposta exigida do Executor (6 itens)
leitura · **crítica técnica (antes de executar)** · **veredito** (`concordo`/`ajuste-menor`/`discordo`) · execução · evidências · pendências.

## Mecânica do `codex exec` (lições operacionais — ADR 0003)
- **Sempre fechar o stdin (`< /dev/null` ou equivalente)** (senão a invocação trava lendo input adicional do stdin esperando um EOF que não chega).
- **Saída estruturada/streaming** (progresso ao vivo, para distinguir "trabalhando" de "travado") · **watchdog** generoso (≥600s; e2e/critique mais).
- Seleção de modelo por invocação (flag de modelo) · esforço de raciocínio por invocação (flag de `model_reasoning_effort`, ex.: `low|medium|high|xhigh`).
- **Transparência (ADR 0003):** colar à Autoridade a **ordem verbatim** e a **resposta na íntegra**.

> **Template:** os flags exatos (fechar stdin, modo de saída JSON/streaming, flag de modelo, flag de esforço de raciocínio, watchdog) dependem da CLI do seu `codex exec`. Fixe a sintaxe real do seu executor ao instanciar este pack; o que é universal é o princípio — stdin fechado, saída observável ao vivo, timeout folgado, e ordem+resposta expostas verbatim à Autoridade.

## Pós-resposta (Orquestrador)
- `discordo` material → **apresentar à Autoridade** (sem overrule, ADR 0004).
- Auditar (re-executar gates, ADR 0005) → reprovou → **retry upshifta tier**.
- Aprovado → commit ([[specs/commit]]).
