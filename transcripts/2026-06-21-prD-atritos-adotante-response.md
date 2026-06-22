---
codex-session: 019eeca7-9056-7450-9637-dc3abcc93d79
codex-session-source: stream
model: unknown
sandbox: workspace-write
label: prD-atritos-adotante
---

Vou abrir o gate obrigatório do Engrama antes de avaliar a ordem e tocar qualquer arquivo. Primeiro passo: ler a governança, o bootstrap do projeto e o topo do ledger para declarar papel, alçada, estado factual e o próximo passo seguro.
Papel: Executor Crítico. Alçada: escrever a fatia na branch `feat/p1-atritos-do-adotante`, criticar a ordem antes de executar, não comitar, e escalar objeção material se houver.

Estado factual: o topo de [.engrama/log.md](/Users/x86/git-projects/engrama/.engrama/log.md:1) registra a sequência recente PR-A/B/C já auditada; o bootstrap do projeto está `active` em [.engrama/project/bootstrap-do-projeto.md](/Users/x86/git-projects/engrama/.engrama/project/bootstrap-do-projeto.md:1), então não há bloqueio de abertura de sessão. Próximo passo seguro: inspecionar os arquivos tocados pela ordem, incluindo o ADR de governança citado, formular a crítica técnica do item 3 e só então editar. O que depende de aprovação da Autoridade: qualquer override a uma objeção material de governança; se eu concluir que o auto-seed do ledger viola ADR 0006 de forma material, essa arbitragem não é minha.
Agora vou ler a implementação atual do gate, os passos dos docs e o ADR 0006 para decidir o item 3 com base no estado real, não por inferência. Também vou checar a branch e a árvore para evitar colisão com trabalho existente.
A ordem do item 3 toca num detalhe que não fecha só com prosa: uma dispensa sem diff-binding na `main` vira autorização ampla, não “só o 1º commit”. Vou ler o gerador de fingerprint e o sincronizador antes de cravar o veredito e começar os edits.
Já está claro que o auto-seed só é defensável se ficar amarrado ao diff; sem isso, a dispensa na `main` abre mais do que o 1º commit. Antes de editar, vou localizar os testes que cobrem bootstrap/gate para encaixar as novas garantias sem regressão.
Vou fechar o veredito do item 3 e em seguida editar. Se eu implementar o auto-seed, ele vai sair com `sha256` do diff inicial e teste cobrindo que a dispensa destrava só o primeiro commit, não a branch inteira.
Plano de execução:

1. Fechar o item 3 com `ajuste-menor`, não `discordo`: aceito a dispensa automática do bootstrap **só se** ela vier amarrada por `sha256` ao diff inicial. Sem binding, a linha `dispensada` na `main` não cobre “só o 1º commit”; ela abre qualquer commit futuro de `governance/gate` nessa branch no modo legado. Isso seria uma regressão material.
2. Editar a raiz de [.engrama/scripts/critique-gate.sh](/Users/x86/git-projects/engrama/.engrama/scripts/critique-gate.sh), [bin/bootstrap.sh](/Users/x86/git-projects/engrama/bin/bootstrap.sh), [docs/INSTALL.md](/Users/x86/git-projects/engrama/docs/INSTALL.md), [docs/INSTANTIATE.md](/Users/x86/git-projects/engrama/docs/INSTANTIATE.md) e, se necessário para a propagação fiel, [bin/sync-template.sh](/Users/x86/git-projects/engrama/bin/sync-template.sh).
3. Cobrir com teste o comportamento novo: bootstrap semeia a dispensa com hash, o primeiro commit passa, uma segunda mudança sensível na mesma branch volta a bloquear; e o gate mostra a dica de “ledger vazio”.
4. Rodar `bash bin/sync-template.sh`, depois `bash tests/run.sh`, `bash .engrama/scripts/lint.sh`, `shellcheck` nos scripts e `bash tests/contract/sync.test.sh`. Se o auto-seed entrar, também vou provar num `/tmp` o 1º commit do alvo passando sem intervenção manual.
Vou editar agora o gate, o bootstrap, o sincronizador e a documentação. A mudança sensível é esta: a dispensa automática entra só como `ajuste-menor` porque vai sair vinculada por `sha256` ao snapshot staged do instalador; sem isso, eu não implementaria.
Os edits principais entraram. Agora vou sincronizar o template e validar se a nova dispensa do bootstrap realmente fica restrita ao diff inicial, porque esse é o ponto que separa `ajuste-menor` de regressão de governança.
Vou rodar a suíte completa primeiro; se algo quebrar, corrijo antes de coletar as evidências separadas. Depois faço as validações pedidas isoladamente e o smoke em `/tmp` do commit inicial do bootstrap.
A suíte passou pelos casos do gate e do diff-binding; agora estou esperando os contratos de bootstrap e sync, que são os que realmente provam o item 3 no alvo temporário.
A suíte completa fechou verde, incluindo os novos casos `C12`/`C13` do bootstrap. Agora vou coletar as evidências isoladas pedidas e o smoke em `/tmp` do commit inicial passando pelo gate.
O smoke achou uma borda real: o staging do snapshot tenta incluir `.DS_Store` que o `install.sh` exclui. O fluxo continuou, mas esse stderr é ruído indevido; vou corrigir antes de fechar a evidência final.
Vou ajustar só o staging do snapshot no bootstrap: ignorar `.DS_Store` e qualquer arquivo do template que não tenha sido materializado no alvo. Depois re-rodo a suíte e o smoke.
A correção é localizada, mas afeta o caminho do bootstrap. Vou revalidar a suíte completa para não deixar o smoke arrumado e o contrato regressivo quebrado.
A prova em `/tmp` está limpa: o bootstrap semeou a linha com `sha256` e o primeiro commit passou, sem ruído extra. Vou só fechar o inventário de arquivos tocados e preparar a devolutiva com o veredito e as evidências objetivas.
1. Leitura da ordem

