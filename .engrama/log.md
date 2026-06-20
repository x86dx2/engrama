# Log — Memória factual append-only

Mais recente no topo. Cabeçalho: `## [YYYY-MM-DD] {tipo} | título`. Logar **antes** de cada commit não-trivial. O item mais recente no topo **é** o checkpoint vivo (estado de retomada) — ver [[governance/continuidade-de-sessao]].

Tipos comuns: `decision` · `ingest` · `update` · `slice` · `fix` · `chore` · `audit` · `phase`.
Permite `grep "^## \[" log.md | tail -N` para varrer o histórico.

---

## [2026-06-20] fix | P0.1 — instalador: substituição literal segura + fail-closed (executor-bridge)
- Branch `fix/p0-instalador-substituicao-segura`. Executor (`codex exec`) corrigiu `install.sh`; Orquestrador auditou.
- **Bug fechado (era CRÍTICO):** valor com `#` quebrava o `sed -f` global (instalação 100% crua com exit 0); `&` corrompia. Agora: escape literal (`\`,`&`,`#`) + `find -print0`/`read -d ''` + **fail-closed** (aborta exit 1 se sobrar placeholder).
- **Provado:** `tests/contract` 9/9 verde (C5/C6/C7 promovidos a CORRETO; +C9 adversário); shellcheck limpo; teste manual com todos os especiais juntos + values incompleto.
- Crítica/execução do Executor registrada em [[qa/criticas-do-executor]]. Furos restantes (R1–R5, do gate) seguem para P1/P2.
- **PRÓXIMO PASSO SEGURO:** decisão da Autoridade sobre o commit desta branch; depois P0.2 (CI) + P0.3 (cabear `tests/`+`gaps/` no classify) e P1 (endurecer o gate).

## [2026-06-20] audit | Auditoria imparcial + plano de remediação + suítes de teste (dogfood do gate)
- Auditoria de 3 fontes (leitura, workflow 47 agentes, `codex`) **validada por testes**: `tests/gate/` (12 asserts, G1–G7+R1–R5) e `tests/contract/` (8 asserts, C1–C8) + `tests/run.sh`. shellcheck-limpas, fail-fast.
- **Provado correto:** G1–G7, C1–C4, C8 (inclui leitura staged do ledger e bootstrap.sh end-to-end).
- **Furos comprovados (8):** R1 auto-aprovação · R2 substring · R3 non-ASCII fail-open · R4 detached HEAD · R5 bypass cross-branch · C5 `&` corrompe · C6/C7 `#` quebra global + exit 0.
- **Executor-bridge real:** `codex exec` criticou o plano (veredito `discordo`, 13 pontos) → ajustes **incorporados**; registrado em [[qa/criticas-do-executor]]. Plano em [[gaps/auditoria-e-plano-de-remediacao]].
- **Gate ao vivo:** liberou o commit montado na linha `dispensada` do bootstrap (furo R1/EX5 demonstrado no repo real).
- **PRÓXIMO PASSO SEGURO:** decisão da Autoridade sobre o commit (governança não se autoaprova; Executor `discordo` incorporado, sem dispensa registrada). Depois: P0 do plano (corrigir instalador `#`/`&`, CI, cabear `tests/`+`gaps/` no classify, alinhar claims).

## [2026-06-20] decision | Engrama ativado como instância viva e template central
- Instalada governança ativa na raiz: `CLAUDE.md`, `AGENTS.md`, `.engrama/` e `.claude/settings.json`.
- `template/` permanece como artefato distribuível para novos projetos, sem estado local deste repositório e sem conteúdo específico do Ruflos.
- Bootstrap do projeto central concluído em [[project/bootstrap-do-projeto]]; Ruflos foi usado como base operacional, não como conteúdo de domínio.
- Gate central mapeado para `[governance]`, `[gate]` e `[contract]`; superfícies como `financial`, `rbac`, `auth` e `schema` ficam para projetos-alvo.
- Crítica do Executor: dispensada pela Autoridade somente para este bootstrap inicial; próximas mudanças sensíveis exigem crítica independente ou waiver explícito.
- **PRÓXIMO PASSO SEGURO:** validar `shellcheck bootstrap.sh install.sh`, executar smoke de bootstrap limpo e commitar a ativação central.
