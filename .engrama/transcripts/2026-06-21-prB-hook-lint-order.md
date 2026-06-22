Você é o EXECUTOR (Executor Crítico). Tier T3. Critique antes de executar. cwd = raiz do repo "engrama", branch `feat/hook-test-lint-completo`. Não comite. Fecha os itens 2 e 4 das melhorias.

=== PARTE A — TESTE DO HOOK (item 2) ===
O wrapper PreToolUse `.engrama/scripts/critique-gate-hook.sh` (que intercepta `git commit`, inclusive `--no-verify`, e delega ao gate) NÃO tem teste. EX6 ficou "previsto", nunca feito.
A1) Criar `tests/gate/hook.test.sh` (padrão das suítes: `set -u`, fail-fast com mktemp/git, função `check`, repo temp). Testa o `critique-gate-hook.sh` alimentando o stdin com o JSON do PreToolUse (`{"tool_input":{"command":"..."}}`) e checando o exit/comportamento:
   - (i) comando `git commit -m x` detectado → delega ao gate (e o gate, sem ledger, BLOQUEIA exit 2);
   - (ii) comando `git commit --no-verify` → também detectado e delegado (o ponto do wrapper);
   - (iii) comando não-commit (`git status`/`ls`) → exit 0 (ignora);
   - (iv) `python3` ausente E payload parece commit → FAIL-CLOSED (não exit 0 silencioso): simule removendo python3 do PATH (PATH restrito) e verifique que delega/bloqueia, não libera;
   - (v) JSON malformado mas payload bruto parece commit → fail-closed.
   Monte o repo temp como nas outras suítes (copie o gate + hook). NÃO chame codex/rede.
A2) `classify()`: `tests/gate/*` já é `gate` — sem mudança. Rode `sync-template.sh` só se mexer no gate (não deve).

=== PARTE B — LINT MAIS COMPLETO (item 4) ===
Hoje `.engrama/scripts/lint.sh` cobre wikilinks órfãos, source_refs quebrados, frontmatter, ADR superseded. Estender com (concretos e testáveis):
B1) **Páginas órfãs:** um `.engrama/{decisions,governance,specs,gaps,project}/*.md` que NÃO é referenciado por nenhum `[[wikilink]]` em nenhum outro .md NEM listado no `.engrama/index.md`/`.engrama/governance/index.md` → reportar como órfão. (Isente os índices, log.md, CLAUDE.md.)
B2) **Gaps de numeração de ADR:** `.engrama/decisions/NNNN-*.md` deve formar sequência contígua 0001..N; reportar números faltando.
B3) **Status de frontmatter inválido:** `status:` deve ∈ {active, proposed, superseded, resolved}; reportar valor fora disso.
B4) **TODO/FIXME/XXX em doc normativo:** ocorrência de `TODO`/`FIXME`/`XXX` em `.engrama/{governance,decisions}/*.md` → reportar (conteúdo normativo não deveria ter pendência crua). (NÃO falhe por TODO em `project/bootstrap-do-projeto.md` — lá é esperado no template.)
   - Mantenha o lint VERDE no repo real (se alguma dessas checagens pegar algo real, ou conserte o trivial, ou liste nas pendências p/ o Orquestrador triar). `--report` (só reporta) e default estrito seguem.
B5) `tests/contract/lint.test.sh`: adicionar casos provando cada checagem nova (fixture com órfã / gap de ADR / status inválido / TODO normativo → lint pega; fixture limpo → passa). Propague `lint.sh` ao template via `sync-template.sh` (mantém `sync.test.sh` verde).

FRONTEIRAS: não mude a lógica do gate; portabilidade BSD/GNU; sem `date`/`$RANDOM` em testes. Não comite.

ACEITE (cole as saídas): `bash tests/gate/hook.test.sh` verde; `bash .engrama/scripts/lint.sh` exit 0 no repo real (ou pendências listadas); `bash tests/run.sh` VERDE; `shellcheck` limpo; `sync.test.sh` verde; e prova de SENSIBILIDADE de cada checagem nova do lint (injeta o problema → lint exit 1; remove → exit 0).

RESPONDA nos 6 itens do Executor. Em português.