Implementar os 4 itens na branch `feat/p1-atritos-do-adotante`, sem commit, propagando a mudança do gate raiz para o template via `bash bin/sync-template.sh`, e criticar explicitamente o item 3 por tocar governança sensível.

2. Crítica técnica

O item 3, do jeito proposto em prosa, tinha um problema real: uma linha `dispensada` baseada só em `branch+[governance][gate]` na `main` não cobre “só o 1º commit”; no modo legado local ela abriria commits futuros dessas categorias na mesma branch. Isso seria regressão material.

Ajuste que torna a ideia aceitável: semear a dispensa com `sha256` do diff staged do instalador. Assim, a dispensa cobre só o snapshot mecânico inicial. Se o adotante editar arquivos sensíveis antes do 1º commit, o hash fica obsoleto e o gate volta a bloquear, forçando crítica real ou registro manual. Com esse vínculo, considero o auto-seed compatível com ADR 0006 porque a dispensa fica explicitamente rotulada como da Autoridade via instalador e de escopo mínimo.

3. Veredito

`ajuste-menor`

4. Execução

Toquei estes arquivos:

- [.engrama/scripts/critique-gate.sh](/Users/x86/git-projects/engrama/.engrama/scripts/critique-gate.sh:18)
- [bin/bootstrap.sh](/Users/x86/git-projects/engrama/bin/bootstrap.sh:147)
- [bin/sync-template.sh](/Users/x86/git-projects/engrama/bin/sync-template.sh:68)
- [docs/INSTALL.md](/Users/x86/git-projects/engrama/docs/INSTALL.md:58)
- [docs/INSTANTIATE.md](/Users/x86/git-projects/engrama/docs/INSTANTIATE.md:66)
- [template/.engrama/scripts/critique-gate.sh](/Users/x86/git-projects/engrama/template/.engrama/scripts/critique-gate.sh:17)
- [tests/contract/bootstrap.test.sh](/Users/x86/git-projects/engrama/tests/contract/bootstrap.test.sh:138)
- [tests/gate/critique-gate.test.sh](/Users/x86/git-projects/engrama/tests/gate/critique-gate.test.sh:47)

Mudanças principais:

- `classify()` e a prosa do template/gate agora dizem de forma imperativa que mapear superfície sensível do domínio é obrigatório e que o que não entra no `case` passa sem revisão.
- O bloqueio do gate ganhou dica específica para ledger vazio/stub no bootstrap fresco.
- `bootstrap.sh` agora semeia uma linha `dispensada` da Autoridade via instalador, vinculada por `sha256` ao snapshot staged do próprio bootstrap, e avisa isso no stdout.
- `INSTALL.md` e `INSTANTIATE.md` agora exigem o mapeamento do domínio com exemplos concretos e mudam o self-test para branch descartável determinística.
- Adicionei testes para a dica de ledger vazio e para provar que a dispensa do bootstrap libera o 1º commit, mas não a branch inteira.

5. Evidências

- `bash tests/run.sh`
  Resultado: `TODAS AS SUITES VERDES`
  Destaques novos: `G2B` verde (dica de ledger vazio), `C12` verde (1º commit passa), `C13` verde (2ª mudança sensível volta a bloquear).

- `bash .engrama/scripts/lint.sh`
  Resultado: exit `0`

- `shellcheck bin/*.sh .engrama/scripts/*.sh tests/gate/*.sh tests/contract/*.sh tests/run.sh`
  Resultado: exit `0`

- `bash tests/contract/sync.test.sh`
  Resultado: `13 asserts batidos, 0 divergentes`

- Smoke do bootstrap:
  `bash bin/bootstrap.sh /private/tmp/engrama-prd-bootstrap-smoke`
  Depois:
  `git -C /private/tmp/engrama-prd-bootstrap-smoke commit -qm 'bootstrap inicial smoke'`
  Evidência objetiva:
  - `SEED_LINE=## [2026-06-21] main | [governance][gate] bootstrap inicial — instalacao da governanca | dispensada | Autoridade (via bin/bootstrap.sh) ... sha256:54f405e7b4df8611a2b269ea9f10b8d2da2d30760f6a7cfbf77e6d4dc91459dd`
  - `HEAD=b676869`
  - `POST_COMMIT_STATUS=0`

6. Pendências

Nenhum bloqueio técnico para a fatia.

Limite honesto que permanece: a dispensa automática cobre só o snapshot puro staged pelo instalador. Se o adotante editar `classify()`, `log.md` ou outro arquivo sensível antes do 1º commit, o `sha256` fica obsoleto e ele volta para o caminho manual/crítica real.

Não comitei. Mantive intactos os untracked pré-existentes `test-project/` e `transcripts/2026-06-21-prD-atritos-adotante-order.md`.
