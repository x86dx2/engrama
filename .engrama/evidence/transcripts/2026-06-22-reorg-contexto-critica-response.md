---
codex-session: 019eef98-e4e5-7273-baed-d07381713429
codex-session-source: stream
model: unknown
sandbox: read-only
label: reorg-contexto-critica
---

Vou tratar isso como uma crítica de Executor em modo read-only. Primeiro vou cumprir o gate obrigatório do repositório, identificar meu papel/alçada no Engrama e só então varrer as superfícies reais de path hardcoded para comparar com o seu plano.
Gate lido. Agora vou levantar o estado factual mínimo do bootstrap/log e em seguida varrer o repositório por referências a `.engrama/` para separar o que você já mapeou do que ficou de fora.
Tenho contexto suficiente para criticar o plano. Vou separar agora em três blocos: superfícies ativas que você não listou, superfícies históricas/verbatim que existem mas não devem ser reescritas, e riscos de ordenação/atomicidade da FASE 2.
A primeira lacuna concreta já apareceu: há paths fixos fora da sua lista em `.claude/settings.json`, `template/.claude/settings.json`, e no wrapper `.engrama/scripts/critique-gate-hook.sh`. Vou checar também o ledger e as docs internas do próprio `.engrama/`, porque ali há mistura de prosa viva com histórico append-only.
Há uma segunda classe de lacuna no plano: você cobriu wikilinks e `source_refs`, mas não os **paths literais em prosa/comandos** dentro dos `.md` internos do próprio `.engrama/` (por exemplo `project/bootstrap-do-projeto.md`, `governance/`, `scripts/`, `qa/`, `roadmap/`). Vou varrer isso agora, porque essa é a parte que mais tende a sobrar num refactor “mecânico”.
Há um gap mais sério: a árvore alvo que você propôs não tem `roadmap/`, mas o schema/governança/template ainda tratam `roadmap/` como área canônica do Engrama. Vou confirmar se ela existe fisicamente hoje ou se é “virtual”, porque isso impacta a completude do alvo, não só a reescrita de paths.
Papel: `Executor Crítico` · Alçada: `read-only`. Estado factual: o checkpoint vivo no topo de [log.md](/Users/x86/git-projects/engrama/.engrama/log.md:10) registra em `2026-06-22` a consolidação da raiz em `.engrama/` e o endurecimento do `exec-bridge`, com suíte/lint/shellcheck verdes; o merge desse trabalho ainda depende da Autoridade. Próximo passo seguro: fechar esta crítica de completude antes de qualquer mutação. Depende de aprovação da Autoridade: a FASE 2 mutante, qualquer commit/merge e a decisão de manter ou não `roadmap/` como parte canônica do schema.

Leitura da ordem: criticar, em modo read-only, a reorg por contexto da `.engrama/`, caçando lacunas de cobertura, riscos de ordering e referências hardcoded fora do seu mapa.

**Veredito**
`ajuste-menor`.

A direção do plano está correta, mas ele **não está mecanicamente completo** para uma FASE 2 segura como está escrito. As lacunas materiais são 4:

- Você não mapeou o **harness real**: [`.claude/settings.json`](/Users/x86/git-projects/engrama/.claude/settings.json:18) e [template/.claude/settings.json](/Users/x86/git-projects/engrama/template/.claude/settings.json:18).
- Você não mapeou o **wrapper do hook**: [`critique-gate-hook.sh`](/Users/x86/git-projects/engrama/.engrama/scripts/critique-gate-hook.sh:28) e [template](/Users/x86/git-projects/engrama/template/.engrama/scripts/critique-gate-hook.sh:28).
- Você cobriu `wikilinks`/`source_refs`, mas **não cobriu os paths literais em prosa/comandos** espalhados nas docs internas vivas do próprio `.engrama/`.
- A **árvore alvo está incompleta**: ela esquece `roadmap/` como área canônica futura e esquece `template/.engrama/VERSION`.

**Referências hardcoded não mapeadas**
Não estou repetindo `tests/**`, porque você já os cobriu genericamente. O que ficou de fora do seu mapa ativo foi:

