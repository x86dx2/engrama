---
codex-session: 019eef11-41b1-7f90-be3c-e131d22ae05b
codex-session-source: stream
model: unknown
sandbox: workspace-write
label: consolidar-root-em-engrama
---

Vou abrir os arquivos de governança exigidos pelo gate, na ordem, antes de tocar no código. Depois confirmo papel, alçada, estado factual do log e o próximo passo seguro.
Seguindo a ordem do gate agora em `papeis-e-alcadas`, `cadeia-de-comando`, `modelo-operacional`, `continuidade-de-sessao`, bootstrap e topo do log. Só depois disso eu avalio a ordem e começo a alteração.
Papel: `Executor Crítico`. Alçada: escrever a fatia, criticar ativamente a ordem antes de executar, não arbitrar governança nem git, e parar se houver discordância material. Estado factual lido no topo do `log.md`: a entrada mais recente é `2026-06-21 feat | PR-H — absorcao mem0/Honcho: nomear padroes (domain) + spec de ingestao`, na branch `feat/absorcao-domain-ingestao`, com Executor via `exec-bridge.sh`, veredito `ajuste-menor`, QA verde e absorção fechada.

Próximo passo seguro: validar a ordem contra o estado real da branch atual, mapear todas as referências a `bin/critique-gate-ci.sh` e `transcripts/`, e então executar a migração mecânica A+B preservando paridade raiz↔template e a fronteira de não tocar no `transcripts/` vivo da raiz. O que depende de aprovação da Autoridade: apenas o merge do PR, conforme a própria ordem.
Agora vou verificar o estado real da árvore e localizar todas as referências ativas aos paths antigos. Isso fecha a crítica técnica com base em evidência antes de eu mover qualquer arquivo.
O estado real bate com a ordem: a branch é `feat/consolidar-root-em-engrama`, sem mudanças rastreadas, e há só o transcript da própria ordem como untracked preservado. Encontrei as referências mecânicas esperadas; agora estou lendo os arquivos-alvo para fechar a crítica e aplicar a migração sem deixar drift entre raiz e template.
A crítica técnica está fechando em `ajuste-menor`, não em objeção material. O único ponto delicado é a convivência temporária entre o `transcripts/` vivo da raiz e o novo destino `.engrama/transcripts/`: vou mudar só código, template, testes e docs ativas, e deixar intacto todo transcript histórico e a pasta viva da raiz, exatamente como a ordem exige.
Plano de execução e veredito:

1. `Veredito`: `ajuste-menor`.
A ordem está coerente com o estado real. O ajuste que vou assumir é operacional: tratar como “referência ativa” apenas código, testes, workflows, docs e ADRs atuais, preservando verbatim histórico em `transcripts/`, `log.md` e ledger append-only.

2. `Movimentos mecânicos`.
Vou mover `bin/critique-gate-ci.sh` para `.engrama/scripts/` na raiz e no template, mover `template/transcripts/README.md` para `template/.engrama/transcripts/README.md`, e ajustar `sync-template.sh` para sincronizar os novos destinos sem recriar `template/bin/` ou `template/transcripts/`.

3. `Refs e contratos`.
Vou atualizar workflows, `install.sh`, `exec-bridge.sh`, `lint.sh`, `.markdownlint-cli2.yaml`, testes de contrato/gate, README/docs/ADRs listados e revisar o restante via grep para zerar referências ativas quebradas a `bin/critique-gate-ci.sh` e `transcripts/`.

4. `Validação`.
Depois dos edits, vou rodar a suíte completa, lint, sync idempotente, contratos e shellcheck dos `.sh` tocados, além dos greps pedidos para provar que só sobraram referências históricas/verbatim.
Vou tocar agora nos arquivos. Primeiro movo os artefatos físicos com `git mv`; depois ajusto scripts, workflows, testes e docs para o novo layout e para a exclusão de `.engrama/transcripts/` no lint/markdownlint.
`git mv` está bloqueado neste sandbox porque `.git` está somente leitura; vou fazer os movimentos no working tree com `mv` e deixar a indexação para o Orquestrador no ambiente dele. Isso não altera o escopo funcional da fatia.
Os movimentos e a maior parte das referências já foram reescritos. Agora estou fazendo a passada de consistência: sincronizar raiz→template onde o contrato é mecânico, rodar grep nos caminhos antigos e fechar o que ainda sobrar fora de histórico/verbatim.
Os edits estão fechados. Vou entrar na etapa de prova: suíte completa, lint, sync idempotente, shellcheck e os greps finais para confirmar que só sobraram referências históricas aos paths antigos.
A suíte completa ainda está rodando. Assim que ela terminar eu fecho os contratos específicos e, se algo falhar, volto direto no ponto em vez de seguir para o resto das validações.
O único ponto que apareceu na prova até agora foi um warning de `shellcheck` no gate do template: o `classify()` gerado repete `exec-bridge.sh` depois de `*.sh`, então o warning é legítimo. Vou eliminar essa redundância na origem para manter `shellcheck -S info` limpo sem mudar comportamento.
Fechei o último warning real de `shellcheck` sem alterar comportamento: era redundância no `classify()` gerado do template. Vou reexecutar a suíte completa uma vez mais para que a prova final corresponda exatamente ao estado atual do working tree.
A parte funcional já está verde; estou só fechando as provas pedidas no estado final exato do patch. Vou rerodar o `lint`, o `sync-template` idempotente e os greps finais depois da última correção mecânica do template.
Os greps finais acharam o que eu queria achar: não há path antigo ativo para `bin/critique-gate-ci.sh`; sobraram só transcripts históricos e entradas históricas em `log/ledger`, que são permitidas. Para `transcripts/`, ainda restaram três menções ativas em prosa onde eu tinha deixado o caminho “abreviado” dentro de `.engrama/`; vou expandi-las para `.engrama/transcripts/` e rerodar o grep.
1. **Leitura da ordem**  
Consolidei o escopo A+B: `bin/critique-gate-ci.sh` foi realocado para `.engrama/scripts/`, `template/transcripts/README.md` foi realocado para `template/.engrama/transcripts/README.md`, e atualizei código, workflows, testes, docs e ADRs para o novo layout, preservando a paridade raiz↔template e sem tocar no `transcripts/` vivo da raiz.

