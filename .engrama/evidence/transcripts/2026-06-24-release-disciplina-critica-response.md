---
codex-session: 019ef9f9-d9f6-72e0-b005-b4576e8475eb
codex-session-source: stream
model: unknown
sandbox: read-only
label: release-disciplina-critica
---

Vou fazer a leitura obrigatória de governança antes de criticar o plano. Primeiro vou validar papel, alçada e o estado factual do repositório a partir de `.engrama/` e do topo do log.
Estou confirmando a governança canônica antes de entrar no mérito do gate de release. Na sequência vou extrair o mapeamento concreto de papel/alçada e checar se o bootstrap permite discutir produto sem interrupção.
O bootstrap está `active`, então a análise pode seguir. Agora vou ler o checkpoint factual no topo do `log.md` e, em paralelo, inspecionar os arquivos citados no plano para criticar a definição de “superfície distribuível” e o desenho do gate.
Com a governança lida, a parte útil agora é confrontar o plano com o estado mecânico real do repo: release artifacts, gate atual, template e CI. Vou inspecionar esses pontos para procurar drift, falso-positivo e buracos de bootstrap.
O estado atual já mostra dois sinais importantes: `VERSION` ainda está em `0.1.0` e o `CHANGELOG` de `0.1.0` já contém paths anacrônicos de uma reorg posterior. Agora vou mapear onde `VERSION`/template/instalador entram para testar se o desenho do gate pode quebrar bootstrap ou gerar falsos-positivos.
Estou fechando a parte de evidência: versões, template e bootstrap já mostram onde um gate mal desenhado pode se chocar com o artefato distribuído. Falta agora olhar a classificação atual do gate, a suíte de testes e os ADRs existentes para dizer se o design proposto encaixa sem drift.
A principal aresta nova apareceu: o template hoje não distribui `VERSION`/`CHANGELOG` do projeto-alvo, só `.engrama/VERSION` do pack instalado. Então “espelhar no template” do jeito proposto mistura duas semânticas diferentes de versão e é um buraco de design, não só de implementação. Vou fechar isso com mais um passe curto na suíte e no contrato do template.
Já tenho material suficiente para a crítica de design. Vou fazer um último corte factual: o que realmente mudou desde `v0.1.0`, para comparar sua noção de “superfície distribuível” com a prática do repo e identificar o que está faltando ou sobrando.
Vou referenciar os pontos críticos com evidência de arquivo. Só falta numerar alguns trechos relevantes para ancorar a devolutiva final sem especulação.
**Handshake**

Papel: **Executor Crítico**. Alçada: **análise read-only**; não executo, não edito, não movo nada. Estado factual: o topo do log registra a reorg de `.engrama/` em **2026-06-22** como checkpoint vivo, já com a lição de “crítica separada da ação” e com o template espelhado ([.engrama/log.md](/Users/x86/git-projects/engrama/.engrama/log.md:10)); ao mesmo tempo, o repo ainda está em `VERSION` **0.1.0** e o `CHANGELOG` segue só com `0.1.0` ([CHANGELOG.md](/Users/x86/git-projects/engrama/CHANGELOG.md:7)). Próximo passo seguro: **corrigir o design do gate antes da FASE 2**. Depende de aprovação da Autoridade: **escopo do gate (repo central vs template/adotantes), formato do escape, política de data do release e fatiamento**.

**Leitura da ordem**

Entendi a meta: fechar o sintoma com `0.2.0`, mas principalmente impedir reincidência com um gate mecânico que acople mudança no pack distribuível a `VERSION` + `CHANGELOG`, com escape consciente e CI vinculante.

**Crítica Técnica**

1. **O plano conflita pack-release com project-release do adotante.** Hoje o bootstrap lê a versão do **pack** na raiz ([bin/bootstrap.sh](/Users/x86/git-projects/engrama/bin/bootstrap.sh:85)) e instala isso em `template/.engrama/VERSION` / `.engrama/VERSION` do alvo, não em um `VERSION` raiz do projeto adotante ([bin/install.sh](/Users/x86/git-projects/engrama/bin/install.sh:120), [template/.engrama/VERSION](/Users/x86/git-projects/engrama/template/.engrama/VERSION:1)). Espelhar esse gate no template, como proposto, impõe uma semântica de release que o template **não tem hoje**; do jeito escrito, isso é materialmente inseguro.

2. **`sem-release` como linha livre no `## [Não lançado]` é um bypass persistente e largo demais.** O próprio ADR do diff-binding existe porque um “ok” não pode liberar qualquer diff futuro da mesma branch ([0011-diff-binding-atestacao-verificavel.md](/Users/x86/git-projects/engrama/.engrama/memory/decisions/0011-diff-binding-atestacao-verificavel.md:15)). O mesmo vale aqui: um `sem-release: motivo` solto no changelog abençoa PRs futuros até a próxima release. Se o escape ficar no `CHANGELOG`, ele precisa ser **vinculado ao diff** por token tipo `sha256:` sobre a superfície de release, excluindo os próprios metadados de release.

