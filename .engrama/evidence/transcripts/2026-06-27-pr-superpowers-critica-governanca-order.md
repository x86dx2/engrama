# Ordem de crítica — proposta ADR 0015 (absorção seletiva do Superpowers)

Você é o **Executor no papel de crítica**, read-only e independente do Orquestrador. NÃO edite nada. Crítica de **governança** exigida pelo ADR 0006 (mudança de processo/specs antes do commit).

## Contexto

Branch `feat/absorcao-seletiva-superpowers` (NÃO commitada). A Autoridade pediu avaliar se o projeto `obra/Superpowers` (metodologia de dev para agentes: skills auto-disparáveis + plugins cross-platform; fluxo brainstorm→worktree→plano→subagent-driven-dev→TDD→code-review→fechar branch) agrega valor à governança do Engrama. A proposta: absorver só a **camada de método** como specs markdown e **rejeitar** o que colide.

## Arquivos a revisar (working tree)

- `.engrama/memory/decisions/0015-absorcao-seletiva-metodologia-superpowers.md` (ADR, `proposed`)
- `.engrama/memory/specs/tdd-red-green-refactor.md` (`proposed`)
- `.engrama/memory/specs/planejamento-de-fatia.md` (`proposed`)
- `.engrama/memory/specs/depuracao-sistematica.md` (`proposed`)
- `.engrama/memory/specs/README.md` (tabela + touches), `.engrama/index.md`, `.engrama/log.md` (registros)

Leia também o que eles referenciam para checar reconciliação: `.engrama/memory/specs/test-writing.md`, `.engrama/memory/specs/executor-order.md`, `.engrama/memory/specs/licao-aprendida.md`, ADRs 0002/0005/0006/0008, `.engrama/CLAUDE.md`.

## O que avaliar

1. **A divisão absorver/rejeitar está correta?** As rejeições (subagent-escreve-código; iteração autônoma de horas; abstração cross-platform; runtime/plugin) estão de fato ancoradas nos ADRs citados (0002/0008/0004/0009) e no princípio "canônico=markdown, tooling=descartável"? Falta rejeitar algo? Sobra rejeição indevida?
2. **Reconciliação (Fase II):** os `reconcilia: UPDATE <slug>` estão corretos? Há duplicação/overlap real com `test-writing`/`executor-order`/`licao-aprendida` que deveria ser DELETE/merge em vez de UPDATE?
3. **As specs introduzem REGRA NOVA** (não só aplicam regra existente)? Se sim, isso é honesto e está no escopo certo (método, não governança)? Algo deveria virar ADR em vez de spec?
4. **Overclaims / desonestidade** (princípio 12): a proposta afirma mais do que entrega? Os `touches`/wikilinks estão coerentes?
5. **Fit com os papéis:** alguma spec abre brecha para o Orquestrador (ou subagentes dele) escreverem código de fatia, ou para pular o freio do Executor?

## Saída obrigatória

Achados ancorados em `arquivo:linha`. Termine com uma linha:

- `VEREDITO: confirmo` — proposta sólida, pode seguir para aprovação da Autoridade + commit.
- `VEREDITO: ressalvas` — pode seguir, liste as ressalvas (não-bloqueantes) a incorporar.
- `VEREDITO: discordo` — objeção MATERIAL; explique o gatilho (escala à Autoridade).
