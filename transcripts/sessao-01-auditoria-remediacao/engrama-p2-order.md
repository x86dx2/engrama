Você é o EXECUTOR (Executor Crítico). Tier T4 (o template distribui o gate para TODOS os projetos novos — e hoje distribui a versão BUGADA). Critique antes de executar. cwd = raiz do repo "engrama".

PROBLEMA (EX2 da auditoria): os fixes de segurança do gate foram aplicados só na RAIZ; o `template/` está STALE e distribui o gate vulnerável (sem parsing por campo R2/R5, sem `-z` R3, sem detached-HEAD fail-closed R4, hook sem python3 fail-closed). Além disso o `classify()` da raiz referencia `sync-template.sh`, que NÃO existe.

ORDEM (3 entregas):

A) PROPAGAR OS FIXES PARA O TEMPLATE.
   - `template/.engrama/scripts/critique-gate-hook.sh` deve ficar IDÊNTICO ao da raiz `.engrama/scripts/critique-gate-hook.sh` (esse arquivo não tem placeholders).
   - `template/.engrama/scripts/critique-gate.sh` deve herdar TODA a LÓGICA da raiz (helpers `trim`/`extract_branch_from_header`/`is_ok_verdict`/`is_blocking_objection`; leitura `git diff --cached --name-only -z` em stream; early-exit via `git diff --cached --quiet`; detached-HEAD fail-closed; parsing por campo), MAS preservando as DUAS diferenças intencionais do template:
     (i) as vars no topo são placeholders: `EXECUTOR_CMD="{{EXECUTOR_CMD}}"` e `CRITIQUE_MODEL="{{MODELO_CRITICA}}"` (na raiz são `"codex exec"` / `"gpt-5.5"`);
     (ii) o corpo de `classify()` é o do TEMPLATE: categorias universais (governance/gate/contract) + os exemplos de domínio COMENTADOS (financial/rbac/auth/schema) — herdando as adições UNIVERSAIS novas (`tests/gate/*`→gate, `tests/contract/*`→contract, `.github/*`→gate, `.engrama/gaps|roadmap|domain/*`→governance), mas SEM os paths de auto-governança específicos da raiz (`template/*`, `bootstrap.sh|install.sh|sync-template.sh|engrama.values.example`, `README.md|INSTALL.md|INSTANTIATE.md`).

B) CRIAR `sync-template.sh` (raiz) — o gerador idempotente que sincroniza `template/` a partir da RAIZ canônica, resolvendo a referência fantasma:
   - sincroniza os arquivos de LÓGICA (no mínimo os 2 scripts acima) da raiz→template aplicando: reverse-substituição das vars do gate para placeholders, e mantendo o `classify()` do template (item A.ii). Para os scripts, a forma robusta é: sincronizar a LÓGICA e reaplicar o bloco de config do template (vars placeholder + classify do template) — você decide a mecânica (ex.: manter o classify do template num trecho delimitado e reescrever só o resto).
   - idempotente: rodar 2x não muda nada.
   - imprime o que sincronizou.
   - se sincronizar prosa de governança for frágil (valores que aparecem em texto livre), NÃO faça reverse-sub cega em prosa — limite-se aos scripts e a arquivos seguros, e documente o escopo no cabeçalho do script.

C) CRIAR `tests/contract/sync.test.sh` (teste de drift, no padrão das outras suítes — `set -u`, fail-fast com mktemp/git, função `check`):
   - FALHA se a LÓGICA do gate divergir entre raiz e template (compare tudo EXCETO as 2 vars de topo e o corpo de `classify()` — ex.: extraia as funções helper e o loop de parsing e compare).
   - FALHA se `template/.engrama/scripts/critique-gate-hook.sh` != raiz.
   - FALHA se a referência `sync-template.sh` no `classify()` apontar para arquivo inexistente.
   - PASSA agora (após A/B).

FRONTEIRAS: não toque a prosa de governança (`.engrama/governance/*`, ADRs, README), nem `install.sh`/`bootstrap.sh`, nem a suíte do gate/contract existente (a não ser criar a nova `sync.test.sh`). Mantenha portabilidade BSD/GNU. Não comite.

ACEITE (cole as saídas):
- `grep -c is_ok_verdict template/.engrama/scripts/critique-gate.sh` ≥ 1 e o template tem `-z` e detached-HEAD fail-closed.
- `diff template/.engrama/scripts/critique-gate-hook.sh .engrama/scripts/critique-gate-hook.sh` → vazio (idênticos).
- `template/.engrama/scripts/critique-gate.sh` ainda tem `{{EXECUTOR_CMD}}`/`{{MODELO_CRITICA}}` e o classify com exemplos de domínio comentados.
- `bash sync-template.sh && git diff --stat template/` rodado 2x → 2ª vez sem mudanças (idempotente).
- SMOKE: `bash bootstrap.sh /private/tmp/eg-smoke-$$ && grep -c is_ok_verdict /private/tmp/eg-smoke-$$/.engrama/scripts/critique-gate.sh` ≥ 1 (projeto novo recebe o gate CORRIGIDO) e `grep -c '{{' /private/tmp/eg-smoke-$$/.engrama/scripts/critique-gate.sh` = 0 (placeholders resolvidos).
- `bash tests/run.sh` verde (incl. a nova sync.test.sh); `shellcheck sync-template.sh template/.engrama/scripts/*.sh tests/contract/sync.test.sh` limpo.

RESPONDA nos 6 itens do Executor (leitura · crítica · veredito `concordo|ajuste-menor|discordo` · execução · evidências · pendências). Em português.
