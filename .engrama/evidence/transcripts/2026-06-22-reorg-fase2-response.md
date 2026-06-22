---
codex-session: 019eeffb-b1bc-7ba2-9fb2-ad8e01c6d18e
codex-session-source: stream
model: unknown
sandbox: workspace-write
label: reorg-fase2
---

Papel de Executor Crítico em execução da FASE 2. Vou reabrir os gates obrigatórios do Engrama na ordem prescrita, extrair o estado factual do topo de `.engrama/log.md` e só então criticar a ordem antes de editar.
Abrindo os documentos normativos restantes agora. Primeiro confirmo papéis, cadeia de comando, modelo operacional e continuidade; depois bootstrap e topo do log para fixar o estado factual antes da crítica e da execução.
Papel: Executor Crítico. Alçada: posso criticar a ordem, editar a fatia e produzir evidência, mas não faço `git config`/`commit`/`push`, não toco produção e não arbitro objeção material.

Estado factual no topo de `.engrama/log.md`: a branch em trabalho é `feat/consolidar-root-em-engrama`; a última fatia endureceu o `exec-bridge.sh` contra autoedição e fechou verde de suíte/lint/shellcheck, deixando a sequência pronta para o próximo refactor estrutural. O próximo passo seguro é auditar o estado real do tree e mapear todos os paths antigos que a reorg B precisa mover e reescrever. Nada desta ordem depende de aprovação nova da Autoridade se eu ficar dentro das fronteiras descritas; só haveria escalada se eu detectar contradição material com o estado real ou necessidade de tocar o `transcripts/` vivo fora do carve-out previsto.
Há um ponto de tensão na própria ordem, mas não é objeção material: o alvo quer `.engrama/evidence/transcripts/`, enquanto a fronteira proíbe mover ou editar o `transcripts/` vivo do root nesta run. Vou tratar isso como exceção operacional explícita: reorg completa de referências e maquinário para o novo path, mantendo o diretório vivo antigo intocado até a realocação pós-run do Orquestrador.
Plano de execução:
1. Mover a árvore física que pode ser movida sem tocar o `transcripts/` vivo: `memory/`, `engine/`, `evidence/qa` na raiz e no template.
2. Reescrever referências mecânicas em docs, scripts, harness, CI, install/bootstrap e testes; depois rodar `sync-template.sh` para propagar os 9 maquinários.
3. Ajustar os pontos com restrição especial: ledger só no cabeçalho, `roadmap/` apenas como namespace canônico, e exceção temporária do `transcripts/` vivo.
4. Validar com suíte, lint, sync idempotente, contract sync, shellcheck e grep de paths antigos; se algo quebrar, iterar até zerar.
Vou começar os edits mecânicos pela malha de paths centrais: scripts, hook/settings, sync-template, ledger e docs-raiz que definem navegação. Depois completo a cascata de testes e referências internas.
Vou aplicar o refactor físico agora. Primeiro movo os diretórios permitidos e deixo `root/.engrama/transcripts/` intocado por carve-out; em seguida reescrevo a malha de referências para o novo namespace `memory/`, `engine/` e `evidence/`.
Estou fazendo a reescrita mecânica em lote agora, com exclusão explícita de `log.md`, do ledger histórico e do `transcripts/` vivo. Depois eu reviso manualmente os pontos especiais que não podem ser tratados por substituição cega.
A substituição em lote encontrou um efeito colateral previsível: `transcripts/` foi reescrito antes de `scripts/` em algumas strings compostas e virou `tranengine/scripts`. Vou limpar esses falsos positivos agora e revisar manualmente os arquivos estruturais centrais antes de rodar a bateria de validações.
Tenho três correções estruturais antes dos testes: ajustar scripts que calculam a raiz do repo após o move para `engine/`, limpar os falsos positivos `tranengine/scripts`, e tratar o carve-out de histórico no lint para `log.md`/ledger sem tocar as entradas antigas.
Vou aplicar uma segunda passada mais cirúrgica: agora pego os tokens de path sem barra final que sobraram em testes, docs e scripts ativos. Isso corrige `core.hooksPath`, paths criados em `mkdir`, refs em `cp/git add` e o `TRANSCRIPTS_DIR` do bridge.
Vou fazer os ajustes manuais finais agora. Eles cobrem os pontos que não aceitam substituição cega: header append-only, cálculo da raiz após `engine/`, o carve-out do `transcripts/` vivo e a árvore/schema mostrados ao humano.
O patch composto falhou num trecho que já tinha drift local; vou reaplicar em blocos menores, guiado pelo conteúdo atual de cada arquivo, para evitar colisão mecânica.
As fixtures de `tests/contract/lint.test.sh` ainda geram wikilinks antigos dentro dos heredocs. Vou atualizar só o conteúdo desses fixtures para o novo namespace `memory/...`, sem mexer na intenção dos testes.
Estou sincronizando o template agora a partir da raiz canônica. Isso precisa acontecer antes da suíte, porque `template/.engrama/engine/*`, `.claude/settings.json` e `.markdownlint-cli2.yaml` têm de refletir exatamente o maquinário já corrigido na instância viva.
A parte mecânica principal está fechada. Vou entrar na bateria real agora: suíte completa primeiro, porque ela deve revelar qualquer path residual em testes, contract ou sync antes de eu gastar tempo em smoke secundário.
A suíte está em execução; primeiro bloco já entrou em `ci.test.sh`. Vou esperar a saída completa antes de corrigir qualquer quebra, para ver o conjunto real de regressões em vez de iterar no escuro.
O bloco de fuzz ainda está rodando; até aqui gate/CI/diffbind passaram sem regressão. Estou aguardando o restante da suíte antes de declarar o estado, porque os testes de contract e sync são os que mais tendem a acusar path residual nesta reorg.
A primeira quebra real apareceu no `exec-bridge`: os tests temporários não estão reconhecendo a raiz do repo após o move para `engine/scripts`. Vou inspecionar o contrato do teste e corrigir a resolução de `REPO_ROOT` antes de seguir com o restante da suíte.
Estou corrigindo o bloqueio que apareceu na validação: o refactor estrutural já foi aplicado, e agora vou ajustar `exec-bridge.sh` para o novo depth de `.engrama/engine/scripts` e rerodar a suíte completa.
A suíte avançou além do bloco de bridge e agora sobraram falhas de contrato; vou fechar as duas frentes que restam: a detecção de raiz em `exec-bridge.sh` e a regressão L18 do lint em reconciliação `UPDATE`.
Encontrei a regressão L18: o contrato do lint ainda usa `reconcilia: UPDATE governance/...` em fixture antiga. Vou alinhar esses slugs para `memory/governance/...` e, na mesma fatia, corrigir o `exec-bridge` para voltar a reconhecer o topo do repo.
Vou editar dois pontos agora: `exec-bridge.sh` para subir três níveis até o repo, e o contrato de lint para usar os slugs canônicos `memory/...` em `reconcilia:`.
O ajuste de depth não bastou; o wrapper ainda cai em “fora de repo” dentro do contrato. Vou reproduzir o cenário mínimo do teste para ver exatamente qual caminho ele está calculando na reexecução estável.
A causa apareceu: o contrato está herdando `ENGRAMA_BRIDGE_REEXEC=1` e `ENGRAMA_BRIDGE_HERE=.../.engrama/scripts` do ambiente, então o wrapper pula a cópia estável e usa um path morto legado. Vou blindar o bootstrap do script para só aceitar essas vars quando apontarem para o próprio arquivo em execução.
O wrapper voltou a funcionar no cenário mínimo; falta só confirmar o contrato inteiro do `exec-bridge` e então parto para a bateria final obrigatória do pedido.
O grep estrutural já zerou fora das carve-outs esperadas. Agora vou rodar a bateria final exigida pela ordem, capturando a saída real para anexar no retorno.
A suíte longa ainda está rodando; até aqui os blocos de gate e diff-binding seguem verdes. Vou esperar fechar e então executar as validações isoladas restantes (`lint`, `sync-template`, `shellcheck`, `grep`).
A suíte principal fechou totalmente verde. Estou rodando agora as validações de acabamento pedidas pela ordem: lint isolado, idempotência do sync, shellcheck e o grep de completude dos paths antigos.
A validação estrutural fechou. Falta só uma checagem extra que o aceite pede implicitamente via CI: markdownlint local, para confirmar que os novos ignores de `evidence/transcripts` e o carve-out do `transcripts/` vivo não deixaram ruído residual.
O grep bruto explodiu só por histórico em `transcripts/`; para fechar a prova com sinal alto, vou filtrar exatamente a allowlist da ordem. Se isso vier vazio, a reescrita de paths antigos está completa no conteúdo ativo.
1. **Leitura**  
Executor Crítico, alçada de escrever a fatia sem `git config`/`commit`/`push`. A ordem pedia a reorg mecânica da árvore `.engrama/` por contexto, espelhada em `template/`, preservando topo fixo (`CLAUDE.md`, `index.md`, `log.md`, `VERSION`, `.gitignore`), sem tocar o `transcripts/` vivo do root nem entradas históricas de `log.md`/ledger.

