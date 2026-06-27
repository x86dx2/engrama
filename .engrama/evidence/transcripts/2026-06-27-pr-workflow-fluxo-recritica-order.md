# Re-crítica — fatia "workflow fluxo-operacional" (após incorporar a objeção material)

Você é o **Executor no papel de crítica**, read-only e independente. NÃO edite nada. Esta é a **re-crítica** após sua 1ª crítica (`codex-session:019f0a31`, veredito `discordo` material).

## O que foi incorporado (verifique se resolve)

Branch `feat/workflow-fluxo-operacional` (não commitada). Suas 4 ressalvas:

1. **MATERIAL — template gate não durável.** Corrigido **na fonte**: editei o gerador `emit_template_gate_classify()` em `bin/sync-template.sh` para incluir `.engrama/memory/workflows/*` (não mais só o arquivo gerado) e re-rodei `bin/sync-template.sh`. Confirme: `bin/sync-template.sh` (gerador) + `template/.engrama/engine/scripts/critique-gate.sh` (regenerado) + idempotência do sync. Corrigi também a afirmação falsa no `.engrama/log.md`.
2. **Schema.** Adicionei `memory/workflows/` à estrutura e corrigi o tipo (`memory/workflows/fluxo.md`) em `.engrama/CLAUDE.md` e `template/.engrama/CLAUDE.md`.
3. **Lint.** `.engrama/engine/scripts/lint.sh` agora exige frontmatter e inclui órfãs para `memory/workflows/` (copiado verbatim ao template via sync).
4. **Fidelidade do diagrama.** Nó inicial agora começa em `governança/index`; **break-glass desenhado** no caminho de código (nó `Executor disponível?` → `código AGUARDA` → break-glass sob ordem da Autoridade). Atualizei `.md` inline + `assets/engrama-fluxo.mmd` + re-renderizei o PNG. A seção de exceção deixou de dizer "não desenhado".

## Avaliar

- A objeção material #1 está **resolvida e durável** (sobrevive ao próximo sync)?
- As ressalvas 2–4 foram cobertas sem introduzir incoerência nova?
- Algo novo quebrou (gerador do sync, paridade, schema, lint, diagrama)?

## Saída

Achados ancorados em `arquivo:linha`. Termine com `VEREDITO: confirmo` | `VEREDITO: ressalvas` (liste) | `VEREDITO: discordo` (gatilho material).
