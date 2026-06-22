---
codex-session: 019eed0a-a280-7b30-af41-5020d0b442a2
codex-session-source: stream
model: unknown
sandbox: workspace-write
label: prH-domain-ingestao
---

Vou abrir os gates obrigatórios do Engrama na ordem prescrita, verificar o estado factual no topo do `log.md` e só então criticar a ordem e executar o que for seguro.
Estou no meio da leitura normativa. Até aqui, o enquadramento confirma meu papel como `Executor Crítico`, com obrigação de criticar a ordem antes de tocar nos arquivos e sem qualquer ação de git no repo real.
Papel: `Executor Crítico`. Alçada: posso editar a fatia documental nesta branch, criticar a ordem antes de executar, rodar validações locais e devo evitar qualquer mutação de git no repo real; aprovação da Autoridade só seria necessária para ação irreversível, exceção de processo ou se eu identificar discordância material. Estado factual do topo do `log.md`: o checkpoint vigente é o PR-G em `2026-06-21`, que já formalizou `reconcilia:` no ADR 0012, adicionou lint para esse campo e apontou exatamente este PR-H como próximo passo seguro.
Vou checar a convenção real do repo para espelhamento raiz↔template, o workflow de ingestão já documentado e os pontos normativos que estas páginas precisam citar.
A convenção real do repo está clara: `governance/`, `decisions/`, `specs/`, `project/` e índices são espelhados manualmente em `template/`; `domain/` e `gaps/` ficam na instância viva. Essa divisão bate com a sua ordem, então não há objeção material nela.
Vou confirmar o estado da árvore e ler os ADRs/scripts que as novas páginas precisam citar, para escrever sem quebrar o schema nem a divisão raiz↔template.
Crítica técnica antes de editar: a ordem está coerente com a convenção do repo e não vejo discordância material. O único ajuste menor que vou assumir é estender o escopo mínimo para os pontos de navegação espelhados que o lint depende na prática: além de `.engrama/index.md`, vou atualizar também `template/.engrama/index.md` e `specs/README.md` raiz+template para registrar o novo spec de ingestão e evitar documentação espelhada incompleta.
Plano de execução:
1. Criar o spec framework de ingestão e espelhar no `template/`, além de alinhar o workflow “Ingest” no `CLAUDE.md` raiz+template.
2. Criar as 3 páginas `domain/` só na instância viva, com frontmatter válido, `reconcilia: ADD`, `source_refs` relativos e cross-links densos.
3. Estender `governance/continuidade-de-sessao.md` raiz+template e a nota em ADR 0006 raiz+template, mantendo a distinção quente/fria e o contraste escritor≠auditor.
4. Atualizar índices e catálogo de specs onde necessário, depois rodar `tests/run.sh`, `lint.sh`, `shellcheck -S info` e `tests/contract/sync.test.sh` para fechar a fatia com evidência.
Vou localizar os trechos exatos onde entram a nova spec, a distinção quente/fria e a nota de contraste em ADR 0006, para editar sem espalhar a mesma regra em prosa redundante.
Estou entrando nas edições agora. Vou criar o spec e as páginas `domain/`, depois fechar os pontos espelhados raiz↔template nos arquivos de processo para manter o lint e a convenção do repo consistentes.
As páginas e os espelhos principais já estão escritos. Vou fazer uma leitura de sanidade no diff documental antes de rodar a bateria, porque o risco agora é mais de link/frente de schema do que de conteúdo bruto.
Encontrei um ajuste de portabilidade no spec: o exemplo de busca estava olhando `template/.engrama`, o que faz sentido só no repo central. Vou genericizar isso para o fluxo funcionar também quando o template virar um projeto real.
A leitura de sanidade fechou. Agora vou rodar as validações pedidas; o risco remanescente é de link órfão, wikilink quebrado ou drift raiz↔template do novo spec.
As validações específicas de sync e lint já não acusaram drift. A suíte completa ainda está rodando; vou esperar o restante porque é ali que aparecem os efeitos colaterais mais chatos de docs novas no harness real.
A suíte agregada ficou silenciosa por alguns ciclos. Vou inspecionar se ela está apenas em teste demorado ou se travou em algum subprocesso antes de decidir se preciso interromper e isolar o caso.
As validações passaram. Vou só fechar com o inventário do diff e o estado final da árvore para devolver a fatia com evidência objetiva.
**Leitura**

