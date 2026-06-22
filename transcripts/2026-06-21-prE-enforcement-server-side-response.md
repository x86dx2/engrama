---
codex-session: 019eecc5-c261-7350-87aa-a8e65dacd9c8
codex-session-source: stream
model: unknown
sandbox: workspace-write
label: prE-enforcement-server-side
---

Vou abrir o gate obrigatório do Engrama agora para fixar papel, alçada, estado factual do log e validar se o bootstrap permite seguir. Depois disso eu devolvo a crítica técnica da ordem e só então parto para as mudanças.
Papel: `Executor Crítico`. Alçada: escrever a fatia pedida na branch atual, sem mutação git no repo real e sem ações irreversíveis. Estado factual no topo do `log.md`: a fatia anterior foi `PR-D` em `feat/p1-atritos-do-adotante`, com bootstrap já `active` e o próximo trabalho natural sendo fechar o enforcement server-side prometido ao adotante. Próximo passo seguro: inspecionar os arquivos de CI/template/docs já existentes e aplicar a versão portátil pedida. O que depende da Autoridade: nada para implementar localmente; só haveria escalada se eu encontrasse contradição material com a governança/estado real ou se fosse necessário alterar proteção de branch no GitHub de fato.

Leitura da ordem: você quer portar o enforcement server-side para o `template/`, sem copiar tooling impróprio da raiz, mantendo o `gate` portátil, sincronizando isso no `sync-template`, cobrindo com testes de contrato e deixando os docs honestos sobre a etapa manual de branch protection.

Crítica técnica antes de executar: a direção está coerente com o estado do repo e com o princípio 12 de honestidade. O único cuidado é evitar drift entre o job `gitleaks` da raiz e o do template; vou tratar isso explicitamente em teste. Também vou validar o YAML do template com parser se houver, mas como o ambiente pode não ter parser instalado, preciso manter o fallback sintático exatamente como a ordem já prevê.

Veredito: `concordo`.

Agora vou levantar o estado atual de branch/árvore e abrir os arquivos que entram na mudança.
Encontrei a branch certa (`feat/p2-enforcement-server-side`) e a árvore está limpa para a fatia, exceto um transcript não rastreado em `transcripts/` que eu não vou mexer. O próximo bloco é localizar os pontos de sync e a documentação existente sobre branch protection para espelhar sem inventar formato.
A documentação atual já admite que o enforcement vinculante depende de CI + branch protection no repo desta instância. Vou agora localizar os trechos equivalentes em `README`, `INSTALL`, `INSTANTIATE` e ADR 0006 para qualificar a promessa no template, e em paralelo abrir o estado atual do `template/` que hoje ainda não carrega CI.
Já está claro onde a promessa honesta precisa mudar: a raiz hoje fala do enforcement vinculante desta instância, mas o `template/` ainda nasce sem CI nem instrução de proteção de branch. Vou abrir os testes e a ADR espelhada do template agora, para decidir o menor conjunto de edições sem introduzir drift estrutural.
Vou editar agora quatro áreas: artefatos novos no `template/`, sync/contratos, docs do passo manual no GitHub e a ressalva honesta no README/ADR. Também vou manter o `transcripts/` fora do escopo e não tocar em nenhuma mutação git do repo real.
Antes de aplicar o patch principal, estou checando se algum teste de bootstrap assume uma lista fixa do `template/`. Se houver esse acoplamento, eu corrijo junto para não deixar a suíte verde por acidente parcial.
O patch principal já entrou. Agora estou fazendo a rodada de inspeção e ajuste fino: permissões do novo script do template, coerência das seções renumeradas nos docs e integridade do CI enxuto antes de partir para a suíte pesada.
Estou ajustando a última aresta mecânica: o novo `template/bin/critique-gate-ci.sh` precisa nascer executável, e quero provar que o `sync-template` reconhece os novos artefatos sem reintroduzir drift.
As edições estão coerentes no diff e o `sync-template` já reconhece os novos arquivos. Agora estou rodando a validação pedida: lint, shellcheck, parser YAML e depois a suíte completa, para separar rápido erro estrutural de erro de comportamento.
A validação estrutural passou: `lint`, `shellcheck` e o parser YAML aceitaram o novo workflow do template. A suíte completa está rodando agora; se houver falha, ela já deve apontar exatamente em qual contrato ou comportamento ficou inconsistente.
A suíte está no trecho mais demorado (`fuzz.test.sh`), sem erro emergente até aqui. Vou esperar concluir antes de reexecutar o contrato de sync isoladamente, como a ordem pediu.
A suíte fechou verde, inclusive o contrato novo de `sync` rodado isoladamente. Só falta uma última leitura do estado da árvore e da permissão do novo script para eu consolidar a devolutiva com arquivos tocados, evidências e o que não foi exercível localmente.
1. **Leitura da ordem**  
Portar o enforcement server-side para o `template/`, sem copiar a CI completa da raiz: adicionar `template/bin/critique-gate-ci.sh`, criar um `template/.github/workflows/ci.yml` enxuto e portátil, copiar `template/.markdownlint-cli2.yaml`, sincronizar isso no `bin/sync-template.sh`, cobrir com contratos e ajustar README/docs/ADR 0006 com a ressalva honesta sobre branch protection manual no GitHub do adotante.