- Harness: [`.claude/settings.json`](/Users/x86/git-projects/engrama/.claude/settings.json:18), [template/.claude/settings.json](/Users/x86/git-projects/engrama/template/.claude/settings.json:18).
- Hook wrapper: [`.engrama/scripts/critique-gate-hook.sh`](/Users/x86/git-projects/engrama/.engrama/scripts/critique-gate-hook.sh:28), [template/.engrama/scripts/critique-gate-hook.sh](/Users/x86/git-projects/engrama/template/.engrama/scripts/critique-gate-hook.sh:28).
- Ledger ativo: [`.engrama/qa/criticas-do-executor.md`](/Users/x86/git-projects/engrama/.engrama/qa/criticas-do-executor.md:14), [template/.engrama/qa/criticas-do-executor.md](/Users/x86/git-projects/engrama/template/.engrama/qa/criticas-do-executor.md:14).
- Bootstrap vivo: [`.engrama/project/bootstrap-do-projeto.md`](/Users/x86/git-projects/engrama/.engrama/project/bootstrap-do-projeto.md:42), [template/.engrama/project/bootstrap-do-projeto.md](/Users/x86/git-projects/engrama/template/.engrama/project/bootstrap-do-projeto.md:63).
- Schema `.engrama/CLAUDE.md` além da árvore: [raiz](/Users/x86/git-projects/engrama/.engrama/CLAUDE.md:22), [template](/Users/x86/git-projects/engrama/template/.engrama/CLAUDE.md:22).
- Governança viva com paths literais em prosa: [governance/index.md](/Users/x86/git-projects/engrama/.engrama/governance/index.md:19), [modelo-operacional.md](/Users/x86/git-projects/engrama/.engrama/governance/modelo-operacional.md:33), [cadeia-de-comando.md](/Users/x86/git-projects/engrama/.engrama/governance/cadeia-de-comando.md:77), [papeis-e-alcadas.md](/Users/x86/git-projects/engrama/.engrama/governance/papeis-e-alcadas.md:34), e pares no `template/`.
- ADRs/docs internas com paths literais em prosa: [0003](/Users/x86/git-projects/engrama/.engrama/decisions/0003-executor-bridge-orquestrador-invoca-executor.md:53), [0006](/Users/x86/git-projects/engrama/.engrama/decisions/0006-governanca-nao-se-autoaprova.md:41), [0011](/Users/x86/git-projects/engrama/.engrama/decisions/0011-diff-binding-atestacao-verificavel.md:22), [specs/README.md](/Users/x86/git-projects/engrama/.engrama/specs/README.md:10), [specs/licao-aprendida.md](/Users/x86/git-projects/engrama/.engrama/specs/licao-aprendida.md:29), [specs/ingestao-memoria-dois-fases.md](/Users/x86/git-projects/engrama/.engrama/specs/ingestao-memoria-dois-fases.md:22), e pares no `template/`.
- Root-only docs de domínio/gap com paths literais: [domain/escopo-e-identidade.md](/Users/x86/git-projects/engrama/.engrama/domain/escopo-e-identidade.md:39), [domain/validacao-cruzada-estrutural.md](/Users/x86/git-projects/engrama/.engrama/domain/validacao-cruzada-estrutural.md:37), [gaps/auditoria-e-plano-de-remediacao.md](/Users/x86/git-projects/engrama/.engrama/gaps/auditoria-e-plano-de-remediacao.md:66).
- Omissão estrutural `roadmap/`: [`.engrama/CLAUDE.md`](/Users/x86/git-projects/engrama/.engrama/CLAUDE.md:46), [`.engrama/index.md`](/Users/x86/git-projects/engrama/.engrama/index.md:49), [README.md](/Users/x86/git-projects/engrama/README.md:132), [`critique-gate.sh`](/Users/x86/git-projects/engrama/.engrama/scripts/critique-gate.sh:101), [template/.engrama/CLAUDE.md](/Users/x86/git-projects/engrama/template/.engrama/CLAUDE.md:46), [template/.engrama/index.md](/Users/x86/git-projects/engrama/template/.engrama/index.md:42).
- Omissão estrutural `template/.engrama/VERSION`: [`critique-gate.sh`](/Users/x86/git-projects/engrama/.engrama/scripts/critique-gate.sh:109), [template gate](/Users/x86/git-projects/engrama/template/.engrama/scripts/critique-gate.sh:103), [template/.engrama/VERSION](/Users/x86/git-projects/engrama/template/.engrama/VERSION:1), [docs/INSTALL.md](/Users/x86/git-projects/engrama/docs/INSTALL.md:56), [tests/contract/bootstrap.test.sh](/Users/x86/git-projects/engrama/tests/contract/bootstrap.test.sh:120).

Checagem de magnitude: eu verifiquei paths literais em pelo menos `34` arquivos ativos sob `.engrama/` na raiz e `29` no `template/` além do sweep que você explicitou.

**Riscos de ordering**
- Defina antes se `roadmap/` continua canônico. Se sim, o alvo precisa ser `memory/roadmap/` mesmo sem diretório físico hoje. Se não, isso deixa de ser refactor mecânico e vira mudança de contrato.
- Preserve `template/.engrama/VERSION` no topo. Mover ou esquecer isso quebra gate, install, bootstrap e testes do template.
- Atualize `LEDGER`/exclusão do hash **antes** de gerar a nova entrada diff-bound da reorg. Senão você calcula SHA com o caminho antigo ou reintroduz o ledger no material assinado.
- Atualize [`.claude/settings.json`](/Users/x86/git-projects/engrama/.claude/settings.json:18) e [`critique-gate-hook.sh`](/Users/x86/git-projects/engrama/.engrama/scripts/critique-gate-hook.sh:28) na mesma onda do move de `engine/scripts`, senão o harness continua apontando para o path morto.
- O root ledger mistura **header vivo** com **histórico append-only**. A FASE 2 precisa reescrever só o cabeçalho/instruções e acrescentar uma nova entrada; não pode “limpar” as entradas antigas.
- Seus critérios de aceite precisam excluir do grep “zero old path” as superfícies verbatim/históricas: [log.md](/Users/x86/git-projects/engrama/.engrama/log.md:10), entradas antigas de [criticas-do-executor.md](/Users/x86/git-projects/engrama/.engrama/qa/criticas-do-executor.md:50) e `.engrama/transcripts/**`.

**Fatiamento**
- Eu faria **1 commit final só**. Multi-commit real aumenta o risco porque gate/harness/docs/template ficam incoerentes no meio.
- Dentro desse commit, eu faria 2 sub-fases sem commitar: `A)` constantes/layout/harness/gate/sync-template, `B)` rewrite de docs internas + template + testes + grep final + suíte. Se quiser checkpoints, faça no working tree e squash no fim.

**Alternativa melhor**
- Manter a opção B, mas corrigir o alvo para incluir `memory/roadmap/` e manter `template/.engrama/VERSION` no topo. Fora isso, eu não mudaria a direção geral.

Execução: nenhuma; obedeci o modo read-only.

Pendências para liberar a FASE 2:
- incorporar os itens omitidos acima ao plano;
- decidir explicitamente o destino de `roadmap/`;
- ajustar os critérios de aceite para “zero ref ativa quebrada”, com allowlist explícita para histórico/verbatim.
