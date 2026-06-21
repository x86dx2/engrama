Você é o EXECUTOR (Executor Crítico). Tier T4 (coração do enforcement). Critique antes de executar. cwd = raiz do repo "engrama", branch `fix/diffbind-fingerprint`.

PROBLEMA (item 4 das pendências): o diff-binding (T3) tem o fingerprint INCONSISTENTE entre o gate LOCAL e o gate-CI. O gate local computa `engrama-diff-hash.sh` sobre `git diff --cached --raw` (diff real staged). O `critique-gate-ci.sh` reconstrói um REPO SINTÉTICO e computa o hash lá — produzindo blob-shas diferentes do diff real. Por isso o modo estrito (`ENGRAMA_REQUIRE_DIFF_BIND=1`) foi DESLIGADO no CI (ver ADR 0011 "Limitação conhecida", e a nota no ci.yml). OBJETIVO: unificar o cálculo para que LOCAL == CI, e RE-LIGAR o estrito.

INSIGHT-CHAVE (confirme): para um PR de UM commit (squash), `git diff --cached --raw` (staged vs main, no momento do commit) == `git diff --raw <base>...HEAD` (depois do commit) — mesmo conteúdo, mesmo --raw, mesmo hash. A divergência vem SÓ da reconstrução sintética do gate-CI, não do `git diff`. Logo: o gate-CI deve computar o fingerprint sobre o **diff REAL do PR**, não sobre o repo sintético.

ORDEM:
A) `.engrama/scripts/engrama-diff-hash.sh`: adicionar modo `--range <gitrange>` que computa o fingerprint sobre `git diff --raw -z <gitrange> -- . ':(exclude).engrama/qa/criticas-do-executor.md'` (MESMA exclusão do ledger, MESMO sha256, MESMO formato de saída `sha256:<hex>`). O default (sem flag) segue `git diff --cached --raw -z` (inalterado). Uma única fonte de hashing.
B) `bin/critique-gate-ci.sh`: computar o fingerprint do PR via `engrama-diff-hash.sh --range "<base-ref>...HEAD"` (o diff REAL) e fazer o GATE usar ESSE valor — não o do repo sintético. Mecanismo sugerido: exportar `ENGRAMA_DIFF_HASH=<valor>` antes de invocar o gate; o gate, se essa env estiver setada, USA-A como "fingerprint atual" (override) em vez de recomputar do `git diff --cached`. (O repo sintético segue sendo usado para rodar `classify()` + a checagem do ledger por campo — só o FINGERPRINT passa a vir do diff real.)
C) `.engrama/scripts/critique-gate.sh`: no ponto onde computa `CURRENT_DIFF_HASH` (hoje `bash engrama-diff-hash.sh`), respeitar `ENGRAMA_DIFF_HASH` se setada e válida (`^sha256:[0-9a-f]{64}$`), senão computar como hoje. Não muda mais nada da lógica (parsing por campo, legado, estrito).
D) TESTES (novos/atualizados, padrão das suítes): prove que
   (i) `engrama-diff-hash.sh --cached` (staged vs main, num repo sintetico de teste com 1 commit) == `engrama-diff-hash.sh --range main...HEAD` para o MESMO conteúdo (a igualdade que conserta o bug);
   (ii) o gate com `ENGRAMA_DIFF_HASH` override usa o valor passado (não recomputa);
   (iii) modo estrito: entrada com `sha256` que BATE o override -> LIBERA; que NÃO bate -> BLOQUEIA; sem hash em estrito -> BLOQUEIA.
   Mantenha TODAS as suítes existentes verdes (diffbind/gate/fuzz/contract/sync/ci/lint/session).
E) `.github/workflows/ci.yml`: RE-LIGAR `ENGRAMA_REQUIRE_DIFF_BIND: "1"` no step "Re-run critique gate against pull request diff" e ajustar o step para computar `ENGRAMA_DIFF_HASH` via `--range "origin/${{ github.base_ref }}...HEAD"` antes de chamar o `bin/critique-gate-ci.sh` (ou fazer o proprio wrapper computar). Remover a nota "estrito desligado".
F) DOC: atualizar ADR 0011 (raiz + template) — trocar a "Limitação conhecida" por "Corrigido (2026-06-21): fingerprint unificado via --range; estrito religado". Documentar honestamente a borda: para PR de MÚLTIPLOS commits, o binding cobre o diff CUMULATIVO (`base...HEAD`); o fluxo recomendado é squash/1-commit. Atualizar a doc do ledger (`.engrama/qa/criticas-do-executor.md` cabeçalho) se necessário. Rodar `sync-template.sh` se mexer no gate/helper.

FRONTEIRAS: não mude a semântica do parsing por campo nem o legado; portabilidade BSD(shasum)/GNU(sha256sum). Não comite.

ACEITE (cole as saídas): prova (i) (igualdade --cached == --range); `bash tests/run.sh` verde com os novos casos; `shellcheck` limpo; `sync.test.sh` verde; e uma PROVA de ponta-a-ponta: simule um PR (repo temp com base + 1 commit), compute `--range base...HEAD`, ponha o `sha256` no ledger, rode o gate-CI com `ENGRAMA_REQUIRE_DIFF_BIND=1` -> LIBERA; mude um arquivo -> BLOQUEIA.

RESPONDA nos 6 itens do Executor. Em português.
