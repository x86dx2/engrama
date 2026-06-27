# Ordem de crítica — fatia "workflow fluxo-operacional" + governar memory/workflows/

Você é o **Executor no papel de crítica**, read-only e independente. NÃO edite nada. Crítica de **governança + gate** (ADR 0006) antes do commit.

## Contexto

Branch `feat/workflow-fluxo-operacional` (NÃO commitada). A Autoridade pediu o fluxograma do engrama "com todos os caminhos" e escolheu versioná-lo como **página workflow no .engrama**. Ao executar, notei que `memory/workflows/` era o único namespace de memória fora do `classify()` — então também governei o namespace.

## Arquivos a revisar (working tree)

- `.engrama/memory/workflows/fluxo-operacional.md` (type `workflow`, `proposed`) — 2 Mermaid inline + legenda + links pros assets.
- `.engrama/memory/workflows/assets/` — `engrama-fluxo.{mmd,png}`, `engrama-ingest.{mmd,png}` (render local; png binário).
- `.engrama/engine/scripts/critique-gate.sh` e `template/.engrama/engine/scripts/critique-gate.sh` — adicionei `.engrama/memory/workflows/*) addcat governance` na linha de governança (runtime E template).
- `.engrama/index.md` (seção Workflows), `.engrama/log.md` (checkpoint).

Leia para checar fidelidade: `.engrama/memory/governance/cadeia-de-comando.md`, `modelo-operacional.md`, `continuidade-de-sessao.md`, `.engrama/CLAUDE.md` (schema/estrutura).

## O que avaliar

1. **Fidelidade:** o fluxograma contradiz algum normativo (cadeia/modelo/continuidade)? Algum caminho está ERRADO, faltando ou invertido? (ex.: overrule, gatilhos de materialidade, ordem dos passos, gate/diff-binding, produção inativa).
2. **Honestidade (princ. 12):** a página se declara "visualização; prevalece o normativo" — isso está correto e suficiente? Há overclaim?
3. **Gate change:** governar `memory/workflows/` como `governance` é a decisão certa (consistência com os outros namespaces de memória)? A paridade runtime↔template está correta (são baselines independentes; sync não sincroniza classify)? Algum efeito colateral no gate?
4. **Schema:** o `.engrama/CLAUDE.md` lista `workflows/` como tipo mas não como dir físico (igual `roadmap/`). Materializar `memory/workflows/` exige atualizar a estrutura no schema? É bloqueante?
5. **Mecânica:** versionar PNG binário sob `.engrama/` é aceitável? `reconcilia: ADD`, `touches`, `source_refs` coerentes?

## Saída obrigatória

Achados ancorados em `arquivo:linha`. Termine com:
- `VEREDITO: confirmo` | `VEREDITO: ressalvas` (liste-as) | `VEREDITO: discordo` (gatilho material; escala à Autoridade).
