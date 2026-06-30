---
type: spec
status: active
touches: [memory/specs/test-writing, memory/specs/README]
date: 2026-06-20
source_refs:
  - .engrama/memory/specs/infra-runbook.md
---

Runbook de **infraestrutura/ops** do seu projeto (provisionar ambiente local, subir/derrubar o dev server, seedar dados, recriar golden/baseline). Operações **locais** são livres; **remoto/produção** é gated (ADR 0009). Este arquivo é um **esqueleto agnóstico de stack**: a estrutura (contextos, golden, portas, teardown, remoto) vale para qualquer projeto; os **comandos concretos** você preenche com a `Markdown + Bash + Git hooks + Claude Code settings` do seu projeto.

> Template: substitua cada `> Template: comando do seu stack` pelo comando real (runner de teste, migrations/seed, dev server, deploy). Use `N/A (sem servidor local)` como placeholder de host:porta local e ajuste-o às portas reais que você escolher. Mantenha a **separação de ambientes locais isolados** e o **gate de remoto/produção** — essas duas invariantes são universais, não as ferramentas.

## Contextos locais (ambientes isolados)
Cada contexto sobe num **estado isolado** (banco/storage próprio) para que sessões diferentes não se contaminem. Defina um contexto de desenvolvimento livre + (opcional) um espelho local de staging/produção.

| Contexto | Comando | Porta | Estado isolado |
|---|---|---|---|
| development | `> Template: comando do seu stack` | `N/A (sem servidor local)` | banco/storage de development |
| staging-local | `> Template: comando do seu stack` | `N/A (sem servidor local)` | banco/storage de staging |
| production-local | `> Template: comando do seu stack` | `N/A (sem servidor local)` | banco/storage de production |

> Template: cada contexto deve apontar para um **banco/storage local distinto** (sufixos `-development`/`-staging`/`-production`, ou bindings separados). O objetivo é que subir um contexto **nunca** sobrescreva o estado de outro. Defina os nomes concretos para o seu projeto.

## Instância golden de caracterização (isolada)
A instância **golden** existe para caracterizar comportamento de referência (golden/contract tests) **sem** tocar a sessão de desenvolvimento ativa da Autoridade.

- **NÃO usar a porta de development** (pode ser sessão ativa da Autoridade). Caracterizar contra uma **porta dedicada** (`N/A (sem servidor local)`).
- **Subir:** `> Template: comando do seu stack` (migra+seed o estado isolado) → `> Template: comando do seu stack` (build + serve na porta dedicada).
- ⚠️ **Servidor persistente = o comando de background EM SI.** Rode o dev server direto como processo de background — **não** o embrulhe em `( … ) &` + exit, senão o processo filho é morto ao sair do wrapper.
- ⚠️ Builds podem levar **minutos**; usar poller de readiness em vez de assumir que subiu na hora: `> Template: until <healthcheck do seu stack>; do sleep 1; done`.
- **Health:** `> Template: comando de health do seu stack` (ex.: `curl -s N/A (sem servidor local)/health` → `{status:"healthy"...}`).
- **Matar:** `> Template: comando de teardown do seu stack` (ex.: matar pela porta/`N/A (sem servidor local)` ou pelo config — ver a seção de teardown abaixo).
- **Golden:** `> Template: comando que roda o golden/contract apontando para N/A (sem servidor local)`.

## App local — instância de desenvolvimento (estado isolado)
Quando o app em construção sobe numa instância própria, **isole-a** das demais (golden, sessões da Autoridade) por config e por porta.

- **Config:** use um arquivo de config local dedicado (binding de banco/storage **isolado**, porta própria) que **não colida** com as outras instâncias.
- **Migrations no estado local:** `> Template: comando de migrate/seed do seu stack` (aplica as migrations no banco/storage isolado).
- **Subir:** `> Template: comando de dev server do seu stack` (build + serve na porta isolada). ⚠️ rodar como **processo persistente em si** (não em subshell `( ) &`+exit). ⚠️ se o `build` depender de um passo anterior (ex.: `build` do framework), garanta que esse script exista. Builds curtos são rápidos; apps maiores levam minutos → usar poller `until <healthcheck>`.
- **Health:** `> Template: comando de health do seu stack` (ex.: `curl -s N/A (sem servidor local)/health` → `{status:healthy, ...}`).
- **Matar (árvore INTEIRA, antes de cada reboot):** `> Template: comando de teardown do seu stack`. Ver o aviso abaixo sobre teardown — matar só pela porta costuma **não bastar**.

> ⚠️ Teardown que casa pelo **path/config do projeto**, nunca por nome de script compartilhado. Matar só pela porta normalmente deixa processos órfãos (`build`/`watch`/runtime) reparentados ao init, que **acumulam entre reboots**. E matar por um **nome de script genérico/compartilhado** pode derrubar uma instância de **outro** projeto que usa o mesmo script.
>
> Exemplo (troque pelo do seu projeto): um teardown que casava pelo nome de um script de dev compartilhado entre dois projetos derrubou junto a instância golden do projeto vizinho — o teardown precisa casar pelo **arquivo de config** ou pelo **path do projeto** (ex.: `./seu-projeto`), não pelo nome de script compartilhado. O incidente mostrou que `matar-pela-porta` sozinho **não basta**: sobram processos órfãos que se acumulam.

- **Restaurar o golden se cair:** `> Template: comando que rebuilda e serve o estado golden EXISTENTE` (NÃO use o comando de `reset`/`seed` — ele sobrescreveria o estado). O estado isolado normalmente sobrevive a restart se for persistido em disco.
- **Re-point dos testes:** se os testes resolvem a base **por área**, ligue uma área nova ao app novo = adicionar a área ao mapa de base-URL + (quando precisar de dados) semear o estado isolado correspondente. Artefatos de build (`.cache`/`.build`/diretórios temporários do seu stack) devem ser gitignored.

## Remoto/produção (gated — ADR 0009)
- **Read-only remoto** (inspeção, checagem de migrations remotas, checagem de secrets) = livre.
- **Mutação remota** (deploy, escrita `--remote`, secrets, migration) = **ordem da Autoridade**; **produção = ordem + 2ª confirmação**. O Orquestrador **nunca aprova MR de produção**.

> Template: defina, para o seu projeto, o que conta como "read-only remoto" (livre) vs. "mutação remota" (gated) na sua `Markdown + Bash + Git hooks + Claude Code settings` — comandos de deploy, flags `--remote` de escrita, rotação de secrets, migrations/seeds. Mantenha a invariante do ADR 0009.

## Executor-bridge + tooling auxiliar
- Se o harness do Executor carrega tooling auxiliar (ex.: um servidor MCP de swarm/orquestração de subagentes) no boot, mitigue eventual hang de inicialização com timeout de startup. Esse tooling é **subordinado** ao modelo, não o canal de governança.
- Sempre invocar o Executor pelo `exec-bridge.sh`; o adapter fecha stdin ao chamar o vendor e evita travas de boot (ver [[memory/specs/executor-order]]).