2. **Crítica técnica antes de executar**  
Sem objeção material. O único ponto delicado da ordem era intencional: rewire para `.engrama/evidence/transcripts/`, mas manter o `root .engrama/transcripts/` vivo intacto nesta run; tratei isso como carve-out temporário para o pós-run do Orquestrador. No meio da validação apareceu um risco real adicional: `exec-bridge.sh` herdava `ENGRAMA_BRIDGE_REEXEC/HERE` legados do ambiente e pulava a cópia estável; corrigi isso no próprio bridge.

3. **Veredito**  
`ajuste-menor`

4. **Execução**  
A reorg foi aplicada em root e template: memória em `memory/`, maquinário em `engine/`, evidência em `evidence/qa`, com o `transcripts/` vivo do root preservado. Atualizei o maquinário principal em [.engrama/engine/scripts/exec-bridge.sh](/Users/x86/git-projects/engrama/.engrama/engine/scripts/exec-bridge.sh), [.engrama/engine/scripts/lint.sh](/Users/x86/git-projects/engrama/.engrama/engine/scripts/lint.sh) e [bin/sync-template.sh](/Users/x86/git-projects/engrama/bin/sync-template.sh), além de harness (`.claude/settings.json`, `critique-gate-hook.sh`), CI, docs, ADRs, `AGENTS.md`, `CLAUDE.md`, índices e toda a suíte. No ledger, reescrevi só cabeçalho/instruções/source refs; em `log.md`, só o cabeçalho.

