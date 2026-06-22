---
type: spec
status: active
touches: [memory/governance/cadeia-de-comando, memory/governance/modelo-operacional]
date: 2026-06-20
source_refs:
  - CLAUDE.md
  - .engrama/memory/governance/cadeia-de-comando.md
  - .engrama/memory/governance/modelo-operacional.md
---

Checklist de **commit** (aplicado pelo Orquestrador — git é a lane do Orquestrador, ADR [[memory/decisions/0002-orquestrador-dono-do-git-executor-escreve]]; **não** é subagente). O commit materializa "auditei e aceito".

## Antes de commitar
- [ ] **Auditei** o que está sendo commitado (não comito trabalho não auditado). Código → re-executei os gates (ADR [[memory/decisions/0005-orquestrador-qa-reexecucao-e-metricas]]).
- [ ] **Engrama atualizado ANTES** do commit não-trivial: `log.md` (entry `## [data] tipo | título`) + página/ADR/gap conforme o que mudou.
- [ ] Se é **governança** → passou pela **crítica do Executor** (ADR [[memory/decisions/0006-governanca-nao-se-autoaprova]]) com consenso (ou impasse escalado / dispensa da Autoridade).
- [ ] Sem **secrets/.env/credenciais** no diff. Sem binários/runtime gitignored (DBs, índices derivados de tooling auxiliar, `node_modules/`, etc.).

## Mensagem
- **Conventional commit:** `tipo(escopo): descrição` — `feat|fix|docs|test|chore|refactor|perf`.
- Corpo: o quê + porquê, conciso.
- **NUNCA** `Co-Authored-By` (a menos que `.claude/settings.json` tenha `attribution.commit`).
- Identidade: a do repo, consistente com o autor configurado do projeto.

> Template: defina a identidade de commit do **seu** projeto (nome/email do autor canônico no `git config`). Se este modelo for portado de um projeto anterior, mantenha a identidade consistente com a do novo repo — não herde cegamente a do projeto de origem.

## Depois
- [ ] **Destino explícito:** push (trilha não-prod) ou estacionamento formal declarado. Commit local não encerra entrega.
- [ ] `git push origin main` (ou branch/MR quando a trilha exigir).
- [ ] **Produção** (quando houver deploy): o Orquestrador **nunca aprova MR de prod**; escrita em prod = ordem + 2ª confirmação (ADR [[memory/decisions/0009-producao-intocavel-dupla-confirmacao]]).

> Template: ajuste o nome da branch padrão (`main`/`master`/etc.) e a trilha de promoção (`feature → staging → main`, MRs, host de git/CI) ao seu projeto. Mantenha o invariante: commit local não encerra entrega — destino (push ou estacionamento declarado) é obrigatório.

## Granularidade
Um commit = uma mudança coerente. Lote de teste / fatia / decisão de governança = commits separados e rotulados.