Você pediu a fatia documental do PR-H na branch `feat/absorcao-domain-ingestao`, sem commit e sem mutação git sensível no repo real, formalizando ingestão em duas fases e nomeando três padrões de domínio já praticados pelo Engrama.

**Crítica Técnica**

A ordem está coerente com a convenção real do repo. Meu único ajuste menor foi estender a navegação espelhada também para `template/.engrama/index.md` e `specs/README.md` raiz+template, porque o novo spec framework precisava entrar no catálogo espelhado para não deixar drift documental. Veredito: `ajuste-menor`.

**Execução**

Implementei o spec framework [`.engrama/specs/ingestao-memoria-dois-fases.md`](/Users/x86/git-projects/engrama/.engrama/specs/ingestao-memoria-dois-fases.md) e sua cópia [template](/Users/x86/git-projects/engrama/template/.engrama/specs/ingestao-memoria-dois-fases.md), alinhando o `Ingest` em [`.engrama/CLAUDE.md`](/Users/x86/git-projects/engrama/.engrama/CLAUDE.md) e [template/.engrama/CLAUDE.md](/Users/x86/git-projects/engrama/template/.engrama/CLAUDE.md). Também acrescentei a distinção memória quente/fria em [`.engrama/governance/continuidade-de-sessao.md`](/Users/x86/git-projects/engrama/.engrama/governance/continuidade-de-sessao.md) e na cópia template, sem decay/expiry automático, e a nota de contraste estrutural em [ADR 0006 raiz](/Users/x86/git-projects/engrama/.engrama/decisions/0006-governanca-nao-se-autoaprova.md) e [template](/Users/x86/git-projects/engrama/template/.engrama/decisions/0006-governanca-nao-se-autoaprova.md). No template, a referência à página de domínio ficou em prosa, não em wikilink, para respeitar a regra de `domain/` ser instância-only.

As páginas instância-only criadas foram [validacao-cruzada-estrutural](/Users/x86/git-projects/engrama/.engrama/domain/validacao-cruzada-estrutural.md), [escopo-e-identidade](/Users/x86/git-projects/engrama/.engrama/domain/escopo-e-identidade.md) e [ponto-de-vista-e-representacao](/Users/x86/git-projects/engrama/.engrama/domain/ponto-de-vista-e-representacao.md), todas com frontmatter válido, `reconcilia: ADD`, `source_refs` relativos e cross-links densos. Atualizei ainda [`.engrama/index.md`](/Users/x86/git-projects/engrama/.engrama/index.md), [template/.engrama/index.md](/Users/x86/git-projects/engrama/template/.engrama/index.md), [`.engrama/specs/README.md`](/Users/x86/git-projects/engrama/.engrama/specs/README.md) e [template/.engrama/specs/README.md](/Users/x86/git-projects/engrama/template/.engrama/specs/README.md) para registrar o novo spec e a nova seção `domain/` da instância viva.

Divisão aplicada:
- Framework: spec de ingestão, extensão de `continuidade-de-sessao`, nota em ADR 0006, ajuste do workflow `Ingest` e catálogos espelhados raiz+template.
- Instância-só: as 3 páginas `domain/` e a seção `domain/` na raiz de `index.md`.

**Evidências**

Validações rodadas:
- `bash tests/run.sh` → `TODAS AS SUITES VERDES`
- `bash .engrama/scripts/lint.sh` → exit `0`, sem órfãs e sem wikilinks quebrados
- `bash tests/contract/sync.test.sh` → `21 asserts`, `0 divergentes`
- `shellcheck -S info` → não rodei, porque nenhum `.sh` foi alterado

Observações objetivas:
- Nenhum `git config`, `git add`, `git commit` ou `git checkout` foi executado no repo real.
- Estado final do diff: 10 arquivos modificados e 5 arquivos Markdown novos sob `.engrama/`.
- O untracked `transcripts/2026-06-21-prH-domain-ingestao-order.md` já estava fora do escopo e foi deixado intacto.

**Pendências**

Nada depende de aprovação da Autoridade nesta fatia. Risco residual já documentado e mantido honesto: o furo R1 continua um teto conhecido de identidade do crítico; as novas páginas só o nomeiam, não o resolvem.
