# Ordem ao Executor — PR-C: quickstart + diff-binding multi-commit + gitleaks sem Node

Branch já criada: `feat/quickstart-diffbind-gitleaks`. Sandbox: workspace-write. **NÃO comitar** (o Orquestrador é dono do git). Critique a ordem antes; se discordar materialmente, escale.

Três itens, todos pendências triviais/cosméticas já levantadas. Mantenha o estilo denso da casa.

## Item 5 — Quickstart no README (raiz)
Adicione uma seção curta **`## Quickstart (TL;DR)`** logo após o bloco de bullets do topo (antes do primeiro `---`), com no máximo ~8 linhas: um fenced block mostrando o caminho de adoção em 1 minuto — copiar `template/` para a raiz do projeto novo, rodar as validações locais, e o ponteiro para `docs/INSTALL.md`/`docs/INSTANTIATE.md` para o passo a passo. Não duplicar o conteúdo desses docs; só o atalho. Honesto: é um template, então o "quickstart" é de *adoção*, não de "rodar um app".

## Item 6 — diff-binding multi-commit: tornar o caveat ACIONÁVEL (não só documentado)
O README já documenta o caveat (binding cobre o diff cumulativo `base...HEAD`; squash recomendado). Falta torná-lo acionável:
1. Em `.github/workflows/ci.yml`, no job `test`, adicione um passo **não-bloqueante** (após o gate-contra-PR) que, **só em pull_request com mais de 1 commit**, emita um `::notice::` lembrando que o diff-binding cobre o diff cumulativo e que squash/1-commit é o fluxo recomendado. Nunca deve falhar o job (use `if: always()` ou guard por evento; conte commits via `git rev-list --count <base>..HEAD` reusando o base já buscado no passo "Fetch pull request base"). Não toque na lógica do gate em si.
2. Em `CONTRIBUTING.md`, adicione um item ao fluxo deixando explícito: **squash/1 commit por PR é o recomendado** porque o diff-binding ata o `sha256` do diff cumulativo do PR; PRs multi-commit continuam válidos, mas o fingerprint cobre o conjunto, não cada commit.

## Item 7 — gitleaks sem Node action (mata o warning de deprecação do Node 20)
Em `.github/workflows/ci.yml`, job `gitleaks`: troque o passo que usa `gitleaks/gitleaks-action@v2` por uma invocação **direta do binário** gitleaks (sem action Node, sem depender de `GITHUB_TOKEN`):
- baixe um release **fixado por versão** do gitleaks (asset linux x64, ex.: `gitleaks_<ver>_linux_x64.tar.gz` do release `v<ver>` — escolha uma versão estável recente e confirme o nome real do asset), com `set -euo pipefail` e `curl -sSfL`;
- rode o scan no repo já com `fetch-depth: 0` (use o subcomando correto da versão escolhida — em gitleaks v8 recente é `gitleaks git . --redact --no-banner -v`, exit≠0 em achado);
- remova o bloco `env: GITHUB_TOKEN` desse job (não é mais necessário).
Objetivo: o job continua **falhando se houver secret**, mas sem o warning de Node e sem o token.

## Saída esperada
Liste os arquivos tocados, e rode localmente o que der pra rodar (`bash tests/run.sh`, `bash .engrama/scripts/lint.sh`, e valide o YAML do ci.yml com `python3 -c 'import yaml,sys; yaml.safe_load(open(".github/workflows/ci.yml"))'` se houver pyyaml — senão diga que não validou). A parte de download do gitleaks só roda na CI; deixe claro que não pôde ser exercida localmente.
