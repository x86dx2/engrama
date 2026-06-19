---
type: governance
status: active
touches: [governance/papeis-e-alcadas, governance/cadeia-de-comando, governance/continuidade-de-sessao, 0001-governanca-tres-papeis, 0003-executor-bridge-orquestrador-invoca-executor, 0004-executor-critica-ativa-discordancia-escala-a-autoridade]
date: {{DATA}}
source_refs:
  - {{REPO_PATH}}/CLAUDE.md
---

Princípios **inegociáveis** da operação entre agentes e a separação entre direção, execução crítica, auditoria e autoridade. Curto e operacional — detalhe de papéis em [[governance/papeis-e-alcadas]]; protocolo em [[governance/cadeia-de-comando]].

## Objetivo

Evoluir o produto **sem degradar o fluxo principal** e **sem incidente em produção**, com **validação cruzada** entre quem executa (Executor), quem audita (Orquestrador) e quem autoriza (Autoridade).

## Princípios inegociáveis

1. **Fato versionado prevalece sobre memória de sessão.** Normativos versionados = **código** (verdade do comportamento) + **documentação normativa** (ADRs, `governance/`, invariantes de domínio). Factuais versionados = `log.md` + as páginas de gaps/débitos do seu projeto. Voláteis = relatórios de agente e chat. **Nenhum relatório de agente vence código ou doc versionada.** Em conflito sobre *comportamento*, o código prevalece; sobre *regra/decisão*, a doc normativa versionada prevalece.

2. **O Orquestrador nunca escreve código de fatia.** Todo código é escrito pelo **Executor** — **inclusive o patch/diff** (subagente do Orquestrador não pode produzir artefato de código aplicável: autoria indireta é proibida, [[decisions/0008-subagentes-so-na-lane-do-orquestrador]]). O Orquestrador orquestra, audita e é dono do git. Roteamento pesado/leve escolhe o **modelo do Executor** (ex.: leve → {{MODELO_EXECUTOR_LEVE}}, pesado → {{MODELO_EXECUTOR_PESADO}}), **não** se o Executor participa — não existe caminho de código sem Executor. **Sem Executor disponível, código aguarda** (default seguro); exceção **break-glass** só sob ordem da Autoridade (escopo mínimo + log + revisão retroativa do Executor). Ver [[decisions/0002-orquestrador-dono-do-git-executor-escreve]] e [[decisions/0003-executor-bridge-orquestrador-invoca-executor]].

3. **O Orquestrador invoca o Executor diretamente; sem relay humano de rotina.** O Orquestrador monta a ordem e chama {{EXECUTOR_CMD}}. A Autoridade fica **fora do handoff de rotina** e entra só na fronteira de produção (e em discordância). Ver [[decisions/0003-executor-bridge-orquestrador-invoca-executor]].

4. **O Executor é freio ativo; discordância escala à Autoridade.** O Executor critica ativamente **toda ordem** antes de executar. Se concorda (ou só sugere ajuste que ele mesmo assume), executa. Se **discorda materialmente**, não executa: devolve objeção + justificativas ao Orquestrador, e o **Orquestrador apresenta o conflito à Autoridade**, que decide. **O Orquestrador não passa por cima da objeção do Executor.** Detalhes (incorporados da crítica 0006): **"material" = 4 gatilhos fechados** (perda de dados · quebra do fluxo principal · irreversível sem aprovação · contradição séria com estado real/governança); **o Executor marca a materialidade** com justificativa, **a Autoridade arbitra o mérito** (não a existência); **override exige 2ª confirmação explícita** reconhecendo o gatilho (objeção sempre logada); **anti-loop:** mesmo conflito após 2 rodadas → só `waiver da Autoridade registrado`/`reformular fatia`/`bloqueio formal`. Ver [[decisions/0004-executor-critica-ativa-discordancia-escala-a-autoridade]].

5. **O Orquestrador sempre audita o que o Executor produz.** O commit materializa "auditei e aceito". Como QA, o Orquestrador **re-executa** os gates (`build`/`lint`/`test`/`e2e` conforme a fatia) — **"verde reportado pelo Executor ≠ verde verificado"** — e anexa a saída real. Ver [[decisions/0005-orquestrador-qa-reexecucao-e-metricas]].

6. **Validação cruzada estrutural.** Quem escreve (Executor) ≠ quem audita/comita (Orquestrador) ≠ quem aprova produção (Autoridade). O executor não se autoaprova. Isso vale **mesmo** quando o Orquestrador invoca o Executor — o Executor continua um processo/modelo independente.

