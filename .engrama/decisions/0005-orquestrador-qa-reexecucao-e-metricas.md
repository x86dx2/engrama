---
type: decision
status: active
touches: [governance/papeis-e-alcadas, governance/cadeia-de-comando, 0002-orquestrador-dono-do-git-executor-escreve]
date: 2026-06-20
source_refs:
  - CLAUDE.md
---

O **Orquestrador é QA**: antes de aceitar/comitar uma fatia, **re-executa** os gates por conta própria e anexa a saída real. **"Verde reportado pelo Executor ≠ verde verificado."** O Orquestrador **define e é dono das métricas de qualidade**; o Executor **escreve** os testes/tooling sob a spec do Orquestrador.

## Decisão
- O Orquestrador re-roda `build`/`lint`/`test`/`e2e` conforme o tipo de fatia (o **gate real** é o que reproduz o ambiente de entrega — ver exemplo abaixo; checagens parciais não bastam) e **anexa a saída real** como evidência.

  > Exemplo (troque pelo do seu projeto): o gate "real" é o que reproduz o ambiente de entrega de fato — num projeto JS/TS pode ser o `build` completo (não só `tsc` ou unit isolado); noutro pode ser o empacotamento, a compilação cruzada, o lint estrito ou o smoke de integração. Defina qual é o **gate que de fato pega regressão** e exija a saída dele.

- O Orquestrador **não escreve teste de fatia** (isso é do Executor, sob a spec do Orquestrador — preserva [[decisions/0002-orquestrador-dono-do-git-executor-escreve]]); o Orquestrador **roda para garantir**.
- Divisão: o Executor roda testes para **achar** falhas; o Orquestrador re-executa para **garantir** que funciona.

## Métricas de qualidade (v1, donas do Orquestrador)
1. Gates verdes **verificados** (não relatados).
2. Cobertura de invariantes críticos com par feliz + bloqueio.
3. Fluxo principal sempre verde.
4. Burn-down dos achados de auditoria.

> Template: este é um conjunto inicial (v1). Adapte/estenda as métricas ao seu domínio — por exemplo, alvos de cobertura por superfície sensível, SLAs de regressão, ou métricas de performance — mantendo o princípio de que **a régua é dona do Orquestrador** e que **mudar a régua exige aprovação da Autoridade**.

Mudar a regra de qualidade exige aprovação da Autoridade.

## Consequências
- Nenhuma fatia é aceita por confiança na palavra do Executor.
- Fatia docs-only/governança não tem gate de código.
