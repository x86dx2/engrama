---
type: governance
status: active
touches: [governance/index, governance/continuidade-de-sessao, governance/modelo-operacional]
date: 2026-06-20
source_refs:
  - /Users/x86/git-projects/engrama/CLAUDE.md
  - /Users/x86/git-projects/engrama/.engrama/scripts/critique-gate.sh
---

Bootstrap inicial do projeto. Este documento registra a configuração de primeira abertura do **Engrama como repo central**: uma instância viva que usa a própria governança para evoluir o pack e manter um template limpo para projetos novos.

## Decisões de bootstrap

- O `engrama` e o `Ruflos` compartilham a mesma base operacional: Claude como Orquestrador, Codex como Executor Crítico, Humano como Autoridade, `codex exec` como executor-bridge, `gpt-5.5` para crítica e `gpt-5.4`/`gpt-5.4-mini` para execução.
- O que veio do `Ruflos` como regra universal fica no Engrama: gate mecânico, handshake, crítica independente, tiers de modelo, `.claude/settings.json`, proteção contra `.env`, e bootstrap de primeira abertura.
- O que era específico do `Ruflos` não entra na instância central nem no template: stack Cloudflare/Next/D1, pasta `web/`, rotas `/api/v1`, superfícies financeiras concretas, ADRs de domínio e roadmap de migração.
- A raiz deste repo é a **instância viva**. O diretório `template/` é o **artefato distribuível** para novos projetos.

## Perfil inicial do projeto

- **Projeto:** Engrama
- **Finalidade:** Repositorio central do Engrama: instancia viva de governanca entre agentes e fonte do template bootstrapavel para novos projetos.
- **Repo:** /Users/x86/git-projects/engrama
- **Orquestrador padrão:** Claude (Claude Code)
- **Executor padrão:** Codex via `codex exec`
- **Autoridade:** Humano

## Stack e arquitetura inicial

- **Stack inferida:** Markdown + Bash + Git hooks + Claude Code settings
- **Detalhamento arquitetural:** repo documental/operacional. Bash faz bootstrap, instalação e validação; Markdown define governança, ADRs, specs e template; Git hooks impõem crítica antes de commits sensíveis.
- **Pasta(s) principais do produto:** raiz = instância viva; `.engrama/` = memória/governança ativa; `.claude/` = hook do Orquestrador; `bin/` = tooling do pack; `docs/` = guias detalhados; `template/` = template exportável.
- **Dependências externas relevantes:** `git`, `bash`, `rsync`, `sed`, `rg`, `jq`, `shellcheck` para validação local; `codex exec` para executor-bridge.

## Comandos canônicos (inferidos; confirmar/editar)

- **Dev:** N/A
- **Build:** shellcheck bin/*.sh .engrama/scripts/*.sh
- **Test:** bash ./tests/run.sh
- **E2E:** N/A
- **Outros comandos operacionais:** `bash ./.engrama/scripts/lint.sh`; `bash ./bin/bootstrap.sh /private/tmp/engrama-bootstrap-smoke`; `bash ./bin/sync-template.sh`; `git config core.hooksPath .engrama/githooks`; `rg '\{\{[A-Z_]+\}\}'` para checar placeholders no artefato instalado.

## Fronteiras e superfícies sensíveis (preencher antes do 1º commit governado)

- **Fronteiras explícitas:** não trazer ADRs/domínio/roadmap do `Ruflos` para o template central; não copiar `docs/` da instância viva para projetos novos; não sobrescrever `CLAUDE.md`, `AGENTS.md`, `.engrama/` ou `.claude/settings.json` existentes em repo-alvo.
- **`auth`:** não aplicável como domínio de produto neste repo; proteção relevante é bloqueio de leitura de `.env` em `.claude/settings.json`.
- **`rbac`:** não aplicável como domínio de produto neste repo; alçada é governança entre agentes.
- **Fluxo crítico do domínio:** instalação bootstrapavel limpa: `bin/bootstrap.sh` deve criar/inicializar repo-alvo, instalar `CLAUDE.md`, `AGENTS.md`, `.engrama/`, `.claude/settings.json`, substituir placeholders, ativar hooks e deixar `project/bootstrap-do-projeto.md` pronto para entrevista de primeira abertura.
- **`schema`:** não há schema de dados; mudanças estruturais no schema do Engrama (`.engrama/CLAUDE.md`, frontmatter, diretórios obrigatórios) são `governance`.
- **`contract`:** contrato do template/instalador: não copiar `docs/engrama`, não vazar estado vivo do repo central, manter placeholders no `template/`, e gerar projeto novo com bootstrap `proposed`.
- **Client-side sensível:** não aplicável.

## Configuração obrigatória do bootstrap

- Bloco de stack em `CLAUDE.md` alinhado ao repo central.
- `.engrama/scripts/critique-gate.sh` adaptado para governança/gate/contract do Engrama.
- `.claude/settings.json` instalado com proteção de `.env` e hook `PreToolUse`.
- `template/` preservado como artefato genérico para projetos novos.
- `log.md` registra o bootstrap da instância viva.

## Critério de pronto do bootstrap

O bootstrap só fica `active` quando:

- a finalidade do projeto estiver explícita;
- a stack estiver confirmada;
- os comandos canônicos estiverem revisados;
- o `classify()` do gate estiver alinhado à superfície sensível real;
- a Autoridade estiver identificada;
- houver uma primeira entrada real em `log.md`.
