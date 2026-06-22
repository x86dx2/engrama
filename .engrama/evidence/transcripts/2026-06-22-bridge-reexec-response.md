---
codex-session: 019eef66-3f0d-7192-aca6-9f7cd5b6ef8c
codex-session-source: stream
model: unknown
sandbox: workspace-write
label: bridge-reexec
---

Vou abrir os gates obrigatórios do Engrama na ordem prescrita e confirmar o estado factual antes de tocar no bridge ou nos testes.
Papel: Executor Crítico. Alçada: escrever a fatia, criticar a ordem antes de executar, sem tocar git de promoção nem governança fora do escopo; estado factual no topo do log ainda precisa ser lido para fechar o handshake, depois sigo para inspecionar `exec-bridge.sh` e os testes.
Papel: `Executor Crítico`. Alçada: escrever a fatia pedida, criticar a ordem antes de executar, sem promover git nem ultrapassar as fronteiras definidas. Estado factual do topo de `.engrama/log.md`: branch `feat/consolidar-root-em-engrama`, refactor recente moveu `transcripts/` para `.engrama/transcripts/`, e houve um incidente real em 2026-06-22 ao editar o próprio `exec-bridge.sh` em execução; próximo passo seguro é inspecionar o bridge atual, o teste contratual e o estado da árvore para aplicar o guard de re-exec sem alterar o restante do comportamento. Depende de aprovação da Autoridade apenas o merge do PR #14, como já indicado na ordem.
Encontrei dois artefatos não rastreados no worktree: `.engrama/scripts/.exec-bridge-stable.sh` e um transcript de ordem da run atual. Eles são coerentes com a mitigação manual descrita no log, então vou preservá-los e trabalhar só no bridge raiz, no sync e no teste contratual.
Vou editar duas superfícies: o topo de `.engrama/scripts/exec-bridge.sh` para re-exec em cópia estável com cleanup do tempfile, e `tests/contract/exec-bridge.test.sh` para um caso que corrompe o bridge do working tree durante a run e prova saída `0` com transcripts preservados. Depois sincronizo o template pelo `bin/sync-template.sh`, sem mexer manualmente nele.
O guard e o caso contratual novo já entraram. Agora vou sincronizar o template, rodar o teste do bridge primeiro para validar a semântica de re-exec e depois executar a bateria completa pedida.
O teste novo passou no primeiro ciclo: a mutação in-place do `exec-bridge.sh` do working tree não derrubou a run e os transcripts saíram corretos. Vou seguir com a suíte completa, shellcheck e o duplo sync para fechar a evidência pedida.
A suíte principal continua verde até aqui; o ponto relevante desta fatia, `E8`, já está estável dentro do `tests/run.sh` também. Falta só o fechamento de `lint.test.sh`, `sync.test.sh` e os checks finais.
As validações pedidas fecharam com exit `0`, incluindo o duplo `sync-template` idempotente e `shellcheck -S info` limpo no bridge. Vou só revisar o diff final e o estado da árvore para entregar a devolutiva mínima com evidência suficiente.
1. **Leitura da ordem**  
Entendi que a fatia era endurecer o bridge para não reler o próprio arquivo do working tree durante a execução, fazendo re-exec imediato a partir de uma cópia estável, sem mexer no restante do comportamento; depois propagar isso ao template e provar a imunidade com um teste contratual determinístico.

2. **Crítica técnica**  
Sem discordância material. Fiz dois ajustes menores ao esboço: o cleanup da cópia estável precisava de `trap` no processo pai para cobrir `EXIT/HUP/INT/TERM`, e o teste precisava editar o bridge **in-place**; se eu trocasse o arquivo por rename, poderia não exercer o modo de falha por offset/inode que motivou o incidente.

3. **Veredito**  
`ajuste-menor`

4. **Execução**  
Adicionei o guard de re-exec no topo de [.engrama/scripts/exec-bridge.sh](/Users/x86/git-projects/engrama/.engrama/scripts/exec-bridge.sh:5), com `HERE` resolvido via `ENGRAMA_BRIDGE_HERE` sob re-exec. Rodei `bash ./bin/sync-template.sh`, que propagou a mudança para [template/.engrama/scripts/exec-bridge.sh](/Users/x86/git-projects/engrama/template/.engrama/scripts/exec-bridge.sh:5). Também acrescentei o caso `E8` em [tests/contract/exec-bridge.test.sh](/Users/x86/git-projects/engrama/tests/contract/exec-bridge.test.sh:185), onde o stub do `codex` corrompe o `exec-bridge.sh` do working tree durante a run e o bridge ainda sai `0` com transcripts válidos.

5. **Evidências**  
`bash ./tests/run.sh`: `TODAS AS SUITES VERDES`; destaque para `exec-bridge.test.sh` `8 asserts batidos, 0 divergentes` e `sync.test.sh` `21 asserts batidos, 0 divergentes`.  
`bash ./tests/contract/exec-bridge.test.sh`: `E8` verde; resumo `8 asserts batidos, 0 divergentes`.  
`bash ./bin/sync-template.sh && bash ./bin/sync-template.sh`: todas as linhas `unchanged`, incluindo `template/.engrama/scripts/exec-bridge.sh`, confirmando idempotência.  
`bash ./tests/contract/sync.test.sh`: `S3CA` verde; resumo `21 asserts batidos, 0 divergentes`.  
`shellcheck -S info .engrama/scripts/exec-bridge.sh`: sem saída, exit `0`.

6. **Pendências e bloqueios**  
Sem bloqueio técnico desta fatia. Preservei dois não rastreados pré-existentes do cenário atual, `.engrama/scripts/.exec-bridge-stable.sh` e `.engrama/transcripts/2026-06-22-bridge-reexec-order.md`. O que depende da Autoridade continua sendo só o merge do PR #14; próximo passo seguro do Orquestrador é auditar/reproduzir o cenário e então stagear/comitar o diff.