3. **Referência local = última tag não é robusta como default.** No estado atual, `git describe` resolve para `v0.1.0-20-g9af8943-dirty`; então um warning local baseado na última tag continuará disparando em branches novas por causa de mudanças unreleased já acumuladas em `main`, mesmo quando o diff atual não toca a superfície. CI com `base-ref` do PR está certo; local deveria preferir `merge-base` com a branch base configurada e só cair para última tag como fallback.

4. **A definição de “superfície distribuível” está incompleta e um pouco larga demais.** Faltam pelo menos `.engrama/engine/githooks/**` e `.claude/settings.json`, que são parte do artefato mecanizado e são sincronizados ao template ([.engrama/engine/scripts/critique-gate.sh](/Users/x86/git-projects/engrama/.engrama/engine/scripts/critique-gate.sh:103), [bin/sync-template.sh](/Users/x86/git-projects/engrama/bin/sync-template.sh:12)). Em compensação, `bin/**` pega `bin/sync-template.sh`, que é tooling de mantenedor, não superfície do adotante ([bin/sync-template.sh](/Users/x86/git-projects/engrama/bin/sync-template.sh:1)). Eu estreitaria para `bin/bootstrap.sh` e `bin/install.sh`.

5. **Eu não colocaria esse acoplamento pack-release dentro do `lint.sh` compartilhado sem opt-in explícito.** O `lint.sh` atual é sincronizado para o template ([bin/sync-template.sh](/Users/x86/git-projects/engrama/bin/sync-template.sh:165)). Se ele passar a exigir `VERSION` raiz + `CHANGELOG.md`, você empurra a política de release do repo central para todo projeto adotante por acidente. Melhor: um `release-gate.sh` root-only, chamado pela CI do repo central; só depois, se a Autoridade quiser, desenhar um modo opt-in para adotantes.

6. **A data proposta para `0.2.0` está fraca historicamente.** Os fatos que você quer liberar são de **2026-06-22** ([.engrama/log.md](/Users/x86/git-projects/engrama/.engrama/log.md:10)), mas a release ainda não existe. Se o projeto usa data de corte/tag no changelog, `0.2.0` deveria levar a data real do release, não retroagir para 2026-06-22. Como você já quer corrigir o anacronismo de `0.1.0`, eu evitaria criar outro.

7. **Os testes propostos ainda deixam buracos.** Faltam pelo menos: `release-only PR` (só `VERSION` + `CHANGELOG`) deve passar; `sem-release` stale deve falhar; fallback sem tag/upstream não pode quebrar; delete/rename na superfície deve contar; e, principalmente, o bootstrap/adotante não pode começar a falhar por causa desse gate.

8. **Há outra disciplina memória-dependente grande além de release: o espelhamento de prosa raiz ↔ template.** O próprio `sync-template.sh` diz que **não** sincroniza a prosa ([bin/sync-template.sh](/Users/x86/git-projects/engrama/bin/sync-template.sh:5)). Então mudanças em governança/specs/README do template continuam dependendo de lembrar de espelhar manualmente. A reorg de 2026-06-22 já mostrou esse risco.

9. **Outra lacuna correlata: histórico de changelog não é protegido.** O `0.1.0` já foi anacronicamente reescrito ([CHANGELOG.md](/Users/x86/git-projects/engrama/CHANGELOG.md:9)). Eu adicionaria ao menos um warning quando um PR edita seções já lançadas do changelog, porque isso quase sempre é acidente.

**Veredito**

`discordo` com o plano **como está escrito**. O objetivo está correto, mas o design ainda tem dois furos materiais para FASE 2: **o escape sem binding** e **a tentativa de espelhar a disciplina no template sem primeiro definir a semântica de release do adotante**.

**Execução**

Não aplicável. Ordem read-only cumprida.

**Próximo Passo Seguro**

1. Fechar o design do gate como **repo central only** nesta rodada: `release-gate.sh` próprio, CI vinculante, local best-effort, e escape **bound por hash**.
2. Só depois cortar a PR de release `0.2.0` com `VERSION` + `CHANGELOG`, restaurando a verdade histórica de `0.1.0`.
3. Tratar “release discipline no template” como decisão separada da Autoridade: ou vira contrato novo do pack para adotantes, ou fica fora desta fase.

Se quiser, eu monto em seguida um **desenho fechado de FASE 2** já corrigido, em formato de ordem operacional e casos de teste.