2. **Crítica técnica**  
Não houve objeção material. Os riscos reais eram: quebrar a gravação do transcript desta run, deixar o `lint.sh` varrer verbatim em `.engrama/transcripts/`, e driftar raiz↔template. Tratei isso mudando só código/refs ativas, adicionando o `prune` no lint, e re-sincronizando o template.  
Ajuste menor assumido: neste sandbox o `.git` está read-only, então `git mv` não foi possível; fiz os movimentos no working tree com `mv`.

3. **Veredito**  
`ajuste-menor`

4. **Execução**  
Movi os artefatos para [`.engrama/scripts/critique-gate-ci.sh`](/Users/x86/git-projects/engrama/.engrama/scripts/critique-gate-ci.sh), [`template/.engrama/scripts/critique-gate-ci.sh`](/Users/x86/git-projects/engrama/template/.engrama/scripts/critique-gate-ci.sh) e [`template/.engrama/transcripts/README.md`](/Users/x86/git-projects/engrama/template/.engrama/transcripts/README.md).  
Atualizei [`exec-bridge.sh`](/Users/x86/git-projects/engrama/.engrama/scripts/exec-bridge.sh), [`lint.sh`](/Users/x86/git-projects/engrama/.engrama/scripts/lint.sh), [`sync-template.sh`](/Users/x86/git-projects/engrama/bin/sync-template.sh), [`install.sh`](/Users/x86/git-projects/engrama/bin/install.sh), workflows CI, testes de contrato/gate e a prosa ativa em [`README.md`](/Users/x86/git-projects/engrama/README.md), [`docs/INSTALL.md`](/Users/x86/git-projects/engrama/docs/INSTALL.md), [`docs/INSTANTIATE.md`](/Users/x86/git-projects/engrama/docs/INSTANTIATE.md), [`CHANGELOG.md`](/Users/x86/git-projects/engrama/CHANGELOG.md) e ADRs 0003/0006 raiz+template.  
O `transcripts/` da raiz e seus históricos ficaram intactos, como exigido.

5. **Evidências**  
- Prova física dos destinos:
```text
./.engrama/scripts/critique-gate-ci.sh
./template/.engrama/scripts/critique-gate-ci.sh
./template/.engrama/transcripts/README.md
```
- `bash ./tests/run.sh`  
Saída final: `TODAS AS SUITES VERDES`  
Resumos: `ci 4/0`, `critique-gate 13/0`, `diffbind 9/0`, `fuzz 200/0`, `hook 6/0`, `bootstrap 13/0`, `exec-bridge 7/0`, `lint 22/0`, `session-context 3/0`, `sync 21/0`.
- `bash ./.engrama/scripts/lint.sh; echo "lint exit=$?"`  
Saída real: `lint exit=0`
- `bash ./bin/sync-template.sh && bash ./bin/sync-template.sh`  
As duas runs saíram só com `unchanged:` para os 9 espelhos, incluindo `template/.engrama/scripts/critique-gate-ci.sh`, `template/.engrama/scripts/exec-bridge.sh`, `template/.engrama/scripts/lint.sh` e `template/.markdownlint-cli2.yaml`.
- `bash ./tests/contract/sync.test.sh`  
Saída real: `Resumo: 21 asserts batidos, 0 divergentes | 0 casos marcados FURO`
- `shellcheck -S info ...` nos `.sh` tocados  
Saída real: nenhuma; exit `0`.
- `grep -rn 'bin/critique-gate-ci' . | grep -v '\.git/'`  
Sobrou só em verbatim/histórico: `./transcripts/...`, `./.engrama/log.md`, `./.engrama/qa/criticas-do-executor.md`.
- `grep -rnE '(^|[^.])transcripts/' . | grep -v '\.git/'`  
Revisado: as ocorrências ativas agora são do caminho novo `.engrama/transcripts/...`; referências ao diretório raiz `transcripts/` sobraram só em verbatim/histórico e no [`transcripts/README.md`](/Users/x86/git-projects/engrama/transcripts/README.md), que foi explicitamente preservado.

6. **Pendências**  
`git status` ficou com `D bin/critique-gate-ci.sh`, `D template/bin/critique-gate-ci.sh`, `D template/transcripts/README.md` e os novos caminhos como `??`, porque eu não consegui usar `git mv` com `.git` read-only neste sandbox. O Orquestrador só precisa stagear as renames normalmente.  
Também ficaram intocados, por desenho, o `transcripts/` histórico da raiz e o untracked `transcripts/2026-06-22-consolidar-root-em-engrama-order.md`.  
Dependência de aprovação da Autoridade: apenas o merge do PR.
