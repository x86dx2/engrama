# Engrama — Schema da Memória Institucional

Este engrama é a **memória institucional** do projeto. Ele NÃO é o código nem a fonte da verdade do domínio — é a **interpretação acumulada** sobre o sistema: decisões (ADRs), invariantes em prosa, narrativas de workflow, gaps em aberto, histórico de fatias e o **processo de governança entre agentes**.

> **Camada:** o engrama é **camada de PROJETO** (versionado no git, na raiz), não tooling de orquestração. É a memória **canônica e portável** — sobrevive a clone novo e a desinstalar qualquer tooling de swarm/orquestração de subagentes. O índice de busca de qualquer tooling auxiliar (ex.: um `.db` derivado) é **descartável/derivado**, nunca canônico: o canônico são os arquivos `.md` versionados.

## Source of truth (não duplicar — referenciar)

```
SOURCE_OF_TRUTH_REPO: .
- CLAUDE.md / AGENTS.md       → gates de governança (entry-points)
- .engrama/governance/*          → processo entre agentes (papéis, alçadas, handoff)
- .engrama/decisions/*           → ADRs (por quê de cada decisão)
- (domínio/arquitetura)       → criados conforme o projeto avança
```

Regra: páginas que referenciam código/schema linkam **caminho relativo à raiz do repo** via `source_refs`, nunca copiam. Precisa do schema atualizado? Leia o arquivo no repo.

## Papel do engrama

Responde o que o repo não responde sozinho:
- **Por quê** decidimos X em vez de Y? (`decisions/`)
- **Como** os agentes trabalham juntos? (`governance/`)
- **Qual é a finalidade/stack/comandos/superfícies sensíveis do projeto?** (`project/bootstrap-do-projeto.md`)
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
├── project/       # bootstrap do projeto: finalidade, stack, comandos, superfícies sensíveis
├── specs/         # playbooks operacionais (o "como"): orquestrador, executor, commit, testes…
├── qa/            # ledger de críticas do Executor (lido pelo gate mecânico)
├── scripts/       # critique-gate.sh + critique-gate-hook.sh + session-context.sh + lint.sh + engrama-diff-hash.sh
├── githooks/      # pre-commit que delega ao gate
├── domain/        # (criada conforme o projeto) invariantes/conceitos de negócio em prosa
├── gaps/          # (criada conforme o projeto) trade-offs em aberto, dúvidas, débitos
└── roadmap/       # (criada conforme o projeto) WPs / fatias com histórico
```

> **Template:** vêm preenchidos neste pack: `governance/`, `decisions/`, `project/`, `specs/`, `qa/`, `scripts/`, `githooks/`, `CLAUDE.md`, `index.md` e `log.md`. As pastas `domain/`, `gaps/` e `roadmap/` são específicas do seu projeto — crie-as e popule conforme o produto for sendo construído.

## Convenções de página

### Frontmatter obrigatório
```yaml
---
type: decision | domain | workflow | roadmap | gap | governance | spec
status: active | proposed | superseded | resolved
touches: [slug-relacionado, outro-slug]
date: 2026-06-20
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

### Bootstrap inicial do projeto (primeiro startup)
1. Ler `project/bootstrap-do-projeto.md`.
2. Se estiver `proposed` ou com `TODO`, o Orquestrador entrevista a Autoridade:
   finalidade · stack · topologia do repo · comandos canônicos · superfícies sensíveis · fronteiras de ambiente.
3. Atualizar:
   - `project/bootstrap-do-projeto.md`
   - bloco de stack em `CLAUDE.md`
   - `classify()` em `.engrama/scripts/critique-gate.sh`
   - `.claude/settings.json` se o projeto já tiver config própria e exigir merge
4. Registrar o bootstrap em `log.md`.
5. Só então iniciar trabalho de produto.

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
## [2026-06-20] decision | Modelo de governança de 3 papéis
- ADR: [[decisions/0001-governanca-tres-papeis]]
- Toca: [[governance/papeis-e-alcadas]]
```
Prefixo `## [YYYY-MM-DD]` permite `grep "^## \[" log.md | tail -N`.