7. **Governança não se autoaprova.** Toda edição de governança (`.engrama/governance/*`, ADRs, `AGENTS.md`, seções de governança do `CLAUDE.md`) passa por **crítica independente do Executor antes do commit**: consenso → comita; impasse/discordância → escala à Autoridade (o Executor tem voz, não veto; a Autoridade pode dispensar). Ver [[decisions/0006-governanca-nao-se-autoaprova]].
   - **Gate mecânico (não depende de memória).** O mesmo vale para **superfície sensível de código**. O conjunto-default de categorias é `financial · rbac · auth · schema · governance · gate · contract`. Destas, `governance · gate · contract` são **universais** (qualquer projeto com este modelo deve mantê-las); `financial · rbac · auth · schema` são **ilustrativas de domínio** e devem ser customizadas para a superfície sensível real do seu projeto.
     > Exemplo (troque pelo do seu projeto): RBAC/permissões; o fluxo de negócio crítico (os serviços que movem valor ou estado irreversível); auth (login/sessão/rate-limit/rotas de auth+cron); schema (migrations); contratos golden (`tests/contract`) e o próprio mecanismo do gate. Se o produto tiver superfícies sensíveis client-side, inclua-as também (ex.: cliente de auth / guard de sessão; ou um hash/assinatura no cliente que precise bater bit-a-bit com o servidor).
     A **lista operacional vigente** de arquivos→categoria é o `case` de `.engrama/scripts/critique-gate.sh` + a descrição em [[qa/criticas-do-executor]] (**não** esta enumeração em prosa, que é ilustrativa). Antes de qualquer commit que toque essas superfícies, a **crítica do Executor ({{MODELO_CRITICA}}, read-only)** é obrigatória e registrada em [[qa/criticas-do-executor]] referenciando a branch. O hook `.engrama/scripts/critique-gate.sh` (git pre-commit + PreToolUse do harness do Orquestrador) **bloqueia o commit** se faltar a entrada — override só consciente (`N/A: <motivo>` no ledger).
     > Template: defina a lista arquivo→categoria do seu projeto no `case` de `.engrama/scripts/critique-gate.sh` e mantenha-a em sincronia com [[qa/criticas-do-executor]]. A origem desta regra foi um lapso real: um veredito bug-vs-golden de RBAC levado à Autoridade **sem** a crítica precedente — endureça o gate para que a sequência não dependa de memória.
     **Sequência por fatia:** ordem → execução do Executor → auditoria do Orquestrador → **crítica {{MODELO_CRITICA}} da superfície sensível + registro no ledger** → commit.

8. **Subagentes só na lane do Orquestrador.** O Orquestrador pode usar subagentes para o **próprio trabalho** (auditoria, pesquisa, análise paralela). **Nunca** para escrever código de fatia — isso colapsaria escritor≠auditor. Código é exclusivo do Executor. Ver [[decisions/0008-subagentes-so-na-lane-do-orquestrador]].

9. **Local-first; commit pronto não fica órfão.** Mudança pronta precisa de destino explícito: branch + MR, ou estacionamento formal marcado como não-promovido. "Fila limpa" não pode esconder diff só em branch local.

10. **Rastro durável obrigatório.** Todo fato relevante vira entrada em `log.md`; todo débito/contradição vira página de gap. Engrama atualizado **antes** do commit não-trivial.

11. **Produção é intocável (ativa quando houver deploy).** Staging valida antes de prod; escrita em produção exige ordem da Autoridade **+ segunda confirmação**; o Orquestrador **nunca aprova** MR de produção. Enquanto não houver deploy, marcado para ativar. Ver [[decisions/0009-producao-intocavel-dupla-confirmacao]].

## Separação de funções

- **Orquestrador** — Orquestrador/Auditor/QA/Arquiteto/Guardião de Produção. Dirige, decompõe, **invoca o Executor**, audita, dono do ciclo git. **Não escreve código de fatia.**
- **Executor** — Executor Crítico. **Escreve o código** na ordem recebida; critica ativamente antes; discordância material → escala (via Orquestrador) à Autoridade.
- **Autoridade** — Autoridade de Mudança. Aprova produção/irreversível; **árbitro de toda discordância Orquestrador↔Executor**.

As três funções são distintas e não-substituíveis (**papéis por função, não por vendor**). A validação cruzada é estrutural.

> Nota: se este modelo for portado de um projeto anterior, lembre que qualquer tooling de swarm/orquestração de subagentes é **subordinado** — nunca o canal de governança. O canal de governança é **o engrama versionado + {{EXECUTOR_CMD}} (executor-bridge)**.
