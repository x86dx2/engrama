---
type: spec
status: active
touches: [memory/specs/README, memory/decisions/0012-reconciliacao-de-memoria, memory/governance/continuidade-de-sessao]
date: {{DATA}}
source_refs:
  - .engrama/CLAUDE.md
  - .engrama/memory/decisions/0012-reconciliacao-de-memoria.md
  - .engrama/memory/governance/continuidade-de-sessao.md
  - .engrama/engine/scripts/lint.sh
reconcilia: ADD
---

Playbook operacional da **ingestão durável em duas fases**. Ele formaliza o fluxo que o Engrama já praticava de modo implícito no `Ingest` do `.engrama/CLAUDE.md`: primeiro validar se existe um **candidato** bem-formado; depois reconciliar esse candidato com a memória já versionada via `reconcilia:`.

## Objetivo

Transformar um fato/decisão/padrão novo em memória institucional **sem fingir deduplicação semântica automática**. O Engrama opera em markdown puro: o teto honesto aqui é **julgamento humano + `grep`/`rg`**, suficiente para algo como ~500–1000 fatos bem linkados, mas não equivalente a um resolvedor semântico.

## Quando usar

- Nova página em `memory/decisions/`, `memory/governance/`, `memory/specs/`, `memory/domain/`, `memory/gaps/` ou `memory/roadmap/`.
- Revisão de página existente cujo efeito sobre a memória precise ficar explícito.
- Reavaliação que não muda o conteúdo, mas merece rastro durável (`NOOP`).

Se o conteúdo é puramente efêmero, de sessão, ou só checkpoint local, ele fica no topo de [[log]] e **não** vira página nova.

## Fase I — candidato

Objetivo: provar que o artefato candidato **merece** entrar na memória durável e já nasce no formato do Engrama.

### Checklist mínimo

1. **Escolher o tipo certo da página.**
   - `decision` para ADR.
   - `spec` para playbook operacional.
   - `domain` para padrão/invariante nomeado do seu projeto.
   - `governance`, `gap`, `roadmap` conforme a superfície.
2. **Preencher frontmatter válido.**
   - `type`, `status`, `date`, `source_refs`.
   - `reconcilia:` quando a relação com a memória precisar ficar explícita; para página genuinamente nova, `reconcilia: ADD`.
3. **Garantir `source_refs` relativos à raiz.**
   - `memory/domain/` sempre aponta para a fonte concreta no repo, nunca para uma lembrança vaga.
   - `source_refs` descrevem a implementação/fonte vigente, não a aspiração.
4. **Checar se a página nasce navegável.**
   - Pelo menos um link de entrada em `index.md`.
   - Wikilinks para os ADRs/governança/specs que sustentam a página.
5. **Decidir se é página nova ou edição de página existente.**
   - Se a mudança só melhora um documento atual sem criar outro nó de memória, editar o alvo pode ser mais correto que abrir outro arquivo.

### Saída da Fase I

Um candidato com shape válido: frontmatter correto, `source_refs` reais, links iniciais e posição clara no catálogo.

## Fase II — reconciliação

Objetivo: comparar o candidato com o que **já** existe e declarar a operação correta em `reconcilia:`, conforme o ADR [[memory/decisions/0012-reconciliacao-de-memoria]].

### Busca mínima antes de decidir

```bash
rg -n "<termo-principal>|<sinonimo>" .engrama
rg -n "reconcilia:|status: superseded|<slug-alvo>" .engrama
```

Use `rg`/`grep` para procurar:
- o mesmo conceito com nome diferente;
- ADR/spec/domain já existente sobre o mesmo assunto;
- páginas `superseded` que talvez já cubram o caso;
- entradas do `log.md` que mostrem contexto recente.

### Árvore de decisão

#### 1. Não há equivalente real

Use `reconcilia: ADD`.

Quando aplicar:
- o conceito ainda não existe como página própria;
- o assunto aparecia espalhado em várias páginas, mas sem nome canônico;
- a fatia cria um novo nó de memória em vez de só complementar um antigo.

#### 2. O candidato complementa uma página existente sem invalidá-la

Use `reconcilia: UPDATE <slug>`.

Quando aplicar:
- a página nova adiciona detalhe operacional, limite honesto ou exemplificação;
- o alvo continua válido e permanece `active`;
- o leitor precisa entender que há continuidade, não substituição.

#### 3. O candidato substitui materialmente uma página existente

Use `reconcilia: DELETE <slug>`.

Quando aplicar:
- o alvo antigo deixa de ser a leitura correta;
- a nova página passa a ser a referência principal.

Obrigatório nesse caso:
- marcar a página antiga com `status: superseded`;
- deixar um ponteiro explícito para a substituta;
- não esconder a supersession só em `log.md`.

#### 4. A revisão só reafirma o que já era verdade

Use `reconcilia: NOOP <slug>` **apenas** se a reavaliação merecer rastro durável.

Quando aplicar:
- a leitura foi rechecada e a conclusão permaneceu a mesma;
- o valor está na evidência de revisão, não numa mudança de conteúdo.

Se não há valor durável na reafirmação, pare na leitura humana e não gere página nova.

## Teto honesto

- O Engrama **não** faz busca vetorial, deduplicação semântica nem merge automático.
- `reconcilia:` explicita intenção; ele **não** prova que você encontrou toda duplicata possível.
- A cobertura prática depende da qualidade dos nomes, wikilinks, `source_refs` e da disciplina de busca.
- Acima de algumas centenas de fatos, o custo cognitivo sobe; o mecanismo continua útil, mas continua humano.

## Fechamento operacional

Depois da decisão `ADD|UPDATE|DELETE|NOOP`:

1. atualizar a página candidata;
2. ajustar a página-alvo, se houver supersession ou ponteiro pendente;
3. registrar a nova página em [[index]] e no índice de [[memory/specs/README]], quando aplicável;
4. atualizar `touches` e wikilinks das páginas vizinhas;
5. rodar o lint para pegar órfãs, links quebrados e `reconcilia:` malformado.

Este spec detalha o `Ingest` do `.engrama/CLAUDE.md`; o workflow curto continua lá, e a disciplina de memória quente/fria fica em [[memory/governance/continuidade-de-sessao]].
