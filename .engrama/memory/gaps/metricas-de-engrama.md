---
type: gap
status: proposed
touches: [memory/decisions/0005-orquestrador-qa-reexecucao-e-metricas, memory/decisions/0012-reconciliacao-de-memoria]
date: 2026-06-21
source_refs:
  - .engrama/engine/scripts/lint.sh
  - .engrama/memory/decisions/0012-reconciliacao-de-memoria.md
---

Métricas do Engrama precisam continuar úteis sem empurrar o projeto para infraestrutura de runtime. Este gap registra o que já está mecanizado em markdown puro e o que segue como pesquisa futura, com limite explícito: sem DB, embeddings, API ou motor semântico.

## Já implementado

- **Densidade de enlaces:** medida hoje pelo check de páginas órfãs no lint. É um proxy simples: se uma página não entra no índice nem recebe wikilinks, a malha de memória está rala.
- **Staleness:** páginas `active` em `memory/governance/`, `memory/specs/` e `memory/decisions/` podem emitir warning quando a última mudança versionada passar de 90 dias. A fonte é o último commit do arquivo, não o `mtime`.

## Em aberto

- **Cobertura:** ainda não há uma régua mecânica confiável para dizer se um tema relevante do projeto está bem coberto pela memória documental sem gerar burocracia artificial.
- **Coerência semântica:** detectar duplicata, sobreposição ou contradição de significado continua dependendo de leitura humana, cross-links e `grep`. O campo `reconcilia:` do ADR [[memory/decisions/0012-reconciliacao-de-memoria]] melhora o rastro, mas não substitui julgamento.

## Limites aceitos

- O teto continua sendo markdown-puro. Isso preserva portabilidade e simplicidade, mas aceita falsos positivos e falsos negativos nas métricas.
- Pesquisa futura nesta área precisa respeitar a arquitetura do Engrama: nada de transformar a memória institucional em infra de runtime.
