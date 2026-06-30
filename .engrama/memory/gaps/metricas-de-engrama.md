---
type: gap
status: proposed
touches: [memory/decisions/0005-orquestrador-qa-reexecucao-e-metricas, memory/decisions/0012-reconciliacao-de-memoria]
date: 2026-06-30
source_refs:
  - .engrama/engine/scripts/lint.sh
  - .engrama/memory/decisions/0012-reconciliacao-de-memoria.md
  - .engrama/engine/scripts/usage-report.sh
---

Métricas do Engrama precisam continuar úteis sem empurrar o projeto para infraestrutura de runtime. Este gap registra o que já está mecanizado em markdown puro e o que segue como pesquisa futura, com limite explícito: sem DB, embeddings, API ou motor semântico.

## Revisão 2026-06-30

Estado mantido como `proposed`. O gap continua válido, mas **não é a próxima fatia obrigatória**: as métricas atuais já cobrem sinais estruturais simples, e o salto para cobertura/coerência semântica exigiria desenho cuidadoso para não virar infraestrutura de runtime.

Mudança de contexto desde a abertura:

- A release `v0.3.0` adicionou usage ledger e `usage-report.sh`, que medem uso por modelo/papel/tier/adapter. Isso melhora observabilidade operacional, mas **não resolve** cobertura ou coerência semântica da memória.
- O lint segue como a régua mecanizada de markdown-puro para enlaces, staleness e frontmatter.
- Próxima ação, se priorizada: desenhar uma métrica de cobertura **manual-assistida** e verificável por grep/frontmatter antes de qualquer automação semântica.

## Já implementado

- **Densidade de enlaces:** medida hoje pelo check de páginas órfãs no lint. É um proxy simples: se uma página não entra no índice nem recebe wikilinks, a malha de memória está rala.
- **Staleness:** páginas `active` em `memory/governance/`, `memory/specs/` e `memory/decisions/` podem emitir warning quando a última mudança versionada passar de 90 dias. A fonte é o último commit do arquivo, não o `mtime`.
- **Uso operacional do Executor:** desde ADR 0016, `usage-report.sh` resume execuções por mês/modelo/papel/tier/adapter a partir de `evidence/usage/`. É métrica de uso, não métrica de qualidade da memória.

## Em aberto

- **Cobertura:** ainda não há uma régua mecânica confiável para dizer se um tema relevante do projeto está bem coberto pela memória documental sem gerar burocracia artificial.
- **Coerência semântica:** detectar duplicata, sobreposição ou contradição de significado continua dependendo de leitura humana, cross-links e `grep`. O campo `reconcilia:` do ADR [[memory/decisions/0012-reconciliacao-de-memoria]] melhora o rastro, mas não substitui julgamento.

## Limites aceitos

- O teto continua sendo markdown-puro. Isso preserva portabilidade e simplicidade, mas aceita falsos positivos e falsos negativos nas métricas.
- Pesquisa futura nesta área precisa respeitar a arquitetura do Engrama: nada de transformar a memória institucional em infra de runtime.
