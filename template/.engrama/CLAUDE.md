# Engrama — Schema da Memória Institucional

Este engrama é a **memória institucional** do projeto. Ele NÃO é o código nem a fonte da verdade do domínio — é a **interpretação acumulada** sobre o sistema: decisões (ADRs), invariantes em prosa, narrativas de workflow, gaps em aberto, histórico de fatias e o **processo de governança entre agentes**.

> **Camada:** o engrama é **camada de PROJETO** (versionado no git, na raiz), não tooling de orquestração. É a memória **canônica e portável** — sobrevive a clone novo e a desinstalar qualquer tooling de swarm/orquestração de subagentes. O índice de busca de qualquer tooling auxiliar (ex.: um `.db` derivado) é **descartável/derivado**, nunca canônico: o canônico são os arquivos `.md` versionados.

## Source of truth (não duplicar — referenciar)

```
SOURCE_OF_TRUTH_REPO: {{REPO_PATH}}
- CLAUDE.md / AGENTS.md       → gates de governança (entry-points)
- .engrama/memory/governance/*          → processo entre agentes (papéis, alçadas, handoff)
- .engrama/memory/decisions/*           → ADRs (por quê de cada decisão)
- (domínio/arquitetura)       → criados conforme o projeto avança
```

Regra: páginas que referenciam código/schema linkam **caminho relativo à raiz do repo** via `source_refs`, nunca copiam. Precisa do schema atualizado? Leia o arquivo no repo.

## Papel do engrama

Responde o que o repo não responde sozinho:
- **Por quê** decidimos X em vez de Y? (`memory/decisions/`)
- **Como** os agentes trabalham juntos? (`memory/governance/`)
- **Qual é a finalidade/stack/comandos/superfícies sensíveis do projeto?** (`memory/project/bootstrap-do-projeto.md`)
- O que é o invariante Z em prosa, com cross-links? (`memory/domain/`)
- O que ainda está em aberto? (páginas de `memory/gaps/` / `memory/roadmap/` do seu projeto)

NÃO replica: estrutura de pastas do código, assinaturas/tipos/schemas, estado **efêmero** do dia-a-dia (chat/status volátil). O **checkpoint vivo de retomada**, porém, é versionado: mora no topo do `log.md` (ver [[memory/governance/continuidade-de-sessao]]).

## Estrutura

```
.engrama/
├── CLAUDE.md      # schema e workflows
├── index.md       # catálogo navegável
├── log.md         # append-only: o que mudou e quando
├── VERSION        # versão do pack/instância
├── .gitignore     # carve-outs mecânicos do engrama
├── memory/
│   ├── governance/  # processo entre agentes
│   ├── decisions/   # ADRs
│   ├── project/     # bootstrap do projeto
│   ├── specs/       # playbooks operacionais
│   ├── domain/      # opcional por projeto
│   └── gaps/        # opcional por projeto
├── engine/
│   ├── scripts/     # gate, lint, bridge, sync helpers
│   └── githooks/    # hooks versionados
└── evidence/
    ├── qa/          # ledger de críticas do Executor
    └── transcripts/ # evidência verbatim do executor-bridge
```

> `memory/roadmap/` é o namespace canônico para referências de roadmap, mas este pack não cria um diretório físico para ele. Use o slug `memory/roadmap/...` nas referências e materialize a pasta só se o seu projeto realmente decidir versionar roadmap em arquivo.

> **Template:** vêm preenchidos neste pack: `memory/governance/`, `memory/decisions/`, `memory/project/`, `memory/specs/`, `evidence/qa/`, `engine/scripts/`, `engine/githooks/`, `CLAUDE.md`, `index.md`, `log.md`, `VERSION` e `.gitignore`. As pastas `memory/domain/` e `memory/gaps/` são específicas do seu projeto; `memory/roadmap/` fica só como namespace canônico até você optar por materializá-lo.

## Convenções de página

### Frontmatter obrigatório
```yaml
---
type: decision | domain | workflow | roadmap | gap | governance | spec
status: active | proposed | superseded | resolved
touches: [slug-relacionado, outro-slug]
date: {{DATA}}
source_refs:                       # caminhos relativos à raiz do repo
  - .engrama/...
reconcilia: ADD                   # opcional; ou: UPDATE slug | DELETE slug | NOOP slug
critica_tecnica: pendente | confirmada | incorporada | escalada | dispensada   # só em gaps de superfície sensível (ADR 0006/item 7)
---
```

