Você é o EXECUTOR (Executor Crítico). Tier T3. Critique antes de executar. cwd = raiz do repo "engrama", branch `feat/versionamento-vendor`. Fecha as últimas pendências (itens 7 e 8). Não comite.

=== PARTE A — VERSIONAMENTO (item 8) ===
Hoje o pack não tem versão; um adotante não sabe que versão instalou; o CHANGELOG é eterno "[Não lançado]".
A1) Criar `VERSION` na RAIZ = `0.1.0` (uma linha). É a fonte de verdade da versão do pack.
A2) `bin/bootstrap.sh`: ler a versão do `$HERE/../VERSION` (o repo-fonte do pack) e semear `ENGRAMA_VERSION` no values (junto dos outros defaults), com fallback `0.0.0` se o arquivo faltar.
A3) `template/.engrama/VERSION` = `{{ENGRAMA_VERSION}}` (o instalador substitui pela versão do pack que gerou a instalação). Assim o projeto-alvo registra a versão instalada num arquivo simples.
A4) `bin/install.sh`: garantir que `{{ENGRAMA_VERSION}}` é substituído (a substituição de placeholders já roda em `.engrama/**`; confirme que pega `.engrama/VERSION`). Adicione `VERSION` ao relatório se fizer sentido.
A5) `classify()` do gate: `VERSION` (raiz) e `template/.engrama/VERSION` → `gate` (são parte do mecânico de distribuição). Rode `sync-template.sh` se mexer no gate.
A6) `CHANGELOG.md`: transformar a seção `## [Não lançado]` na **release `## [0.1.0] - 2026-06-21`** (mantendo o conteúdo acumulado), e abrir uma nova `## [Não lançado]` vazia no topo. (A tag git v0.1.0 será criada pelo Orquestrador APÓS o merge — não tente criar tag.)
A7) Teste: `tests/contract/` — um caso provando que após `bin/bootstrap.sh`, o projeto-alvo tem `.engrama/VERSION` == a versão do pack (`0.1.0`), sem `{{` cru.

=== PARTE B — VENDOR/MODEL-NAMES HONESTOS (item 7) ===
Os ids de modelo `gpt-5.5/5.4/5.4-mini` estão hardcoded como PADRÃO mas NUNCA foram verificados contra o namespace real do `codex exec`. E o lema é "papéis por função, NÃO por vendor", mas `codex exec`/modelos/`.claude/` são vendor-específicos.
B1) Em `bin/bootstrap.sh`, `engrama.values.example`, `docs/INSTALL.md`, `docs/INSTANTIATE.md`: relabelar os ids de modelo de "PADRÃO" para **"EXEMPLO — confirme o id real contra o seu `codex exec`"** (NÃO afirmar que são verificados). Pode manter `gpt-5.x` como valor-exemplo, mas com a ressalva clara. NÃO mude para quebrar a instalação; só torne honesto.
B2) Adicionar à governança UMA nota curta (em `.engrama/governance/papeis-e-alcadas.md` ou `cadeia-de-comando.md`, onde já se fala do mapeamento/executor-bridge): explicitar a **"camada de adaptadores de vendor"** — `EXECUTOR_CMD` (`codex exec`), os ids de modelo e o `.claude/settings.json` são o **adaptador concreto, trocável**; o núcleo (papéis/alçadas/gate) é vendor-agnóstico. Isso honra "por função, não por vendor" e documenta onde o vendor está isolado. Propague ao template se a doc for sincronizada à mão (é prosa — ajuste root e template).
B3) `.engrama/CLAUDE.md` "Stack do projeto" e afins: se citarem modelos como verificados, alinhar à ressalva.

FRONTEIRAS: não mude a lógica do gate (só classify + a substituição de VERSION); não quebre a instalação (defaults seguem funcionando, só honestos); portabilidade BSD/GNU. NÃO crie tag git. Não comite.

ACEITE (cole as saídas):
- `cat VERSION` = `0.1.0`; `bash tests/run.sh` VERDE (incl. o teste de VERSION); `shellcheck` limpo; `lint.sh` exit 0; `sync.test.sh` verde.
- SMOKE: `bash bin/bootstrap.sh /private/tmp/eg-ver-$$` → `cat $alvo/.engrama/VERSION` = `0.1.0` (sem `{{`); `grep -rn '{{' $alvo/.engrama` = vazio.
- `grep -rn 'PADRÃO.*gpt-5\|PADRÃO.*MODELO' bin/ engrama.values.example docs/` → as ocorrências agora dizem "EXEMPLO/confirme", não "PADRÃO verificado".
- CHANGELOG com `## [0.1.0] - 2026-06-21` + `## [Não lançado]` vazia.

RESPONDA nos 6 itens do Executor. Em português.
