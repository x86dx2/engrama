---
codex-session: 019eecd7-325e-7632-a2d3-e34c7189240c
codex-session-source: stream
model: unknown
sandbox: workspace-write
label: prF-docs-install-polish
---

Vou abrir o gate obrigatório do Engrama na ordem prescrita e confirmar o estado factual antes de tocar qualquer arquivo. Em seguida, faço a crítica técnica da ordem e, se estiver consistente, implemento só as mudanças pedidas sem usar comandos git no repo real.
Papel: `Executor Crítico`. Alçada: escrever a fatia pedida, criticar a ordem antes de executar, não tocar git no repo real e escalar só se houver objeção material. Estado factual do topo do `log.md`: o checkpoint mais recente é o PR-E de 2026-06-21, que fechou o enforcement server-side no template e deixou como última remediação justamente o polimento barato de docs/install. Próximo passo seguro: inspecionar os arquivos-alvo, reconciliar a lista canônica de placeholders e validar se há alguma contradição material antes de editar. O que dependeria da Autoridade aqui: nada por enquanto, salvo se eu encontrar instrução que quebre o isolamento git exigido ou conflite com a governança versionada.
A ordem está consistente. Crítica técnica antes de executar: o único cuidado é não introduzir um smoke em `bin/install.sh` que dependa de HEAD existente ou que falhe em repositório recém-inicializado; vou ancorar a prova do `sha256:<hex>` num índice vazio dentro do alvo temporário para manter o teste sem commit e sem efeito colateral. Veredito: `concordo`. Agora vou inspecionar os scripts e testes relacionados, editar os pontos pedidos e depois provar tudo com o smoke em `mktemp`.
Encontrei um ponto de contrato útil antes de editar: a suite de bootstrap ainda verifica placeholders só em `CLAUDE.md`, `AGENTS.md` e `.engrama`, então ela não pega lacunas de docs/CI copiados pelo template. Vou ajustar a implementação pedida sem ampliar o escopo do contrato além do necessário, e depois validar com o smoke real do instalador.
Plano de execução:
1. Ajustar `docs/INSTANTIATE.md` para a lista canônica de 17 placeholders, apontando `engrama.values.example` como inventário e corrigindo a fidelidade do Passo 1.
2. Estender `bin/install.sh` com o smoke de integridade e completar o checklist final, sem abortar a instalação se o smoke falhar, mas deixando o erro explícito.
3. Adicionar a nota curta de ADR em `CONTRIBUTING.md` e a linha de obrigação sobre `classify()` em `template/CLAUDE.md` e, se ficar limpa, também em `CLAUDE.md`.
4. Rodar a bateria pedida, incluindo `shellcheck` e um smoke manual de `bin/install.sh` em `mktemp`, sempre com `git -C` só no diretório temporário.
Há uma sutileza no F1: o `grep -rho '{{[A-Z_]*}}' template` que a ordem chama de canônico não captura `{{CMD_E2E}}`, porque o regex ignora dígitos. Vou seguir a ordem ao pé da letra para a tabela do Passo 2 e, para não deixar ambiguidade, explicitar no texto que `engrama.values.example` é o inventário completo e que o bootstrap também infere `CMD_E2E` fora daquela tabela.
Vou editar agora `docs/INSTANTIATE.md`, `bin/install.sh`, `CONTRIBUTING.md`, `template/CLAUDE.md` e `CLAUDE.md`. O foco é manter o diff pequeno: só texto de orientação, o smoke de integridade e a nota curta de ADR/classify.
A tabela do Passo 2 ainda tinha exemplos herdados de `Ruflos`; isso conflita com a própria ordem, que manda usar `engrama.values.example` como fonte dos valores-exemplo. Vou corrigir isso antes de rodar a bateria, para o diff fechar o F1 por completo.
As edições pedidas estão no lugar. Agora estou na fase de prova: rodando a suite, lint, shellcheck e um smoke isolado do `bin/install.sh` em diretório temporário para capturar a checagem de integridade e o checklist final no output.
A verificação de contrato já fechou verde. Ainda estou esperando a suite agregada, o lint e o shellcheck terminarem para confirmar se o novo smoke do instalador não introduziu regressão em shell ou em sincronização raiz/template.
A suite agregada ainda está rodando os testes de bootstrap/smoke em `/tmp`. Lint e shellcheck já saíram sem erro; só falta o `tests/run.sh` concluir para eu fechar a evidência da bateria completa.
A bateria pedida já está verde. Falta só a prova específica do smoke do `install.sh` em `mktemp`, com `git -C` no alvo temporário, para mostrar o bloco de integridade e os passos 7/8 no próprio stdout do instalador.
**Leitura**
Poli os itens F1-F4 sem sair da alçada: docs do caminho manual, `bin/install.sh`, nota curta de ADR e o reforço de `classify()`. Não fiz commit e não rodei `git config`/`git add`/`git commit`/`git checkout` no repo real.

