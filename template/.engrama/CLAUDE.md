# Engrama — Schema da Memória Institucional

Este engrama é a **memória institucional** do projeto. Ele NÃO é o código nem a fonte da verdade do domínio — é a **interpretação acumulada** sobre o sistema: decisões (ADRs), invariantes em prosa, narrativas de workflow, gaps em aberto, histórico de fatias e o **processo de governança entre agentes**.

> **Camada:** o engrama é **camada de PROJETO** (versionado no git, na raiz), não tooling de orquestração. É a memória **canônica e portável** — sobrevive a clone novo e a desinstalar qualquer tooling de swarm/orquestração de subagentes. O índice de busca de qualquer tooling auxiliar (ex.: um `.db` derivado) é **descartável/derivado**, nunca canônico: o canônico são os arquivos `.md` versionados.

## Source of truth (não duplicar — referenciar)

```
SOURCE_OF_TRUTH_REPO: {{REPO_PATH}}
- CLAUDE.md / AGENTS.md       → gates de governança (entry-points)
- .engrama/governance/*          → processo entre agentes (papéis, alçadas, handoff)
- .engrama/decisions/*           → ADRs (por quê de cada decisão)
- (domínio/arquitetura)       → criados conforme o projeto avança
```

Regra: páginas que referenciam código/schema linkam **caminho absoluto** via `source_refs`, nunca copiam. Precisa do schema atualizado? Leia o arquivo no repo.

## Papel do engrama

Responde o que o repo não responde sozinho:
- **Por quê** decidimos X em vez de Y? (`decisions/`)
- **Como** os agentes trabalham juntos? (`governance/`)
- O que é o invariante Z em prosa, com cross-links? (`domain/`)
- O que ainda está em aberto? (páginas de `gaps/` / `roadmap/` do seu projeto)

NÃO replica: estrutura de pastas do código, assinaturas/tipos/schemas, estado **efêmero** do dia-a-dia (chat/status volátil). O **checkpoint vivo de retomada**, porém, é versionado: mora no topo do `log.md` (ver [[governance/continuidade-de-sessao]]).

## Estrutura

```
.engrama/
├── CLAUDE.md      # este arquivo — schema e workflows
├── index.md       # catálogo navegável
├── log.md         # append-only: o que mudou e quando
├── governance/    # processo entre agentes: papéis, alçadas, handoff, continuidade
├── decisions/     # ADRs — uma decisão por arquivo, numeradas (começam em 0001)
├── domain/        # invariantes/conceitos de negócio em prosa (conforme construirmos)
├── gaps/          # trade-offs em aberto, dúvidas, débitos
└── roadmap/       # WPs / fatias com histórico
```

> **Template:** `governance/`, `decisions/`, `CLAUDE.md`, `index.md` e `log.md` vêm preenchidos neste pack. As pastas `domain/`, `gaps/` e `roadmap/` são específicas do seu projeto — crie-as e popule conforme o produto for sendo construído.

## Convenções de página

### Frontmatter obrigatório
```yaml
---
type: decision | domain | workflow | roadmap | gap | governance | spec
status: active | proposed | superseded | resolved
touches: [slug-relacionado, outro-slug]
date: {{DATA}}
source_refs:                       # caminhos absolutos no repo
  - {{REPO_PATH}}/...
critica_tecnica: pendente | confirmada | incorporada | escalada | dispensada   # só em gaps de superfície sensível (ADR 0006/item 7)
---
```

### Body
- Primeira linha após o frontmatter: resumo em 1–3 frases.
- Linkar outras páginas com **wikilinks** estilo Obsidian: o slug entre colchetes duplos (ver exemplos em `index.md` e nas páginas de `governance/`).
- Seções livres conforme o tipo.

### Tipos
- **decision** — `decisions/NNNN-slug.md`. Contexto, decisão, alternativas, consequências, status.
- **domain** — `domain/conceito.md`. Um invariante/conceito; sempre linka a fonte no repo.
- **workflow** — `workflows/fluxo.md`. Narrativa end-to-end.
- **roadmap** — `roadmap/wp-XX-slug.md`. Histórico de uma fatia.
- **gap** — `gaps/slug.md`. Algo em aberto.
- **governance** — `governance/slug.md`. Processo operacional entre agentes.

## Workflows operacionais

### Ingest (decisão / fato novo)
1. Identificar o tipo da página.
2. Criar/atualizar a página com frontmatter.
3. Atualizar `index.md` (seção certa).
4. Logar em `log.md`: `## [YYYY-MM-DD] {ingest|decision|update} | título`.
5. Atualizar cross-links (`touches`) nas páginas afetadas.

### Query (responder pergunta)
1. Ler `index.md` → localizar páginas candidatas.
2. Ler páginas, seguir wikilinks.
3. Se a resposta tem valor durável, arquivar como página nova (não só responder no chat).

### Lint (saúde periódica)
Procurar: páginas órfãs; ADRs `superseded` sem ponteiro; invariantes citados em ≥3 páginas sem `domain/` próprio; `source_refs` apontando a arquivos que mudaram; contradições entre páginas. Logar o resultado.

## Formato do log.md
```
## [{{DATA}}] decision | Modelo de governança de 3 papéis
- ADR: [[decisions/0001-governanca-tres-papeis]]
- Toca: [[governance/papeis-e-alcadas]]
```
Prefixo `## [YYYY-MM-DD]` permite `grep "^## \[" log.md | tail -N`.