2. **Crítica técnica**  
A ordem estava coerente com o estado do repo. O risco real era drift entre a raiz e o template em dois pontos: o pin do `gitleaks` e o wrapper `critique-gate-ci.sh`. Tratei isso com sincronização mecânica para script/config e com contrato explícito para o CI enxuto do template. Não houve objeção material.

3. **Veredito**  
`concordo`

4. **Execução**  
Implementei a fatia sem tocar em `git config`, `git add`, `git commit`, `git checkout` ou qualquer mutação git no repo real.

Arquivos tocados:
- [template/bin/critique-gate-ci.sh](/Users/x86/git-projects/engrama/template/bin/critique-gate-ci.sh)
- [template/.github/workflows/ci.yml](/Users/x86/git-projects/engrama/template/.github/workflows/ci.yml)
- [template/.markdownlint-cli2.yaml](/Users/x86/git-projects/engrama/template/.markdownlint-cli2.yaml)
- [bin/sync-template.sh](/Users/x86/git-projects/engrama/bin/sync-template.sh)
- [tests/contract/sync.test.sh](/Users/x86/git-projects/engrama/tests/contract/sync.test.sh)
- [docs/INSTALL.md](/Users/x86/git-projects/engrama/docs/INSTALL.md)
- [docs/INSTANTIATE.md](/Users/x86/git-projects/engrama/docs/INSTANTIATE.md)
- [README.md](/Users/x86/git-projects/engrama/README.md)
- [.engrama/decisions/0006-governanca-nao-se-autoaprova.md](/Users/x86/git-projects/engrama/.engrama/decisions/0006-governanca-nao-se-autoaprova.md)
- [template/.engrama/decisions/0006-governanca-nao-se-autoaprova.md](/Users/x86/git-projects/engrama/template/.engrama/decisions/0006-governanca-nao-se-autoaprova.md)

5. **Evidências**  
- `bash .engrama/scripts/lint.sh` → `0`
- `shellcheck bin/*.sh .engrama/scripts/*.sh .engrama/githooks/pre-commit tests/run.sh tests/gate/*.test.sh tests/contract/*.test.sh template/bin/critique-gate-ci.sh` → `0`
- `ruby -e 'require "yaml"; YAML.load_file("template/.github/workflows/ci.yml")'` → `0`  
  Validei o YAML com parser real, não só sintaxe por grep.
- `bash tests/run.sh` → `0`  
  Suíte toda verde, incluindo `sync.test.sh`; o contrato novo do template passou com `21` asserts.
- `bash tests/contract/sync.test.sh` → `0`
- `bash bin/sync-template.sh` → reconheceu `template/bin/critique-gate-ci.sh` e `template/.markdownlint-cli2.yaml` como `unchanged`, provando que o sync já cobre os novos artefatos.

6. **Pendências**  
Não comitei.

O que não foi exercível localmente:
- a execução real do workflow `template/.github/workflows/ci.yml` dentro de um repo adotante no GitHub;
- o enforcement vinculante de merge via branch protection e required check `gate`.

Estado da árvore:
- deixei intacto o transcript já não rastreado `transcripts/2026-06-21-prE-enforcement-server-side-order.md`
- o novo `template/bin/critique-gate-ci.sh` ficou executável (`rwxr-xr-x`)