**Crítica técnica**
A única ambiguidade real estava no F1: o regex pedido como “canônico” (`{{[A-Z_]*}}`) não captura `{{CMD_E2E}}`. Mantive a tabela alinhada aos 17 placeholders que a ordem mandou extrair com esse comando e apontei `engrama.values.example` como inventário canônico/completo para cobrir o caso sem desobedecer à ordem.

**Veredito**
`concordo`

**Execução**
Arquivos tocados:
- [docs/INSTANTIATE.md](/Users/x86/git-projects/engrama/docs/INSTANTIATE.md:19)
- [bin/install.sh](/Users/x86/git-projects/engrama/bin/install.sh:27)
- [CONTRIBUTING.md](/Users/x86/git-projects/engrama/CONTRIBUTING.md:11)
- [template/CLAUDE.md](/Users/x86/git-projects/engrama/template/CLAUDE.md:23)
- [CLAUDE.md](/Users/x86/git-projects/engrama/CLAUDE.md:23)

O que entrou:
- `docs/INSTANTIATE.md`: Passo 1 agora cita `transcripts/`; Passo 2 ganhou a tabela reconciliada com os 17 placeholders pedidos, exemplos vindos de `engrama.values.example` e a linha apontando esse arquivo como inventário canônico.
- `bin/install.sh`: adicionei o smoke de integridade com `bash -n` dos scripts críticos no alvo e uma invocação seca de `engrama-diff-hash.sh`, sem abortar a instalação em caso de falha; o checklist final agora inclui os Passos 7 e 8.
- `CONTRIBUTING.md`: nota curta dizendo que `0001-0011` são ADRs do framework e que o projeto começa em `0012`.
- `template/CLAUDE.md` e `CLAUDE.md`: linha curta dizendo que `governance/gate/contract` já nascem protegidas e que adaptar `classify()` ao domínio continua obrigatório.

**Evidências**
Validações pedidas:
- `bash tests/run.sh` → verde, com `TODAS AS SUITES VERDES`
- `bash .engrama/scripts/lint.sh` → exit `0`
- `rg --files -g '*.sh' -g 'pre-commit' | xargs shellcheck` → exit `0` (inclui `bin/install.sh`)
- `bash tests/contract/sync.test.sh` → `21 asserts batidos, 0 divergentes`

Smoke isolado do instalador em `mktemp` com `git -C` no alvo temporário:
```text
Placeholders restantes: ''  (vazio = ok)

Versao instalada do pack: 0.1.0
Smoke de integridade (syntax-check + diff-hash):
  OK    bash -n .engrama/scripts/critique-gate.sh
  OK    bash -n .engrama/scripts/engrama-diff-hash.sh
  OK    bash -n .engrama/scripts/critique-gate-hook.sh
  OK    bash -n .engrama/scripts/lint.sh
  OK    bash -n bin/critique-gate-ci.sh
  OK    engrama-diff-hash.sh -> sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855

Smoke de integridade: OK

PRÓXIMO (julgamento do AGENTE — ver docs/INSTALL.md):
  Passo 7) ativar enforcement server-side (push + branch protection — ver docs/INSTALL.md/INSTANTIATE.md)
  Passo 8) revisar/apagar o exemplo seed em .engrama/log.md e .engrama/qa/criticas-do-executor.md
```

**Pendências**
Nada bloqueando localmente. O que não foi exercível aqui foi só o enforcement server-side real no GitHub (`push` + branch protection); isso ficou documentado, mas não dá para provar sem um remoto alvo.
