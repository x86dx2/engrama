# Log — Memória factual append-only

Mais recente no topo. Cabeçalho: `## [YYYY-MM-DD] {tipo} | título`. Logar **antes** de cada commit não-trivial. O item mais recente no topo **é** o checkpoint vivo (estado de retomada) — ver [[governance/continuidade-de-sessao]].

Tipos comuns: `decision` · `ingest` · `update` · `slice` · `fix` · `chore` · `audit` · `phase`.
Permite `grep "^## \[" log.md | tail -N` para varrer o histórico.

> **Template:** apague o exemplo abaixo e registre a primeira entrada real (tipicamente o bootstrap da governança: engrama inicial + crítica do Executor + aprovação da Autoridade — ver [[decisions/0006-governanca-nao-se-autoaprova]]).

---

## [{{DATA}}] decision | Bootstrap da governança de 3 papéis (Orquestrador/Executor/Autoridade)
- Modelo portado do template de governança (LLM-Wiki). ADRs 0001–0010 ativos.
- Toca: [[governance/index]] · [[governance/papeis-e-alcadas]] · [[decisions/0001-governanca-tres-papeis]].
- Crítica do Executor: <veredito> · Aprovação da Autoridade: <quem/quando>.
- **PRÓXIMO PASSO SEGURO:** <preencha — a primeira fatia verificável do projeto>.
