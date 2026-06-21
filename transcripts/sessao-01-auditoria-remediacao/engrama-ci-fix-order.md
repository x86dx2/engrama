Você é o EXECUTOR (Executor Crítico). Tier T3. Critique antes de executar. cwd = raiz do repo "engrama", branch `fix/ci-portabilidade`.

CONTEXTO: o CI no GitHub FALHOU em 2 pontos (gitleaks passou). Conserte ambos. Isto é uma LIÇÃO do loop falha→regra (ver `.engrama/specs/licao-aprendida.md`): o furo EX4 (source_refs absolutos) quebrou o lint em CI.

FALHA 1 — `lint.sh` retorna exit 1 em CI (ubuntu+macos), mas passa localmente.
CAUSA: a checagem de `source_refs:` valida caminhos ABSOLUTOS (ex.: `/Users/x86/git-projects/engrama/.engrama/scripts/critique-gate.sh`) que existem nesta máquina mas NÃO no runner (`/home/runner/work/engrama/engrama/...`).
FIX: tornar a checagem de `source_refs` PORTÁVEL — resolver cada `source_ref` RELATIVO à raiz do repo. Para um source_ref absoluto, mapeie-o para um caminho repo-relativo e verifique a existência sob `REPO_ROOT` (ex.: ache o maior sufixo do caminho que exista como arquivo sob a raiz do repo — `.engrama/scripts/critique-gate.sh` etc.; ou despe o prefixo até a raiz conhecida). Um source_ref que aponta para um arquivo REAL do repo deve passar INDEPENDENTE de onde o repo está clonado. source_ref que aponta para arquivo inexistente (mesmo após resolução) continua sendo erro.
PROVA OBRIGATÓRIA (simula o CI): clone o repo para um caminho DIFERENTE (`d=$(mktemp -d); git clone -q . "$d/clone"`) e rode `bash "$d/clone/lint.sh"` lá — deve dar exit 0. Isso prova a portabilidade. Adicione um caso a `tests/contract/lint.test.sh` que faça exatamente isso (clone p/ outro path + lint exit 0).
Propague `lint.sh` ao template via `sync-template.sh` (mantenha `sync.test.sh` verde).

FALHA 2 — markdownlint: "Unable to use configuration file '.github/markdownlint-cli2.yaml'; File name should be (or end with) one of the supported types".
FIX: renomeie o config para um nome reconhecido pelo markdownlint-cli2 — o mais limpo é `.markdownlint-cli2.yaml` na RAIZ do repo (auto-descoberto). Ajuste `.github/workflows/ci.yml` (remova o input `config:` se usar o auto-descoberto na raiz, ou aponte para o novo caminho). O config deve ser TOLERANTE para PASSAR nos .md atuais: desabilite regras ruidosas que nao agregam aqui (ex.: MD013 line-length, MD033 inline-HTML, MD041 first-line-heading, MD024 duplicate-headings se necessário, MD036, MD040). O objetivo é markdownlint VERDE nos docs do repo (incl. README com tabelas/HTML e template/ com {{placeholders}}), não falhar por estilo. Se algum .md tiver problema estrutural real (não-estilo), conserte o .md.
PROVA: se tiver `npx`/markdownlint-cli2 disponível localmente, rode e cole a saída (verde); senão, valide o YAML do config e liste as regras desabilitadas + por quê.

FRONTEIRAS: não toque a lógica do gate, install/bootstrap, nem a prosa normativa (exceto consertar um .md com problema estrutural real). Portabilidade BSD/GNU. Não comite.

ACEITE (cole as saídas):
- clone-para-outro-path + `bash lint.sh` lá → exit 0 (portabilidade provada);
- `bash tests/run.sh` verde (incl. o novo caso de lint portátil); `shellcheck lint.sh` limpo; `sync.test.sh` verde;
- markdownlint config com nome válido + tolerante (verde nos docs, ou a lista de regras off + validação do YAML);
- `bash lint.sh` no repo real ainda exit 0.

RESPONDA nos 6 itens do Executor. Em português.
