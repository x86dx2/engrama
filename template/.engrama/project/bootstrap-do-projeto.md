---
type: governance
status: proposed
touches: [governance/index, governance/continuidade-de-sessao, governance/modelo-operacional]
date: {{DATA}}
source_refs:
  - CLAUDE.md
  - .engrama/scripts/critique-gate.sh
---

Bootstrap inicial do projeto. Este documento existe para a **primeira abertura útil** depois que o Engrama é instalado. Enquanto ele estiver com `status: proposed` ou contiver marcadores `TODO`, o **Orquestrador** interrompe o trabalho de produto e conduz a entrevista de bootstrap com a Autoridade.

## Entrevista obrigatória do primeiro startup

Perguntar, confirmar e registrar:

1. **Qual é a finalidade do projeto?**
2. **Quais são as stacks tecnológicas e os principais componentes?**
3. **Qual é a topologia do repo?** (apps, libs, serviços, infra, docs)
4. **Quais são os comandos canônicos?** (`dev`, `build`, `test`, `e2e`, seeds, DB local)
5. **Quais são as superfícies sensíveis reais do projeto?** (`auth`, `rbac`, fluxo crítico, `schema`, `contract`, segredos, client-side sensível)
6. **Quais ambientes/sistemas não podem ser tocados?** (prod, legado, app antigo, banco remoto)
7. **Quem é a Autoridade de Mudança?**
8. **Existe algum requisito operacional extra do projeto?** (CI, deploy, hosting, registry, monorepo, compliance)

## Perfil inicial do projeto

- **Projeto:** {{PROJETO}}
- **Finalidade:** {{FINALIDADE_DO_PROJETO}}
- **Repo:** {{REPO_PATH}}
- **Orquestrador padrão:** {{ORQUESTRADOR}}
- **Executor padrão:** {{EXECUTOR}} via `{{EXECUTOR_CMD}}`
- **Autoridade:** {{AUTORIDADE}}

## Stack e arquitetura inicial

- **Stack inferida:** {{STACK}}
- **Detalhamento arquitetural:** TODO
- **Pasta(s) principais do produto:** TODO
- **Dependências externas relevantes:** TODO

## Comandos canônicos (inferidos; confirmar/editar)

- **Dev:** {{CMD_DEV}}
- **Build:** {{CMD_BUILD}}
- **Test:** {{CMD_TEST}}
- **E2E:** {{CMD_E2E}}
- **Outros comandos operacionais:** TODO

## Fronteiras e superfícies sensíveis (preencher antes do 1º commit governado)

- **Fronteiras explícitas:** TODO
- **`auth`:** TODO
- **`rbac`:** TODO
- **Fluxo crítico do domínio:** TODO
- **`schema`:** TODO
- **`contract`:** TODO
- **Client-side sensível:** TODO

## Configuração obrigatória do bootstrap

- Atualizar o bloco "Stack do projeto" em `CLAUDE.md` se a inferência estiver incompleta ou errada.
- Adaptar `.engrama/scripts/critique-gate.sh` (`classify()`) às superfícies reais do projeto.
- Confirmar/mesclar `.claude/settings.json` se o projeto já tiver config própria do Claude Code.
- Criar as primeiras páginas de `domain/`, `gaps/` e `roadmap/` se o escopo do produto já estiver claro.
- Registrar no `log.md` o bootstrap concluído e o próximo passo seguro.

## Critério de pronto do bootstrap

O bootstrap só fica `active` quando:

- a finalidade do projeto estiver explícita;
- a stack estiver confirmada;
- os comandos canônicos estiverem revisados;
- o `classify()` do gate estiver alinhado à superfície sensível real;
- a Autoridade estiver identificada;
- houver uma primeira entrada real em `log.md`.
