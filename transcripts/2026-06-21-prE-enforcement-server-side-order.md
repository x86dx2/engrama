# Ordem ao Executor — PR-E (P2): enforcement server-side PORTÁTIL no template

Branch já criada: `feat/p2-enforcement-server-side`. Sandbox: workspace-write. **NÃO comitar.** Critique antes; escale se discordar.

## ⚠️ ISOLAMENTO OBRIGATÓRIO (incidente real nesta sessão)
Um smoke anterior rodou `git config` e `git commit` no REPO REAL e contaminou a identidade + criou commit-lixo no `main`. NUNCA rode `git config`, `git add`, `git commit`, `git checkout` ou qualquer mutação git no repo de trabalho. **Todo smoke/teste que precise de git roda em `T=$(mktemp -d)` com `git -C "$T" ...` e identidade setada SÓ no temp (`git -C "$T" config ...`).** Não toque na config git do repo real. Ao terminar, deixe a árvore como achou (fora os arquivos da fatia).

## Contexto
A auditoria de prontidão (P2) achou: um projeto recém-bootstrapado nasce só com o freio LOCAL (burlável via `--no-verify`/`push -f`), sem o enforcement server-side vinculante que o README/ADR 0006 prometem — porque o `template/` não traz CI nem o gate-CI, e os docs não instruem a configurar. Esta fatia leva o enforcement server-side pro template, PORTÁTIL.

O `bin/critique-gate-ci.sh` (raiz) é portátil: depende só de `.engrama/scripts/*` (que o template já tem). O `ci.yml` da RAIZ roda a suíte do FRAMEWORK (`tests/run.sh`) — isso NÃO existe num projeto adotante; então o ci.yml do template é uma versão ENXUTA, não cópia.

## Item A — `template/bin/critique-gate-ci.sh`
Copie `bin/critique-gate-ci.sh` da raiz para `template/bin/critique-gate-ci.sh` (idêntico — ele já é portátil). Esse é o único script de `bin/` que vai no template (install/bootstrap/sync são tooling do repo-fonte e NÃO entram).

## Item B — `template/.github/workflows/ci.yml` (ENXUTO, portátil)
Crie um ci.yml para o projeto adotante com 3 jobs, SEM referência a `tests/run.sh` nem a `bin/*.sh` de tooling:
1. **`gate`** (ubuntu-latest, `fetch-depth: 0`): instalar shellcheck; `shellcheck .engrama/scripts/*.sh .engrama/githooks/pre-commit bin/critique-gate-ci.sh`; `bash ./.engrama/scripts/lint.sh`; em `pull_request`: fetch da base + reexecutar o gate contra o diff do PR com `ENGRAMA_REQUIRE_DIFF_BIND: "1"` chamando `bash ./bin/critique-gate-ci.sh --branch <head_ref> --base-ref origin/<base_ref> --files-from <lista-nul>` (espelhe EXATAMENTE o passo "Re-run critique gate against pull request diff" do ci.yml raiz); inclua o `::notice::` não-bloqueante de multi-commit.
2. **`gitleaks`** (ubuntu): espelhe o job do ci.yml raiz — binário FIXADO `v8.30.1` + verificação de checksum + scan sem `GITHUB_TOKEN`. Idêntico ao da raiz.
3. **`markdown`** (ubuntu): `DavidAnson/markdownlint-cli2-action@v18` com `globs: **/*.md` (espelhe a raiz).
Comente no topo do arquivo que este é o CI do PROJETO ADOTANTE (enxuto) e que o branch protection é passo manual (ver INSTALL/INSTANTIATE).

## Item C — `template/.markdownlint-cli2.yaml`
Copie `.markdownlint-cli2.yaml` da raiz para o template (o job markdown precisa). Ajuste só o necessário (o ignore de `transcripts/` faz sentido manter).

## Item D — sync + testes de contrato
- Em `bin/sync-template.sh`: passe a sincronizar `template/bin/critique-gate-ci.sh` a partir da raiz (idêntico, como os outros scripts) e `template/.markdownlint-cli2.yaml`.
- Em `tests/contract/sync.test.sh`: novos asserts — (1) `template/bin/critique-gate-ci.sh` idêntico ao da raiz; (2) `template/.github/workflows/ci.yml` EXISTE, é YAML válido (se houver parser; senão cheque sintaticamente que tem os 3 jobs) e referencia `bin/critique-gate-ci.sh`; (3) o pin do gitleaks (`v8.30.1`) bate entre o ci.yml do template e o da raiz (pra não driftar). O ci.yml do template NÃO é idêntico ao da raiz (por design) — não asserte identidade dele.

## Item E — docs do passo server-side
- `docs/INSTALL.md` e `docs/INSTANTIATE.md`: adicione um passo "Ativar enforcement server-side" — o template JÁ traz `.github/workflows/ci.yml` + `bin/critique-gate-ci.sh`; o adotante precisa (1) dar push no GitHub, (2) configurar **branch protection** tornando o job `gate` um required check, exigindo PR e bloqueando force-push na branch default. Dê os comandos concretos via `gh api` (espelhe o que está documentado na história deste repo, se houver; senão um exemplo `gh api -X PUT repos/<owner>/<repo>/branches/<default>/protection ...` com required_status_checks contemplando o check `gate`, enforce_admins, required_pull_request_reviews). Deixe honesto: sem isso, o projeto novo fica só com o freio local burlável.
- `README.md`: qualifique "auto-contido" → o template entrega o freio local + o CI de enforcement, mas o **branch protection é um passo manual** no GitHub do adotante.
- ADR 0006 (`.engrama/decisions/0006-*.md`): nota curta de que o modo estrito do diff-binding é OFF por padrão LOCALMENTE; o freio vinculante é server-side (CI required check). Não reescreva a decisão; só acrescente a ressalva honesta.

## Saída esperada
Liste os arquivos tocados. Rode: `bash tests/run.sh`, `bash .engrama/scripts/lint.sh`, `shellcheck` (incl. `template/bin/critique-gate-ci.sh`), `bash tests/contract/sync.test.sh`, e valide o YAML do `template/.github/workflows/ci.yml` (parser se houver; senão diga que validou sintaticamente). Lembre que o ci.yml do template só roda de fato num projeto adotante — diga o que não foi exercível localmente.