5. **Evidências**  
- `bash ./tests/run.sh`
```text
Resumo: 4 asserts batidos, 0 divergentes | 0 casos marcados FURO (a corrigir)
Resumo: 13 asserts batidos, 0 divergentes | 1 casos marcados FURO (a corrigir)
Resumo: 9 asserts batidos, 0 divergentes | 0 casos marcados FURO (a corrigir)
Resumo: 200 asserts batidos, 0 divergentes | 0 casos marcados FURO (a corrigir)
Resumo: 6 asserts batidos, 0 divergentes | 0 casos marcados FURO (a corrigir)
Resumo: 13 asserts batidos, 0 divergentes | 0 casos marcados FURO (a corrigir)
Resumo: 8 asserts batidos, 0 divergentes | 0 casos marcados FURO (a corrigir)
Resumo: 22 asserts batidos, 0 divergentes | 0 casos marcados FURO (a corrigir)
Resumo: 3 asserts batidos, 0 divergentes | 0 casos marcados FURO (a corrigir)
Resumo: 21 asserts batidos, 0 divergentes | 0 casos marcados FURO (a corrigir)
TODAS AS SUITES VERDES
```
- `bash ./.engrama/engine/scripts/lint.sh; echo "lint=$?"`
```text
lint=0
```
- `bash ./bin/sync-template.sh && bash ./bin/sync-template.sh`
```text
unchanged: template/.engrama/engine/scripts/critique-gate.sh
unchanged: template/.engrama/engine/scripts/critique-gate-hook.sh
unchanged: template/.engrama/engine/scripts/session-context.sh
unchanged: template/.engrama/engine/scripts/lint.sh
unchanged: template/.engrama/engine/scripts/engrama-diff-hash.sh
unchanged: template/.engrama/engine/scripts/exec-bridge.sh
unchanged: template/.engrama/engine/scripts/critique-gate-ci.sh
unchanged: template/.markdownlint-cli2.yaml
unchanged: template/.claude/settings.json
```
- `bash ./tests/contract/sync.test.sh`
```text
Resumo: 21 asserts batidos, 0 divergentes | 0 casos marcados FURO (a corrigir)
```
- `shellcheck -S info ...`
```text
<sem saída; exit 0>
```
- `grep -rn '\.engrama/\(governance\|decisions\|domain\|specs\|project\|gaps\|roadmap\|scripts\|githooks\|qa\|transcripts\)/' ...`
```text
saída bruta: só hits em ./.engrama/transcripts/**, ./.engrama/log.md e ./.engrama/evidence/qa/criticas-do-executor.md
```
- `grep ... | grep -v '^./\.engrama/transcripts/' | grep -v '^./\.engrama/log.md:' | grep -v '^./\.engrama/evidence/qa/criticas-do-executor.md:'`
```text
<sem saída; exit 1>
```

6. **Pendências**  
Sem pendência técnica da fatia. Ficam os passos explicitamente reservados ao Orquestrador: realocar o `root .engrama/transcripts/` vivo para `.engrama/evidence/transcripts/`, ajustar `core.hooksPath` para `.engrama/engine/githooks`, anexar a entrada diff-bound no ledger novo e fazer o commit único. A única validação que não consegui provar localmente foi markdownlint, porque `markdownlint-cli2` não está instalado aqui:
```text
zsh:1: command not found: markdownlint-cli2
```
