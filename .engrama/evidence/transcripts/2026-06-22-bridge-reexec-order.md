# ORDEM — endurecer exec-bridge.sh contra auto-edição (re-exec de cópia estável)

Você é o **Executor Crítico**. Critique antes de executar; se discordar materialmente, não execute.
Devolva os 6 itens da resposta mínima.

## 1) Objetivo
Tornar `.engrama/scripts/exec-bridge.sh` **imune a ser editado enquanto é o próprio script em execução**.
Causa-raiz (incidente real, log 2026-06-22): o bash relê o script por **offset de byte**; quando a fatia
editou o `exec-bridge.sh` no meio da run, o tail desalinhou e crashou `set -u` (`codex_rc: unbound variable`,
exit 1) — depois de já ter gravado a resposta (cosmético, mas sujo). Fix: o bridge **re-executa a partir de
uma cópia estável** em tempfile, de modo que editar o arquivo no working tree não afeta a execução em curso.

## 2) Estado factual
- Branch `feat/consolidar-root-em-engrama` (PR #14, não mergeado). `exec-bridge.sh` já grava transcripts em
  `.engrama/transcripts/` (consolidação desta branch). Template em paridade (teste S3CA exige
  `template/.engrama/scripts/exec-bridge.sh` idêntico à raiz).
- A suíte tem `tests/contract/exec-bridge.test.sh` que stuba o codex via `ENGRAMA_CODEX_BIN`.
- ESTA invocação está rodando de uma CÓPIA ESTÁVEL do bridge (mitigação manual do Orquestrador), então você
  pode editar `.engrama/scripts/exec-bridge.sh` à vontade sem crashar a run atual.

## 3) Escopo
- **`.engrama/scripts/exec-bridge.sh`:** no TOPO (antes de qualquer trabalho), adicionar um guard de
  re-exec a partir de cópia estável. Esboço (adapte com cuidado, mantendo `set -u` e o resto intacto):
  ```sh
  if [ -z "${ENGRAMA_BRIDGE_REEXEC:-}" ]; then
    __orig_here="$(cd "$(dirname "$0")" && pwd)"
    __copy="$(mktemp 2>/dev/null || mktemp -t exec-bridge)" || { echo "exec-bridge: mktemp falhou" >&2; exit 2; }
    cat "$__orig_here/$(basename "$0")" > "$__copy" || { rm -f "$__copy"; echo "exec-bridge: copia falhou" >&2; exit 2; }
    ENGRAMA_BRIDGE_REEXEC=1 ENGRAMA_BRIDGE_HERE="$__orig_here" bash "$__copy" "$@"
    __rc=$?
    rm -f "$__copy"
    exit "$__rc"
  fi
  ```
  E ajustar a resolução de `HERE` para usar `ENGRAMA_BRIDGE_HERE` quando re-exec'd (senão, como `$0` agora é o
  tempfile, `git -C "$HERE/.." rev-parse` não acha o repo):
  ```sh
  HERE="${ENGRAMA_BRIDGE_HERE:-$(cd "$(dirname "$0")" && pwd)}"
  ```
  TODO o resto do comportamento (REPO_ROOT, transcript em `.engrama/transcripts/`, extração de
  session/model, fallbacks, trap de cleanup do `TMPDIR_BRIDGE`) **permanece idêntico**.
- **Template:** rode `bash ./bin/sync-template.sh` para propagar à `template/.engrama/scripts/exec-bridge.sh`
  (mantém S3CA). Não edite o template à mão se o sync já cobre.
- **Teste (`tests/contract/exec-bridge.test.sh`):** adicione UM caso que prova a imunidade: um stub de codex
  (via `ENGRAMA_CODEX_BIN`) que, durante sua execução, **edita/append no `exec-bridge.sh`** do working tree
  (ou num arquivo-alvo que simule isso), e o teste assere que o bridge **sai 0**, grava o par de transcript e
  captura a resposta — ou seja, que a auto-edição não corrompe mais a run. Determinístico, sem rede.

## 4) Fronteiras (não tocar)
- NÃO altere o caminho do transcript (`.engrama/transcripts/`), nem a extração de session-id/model, nem os
  fallbacks já existentes. Só adicione o guard de re-exec + a resolução de HERE.
- NÃO desfaça nada da consolidação (mover de arquivos, refs, lint prune, markdownlint ignores).
- NÃO rode `git commit`/`git config`/`git push`; o Orquestrador stageia e comita. Se precisar de smoke, use `mktemp`/`git -C`.
- Mantenha shellcheck `-S info` limpo e o script POSIX-bash portátil.
- Garanta cleanup do tempfile da cópia em TODOS os caminhos de saída (incl. erro).

## 5) Critérios de aceite
1. Editar `.engrama/scripts/exec-bridge.sh` durante uma invocação **não crasha mais** o bridge (re-exec da cópia).
2. `HERE`/`REPO_ROOT` continuam resolvendo corretamente sob re-exec.
3. Testes existentes do exec-bridge passam; NOVO caso prova a imunidade.
4. Paridade raiz↔template (S3CA) preservada via sync.
5. Suíte verde; lint exit 0; sync idempotente + `sync.test` verde; `shellcheck -S info` limpo.

## 6) Validações esperadas (rode e cole a saída)
- `bash ./tests/run.sh`
- `bash ./tests/contract/exec-bridge.test.sh`
- `bash ./bin/sync-template.sh && bash ./bin/sync-template.sh` (idempotente)
- `bash ./tests/contract/sync.test.sh`
- `shellcheck -S info .engrama/scripts/exec-bridge.sh`

## 7) Riscos conhecidos
- Re-exec muda `$0` → HERE deve vir de `ENGRAMA_BRIDGE_HERE` (senão REPO_ROOT quebra). 
- Cleanup do tempfile precisa cobrir erro/sinal.
- Não reintroduzir o bug de path do transcript.

## 8) Depende da Autoridade
Apenas o merge do PR #14 (que passa a incluir este fix).

## 9) Próximo passo após execução
Orquestrador: auditoria (re-roda gates + reproduz o cenário de auto-edição provando exit 0), squash do fix
dentro do commit do PR #14 (`reset --soft main`), re-bind do ledger sobre o diff combinado, log, force-push, CI.

## 10) Modelo/tier
`codex exec` default, sandbox `workspace-write`. Effort médio: mudança localizada + 1 teste; precisa de cuidado
com a semântica de re-exec e cleanup, não amplitude.
