---
type: decision
status: active
touches: [decisions/0005-orquestrador-qa-reexecucao-e-metricas, decisions/0006-governanca-nao-se-autoaprova]
date: {{DATA}}
source_refs:
  - .engrama/CLAUDE.md
  - .engrama/scripts/lint.sh
reconcilia: ADD
---

**Novas páginas podem declarar explicitamente como reconciliam com a memória já versionada.** A inspiração vem do `ADD`/`UPDATE`/`DELETE`/`NOOP` do mem0 e do par `Updates:`/`Obsoletes:` das RFCs do IETF, mas o mecanismo aqui continua deliberadamente markdown-puro e humano-auditável.

## Contexto

O Engrama já registra fatos, ADRs, gaps e governança de forma versionada, mas o ato de dizer se uma página **introduz**, **complementa**, **supera** ou só **reafirma** outra página ainda pode ficar implícito no corpo do texto ou em links espalhados. Isso gera custo de leitura e abre margem para duplicata semântica, supersession ambígua e reavaliação sem rastro claro.

Ao mesmo tempo, o repo não tem nem quer ter infraestrutura de runtime para memória: sem banco, embeddings, API ou resolvedor semântico. A disciplina precisa caber no modelo atual do Engrama: frontmatter, wikilinks, `grep` e lint.

## Decisão

Adotar o campo opcional de frontmatter `reconcilia:` para registrar a operação de reconciliação contra a memória existente.

- `ADD` = conteúdo genuinamente novo. O slug-alvo pode ficar ausente.
- `UPDATE <slug>` = complementa ou ajusta uma página existente sem invalidá-la.
- `DELETE <slug>` = supersede/invalida uma página existente.
- `NOOP <slug>` = reavalia e reafirma sem mudança material.

Regras de uso:

- O campo é **recomendado** para ADRs que mudam governança, processo ou contrato.
- Fora disso, continua **opcional**.
- `DELETE <slug>` deve ser coerente com `status: superseded` e com o ponteiro para a substituta quando a semântica do documento pedir isso.
- O lint valida forma e resolução do slug quando houver alvo.
- O campo explicita a intenção; ele **não** faz deduplicação automática nem infere conflito semântico.

## Alternativas consideradas

### Deixar a reconciliação só no corpo do texto

Rejeitada. Continua possível escrever a nuance no corpo, mas sem um campo curto e padronizado a leitura fica mais cara e o lint não consegue distinguir intenção explícita de omissão.

### Tornar `reconcilia:` obrigatório em toda página

Rejeitada. O custo burocrático não se paga em conteúdo rotineiro, rascunhos iniciais ou páginas claramente novas. O ganho maior está onde a memória institucional costuma conflitar: ADRs e páginas de governança.

### Automatizar detecção de duplicata/overlap

Rejeitada por agora. Isso exigiria uma camada de runtime que contraria a arquitetura do Engrama. O alvo desta decisão é disciplina validável, não automação semântica.

## Consequências

- ADRs e páginas críticas passam a declarar melhor sua relação com a memória já existente.
- O lint ganha um check mecânico para bloquear `reconcilia:` malformado ou apontando para alvo inexistente quando houver alvo obrigatório.
- `ADD` continua barato para conteúdo realmente novo.
- `NOOP` oferece um jeito explícito de registrar reavaliação sem inventar mudança inexistente.
- A qualidade da reconciliação continua limitada por julgamento humano; `grep`, leitura e revisão seguem necessários.

## Status

Ativo. Este próprio ADR usa `reconcilia: ADD` porque introduz uma convenção nova, não uma revisão de ADR existente.