### Convenções opcionais
- `reconcilia:` é opcional. Sintaxe: `ADD` (com alvo opcional) ou `<OP> <slug>` com `OP ∈ {UPDATE, DELETE, NOOP}`.
- `ADD` marca conteúdo genuinamente novo; o slug-alvo pode ficar ausente.
- `UPDATE <slug>` complementa ou ajusta uma página existente sem invalidá-la.
- `DELETE <slug>` supersede/invalida uma página existente; combinar com `status: superseded` + ponteiro para a substituta quando aplicável.
- `NOOP <slug>` registra reavaliação sem mudança material; usar com parcimônia.
- `reconcilia:` é disciplina validável, não automação semântica: detectar duplicata/overlap continua sendo trabalho humano e `grep`.

### Body
- Primeira linha após o frontmatter: resumo em 1–3 frases.
- Linkar outras páginas com **wikilinks** estilo Obsidian: o slug entre colchetes duplos (ver exemplos em `index.md` e nas páginas de `memory/governance/`).
- Seções livres conforme o tipo.

### Tipos
- **decision** — `memory/decisions/NNNN-slug.md`. Contexto, decisão, alternativas, consequências, status.
- **domain** — `memory/domain/conceito.md`. Um invariante/conceito; sempre linka a fonte no repo.
- **workflow** — `workflows/fluxo.md`. Narrativa end-to-end.
- **roadmap** — `memory/roadmap/wp-XX-slug.md`. Histórico de uma fatia.
- **gap** — `memory/gaps/slug.md`. Algo em aberto.
- **governance** — `memory/governance/slug.md`. Processo operacional entre agentes.

## Workflows operacionais

### Bootstrap inicial do projeto (primeiro startup)
1. Ler `memory/project/bootstrap-do-projeto.md`.
2. Se estiver `proposed` ou com `TODO`, o Orquestrador entrevista a Autoridade:
   finalidade · stack · topologia do repo · comandos canônicos · superfícies sensíveis · fronteiras de ambiente.
3. Atualizar:
   - `memory/project/bootstrap-do-projeto.md`
   - bloco de stack em `CLAUDE.md`
   - `classify()` em `.engrama/engine/scripts/critique-gate.sh`
   - `.claude/settings.json` se o projeto já tiver config própria e exigir merge
4. Registrar o bootstrap em `log.md`.
5. Só então iniciar trabalho de produto.

### Ingest (decisão / fato novo)
1. Decidir se o conteúdo merece página durável ou só checkpoint em `log.md`.
2. Rodar a **Fase I** de [[memory/specs/ingestao-memoria-dois-fases]]: tipo correto, frontmatter válido, `source_refs` relativos e, para `memory/domain/`, fonte concreta no repo.
3. Rodar a **Fase II** de [[memory/specs/ingestao-memoria-dois-fases]]: buscar duplicata/overlap com `rg`/`grep` e explicitar `reconcilia: ADD|UPDATE|DELETE|NOOP`.
4. Atualizar `index.md` (seção certa).
5. Logar em `log.md`: `## [YYYY-MM-DD] {ingest|decision|update} | título`.
6. Atualizar cross-links (`touches`) nas páginas afetadas e rodar o lint quando a mudança criar/renomear nós de memória.

### Query (responder pergunta)
1. Ler `index.md` → localizar páginas candidatas.
2. Ler páginas, seguir wikilinks.
3. Se a resposta tem valor durável, arquivar como página nova (não só responder no chat).

### Lint (saúde periódica)
Procurar: páginas órfãs; ADRs `superseded` sem ponteiro; invariantes citados em ≥3 páginas sem `memory/domain/` próprio; `source_refs` apontando a arquivos que mudaram; contradições entre páginas. Logar o resultado.

## Formato do log.md
```
## [{{DATA}}] decision | Modelo de governança de 3 papéis
- ADR: [[memory/decisions/0001-governanca-tres-papeis]]
- Toca: [[memory/governance/papeis-e-alcadas]]
```
Prefixo `## [YYYY-MM-DD]` permite `grep "^## \[" log.md | tail -N`.
