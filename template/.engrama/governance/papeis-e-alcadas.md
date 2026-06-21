---
type: governance
status: active
touches: [governance/modelo-operacional, governance/cadeia-de-comando, 0001-governanca-tres-papeis, 0002-orquestrador-dono-do-git-executor-escreve, 0003-executor-bridge-orquestrador-invoca-executor, 0004-executor-critica-ativa-discordancia-escala-a-autoridade, 0009-producao-intocavel-dupla-confirmacao]
date: {{DATA}}
source_refs:
  - CLAUDE.md
---

Os **3 papéis canônicos**, o mapeamento atual para agentes concretos e a **matriz de alçadas** por ação. Papéis são definidos **por função**, não por vendor — o mapeamento pode mudar sem invalidar o modelo.

## Papéis canônicos

1. **Orquestrador / Auditor / QA / Arquiteto / Guardião de Produção** — define direção técnica, decompõe a menor fatia segura, ordena a sequência, fixa critérios de aceite, **invoca o Executor**, valida evidências, **re-executa os gates** (QA) e emite o **veredito técnico final**. Dono do ciclo git. Autoridade de parada. **Não escreve código de fatia.**
2. **Executor Crítico** — escreve o código da ordem recebida, **nunca cego**: critica ativamente a ordem antes de executar, aponta riscos/lacunas, produz evidência. **Discordância material → não executa; devolve ao Orquestrador, que escala à Autoridade.**
3. **Autoridade de Mudança** — aprova promoção de ambiente, ação irreversível, exceção de processo; dá a 2ª confirmação de produção; **arbitra toda discordância Orquestrador↔Executor**.

Operam por **validação cruzada**: o Executor não se autoaprova; o Orquestrador não aceita execução sem evidência; a Autoridade aprova o que sobe ou altera estado sensível e arbitra impasses.

## Mapeamento atual

| Papel canônico | Agente concreto |
|----------------|-----------------|
| Orquestrador / Auditor / QA / Arquiteto / Guardião de Produção | **{{ORQUESTRADOR}}** |
| Executor Crítico | **{{EXECUTOR}}** ({{EXECUTOR_CMD}}, modelo por tier) |
| Autoridade de Mudança | **{{AUTORIDADE}}** |

> Mapeamento **mutável**: trocar quem ocupa cada papel não invalida o modelo — valem as funções e a matriz.

> Template: defina em `{{ORQUESTRADOR}}` / `{{EXECUTOR}}` / `{{AUTORIDADE}}` quem ocupa cada papel no seu projeto. Pode ser qualquer combinação de agentes/pessoas, desde que o **separador escritor≠auditor** e a **arbitragem humana de impasse** se mantenham.

## Camada de adaptadores de vendor

`EXECUTOR_CMD` (neste projeto, `{{EXECUTOR_CMD}}`), os ids de modelo/tier e o `.claude/settings.json` sao o **adaptador concreto**, trocavel. O nucleo (`Orquestrador` / `Executor` / `Autoridade`, alçadas, handshake e gate) continua **vendor-agnostico**. Quando um comando ou id de modelo aparecer na prosa, leia como configuracao concreta ou exemplo do adaptador atual — nao como namespace universal verificado.

## Como o Orquestrador aciona o Executor (executor-bridge)

O Orquestrador **invoca o Executor diretamente** via {{EXECUTOR_CMD}} (sem relay humano de rotina), passando a **ordem mínima** (ver [[governance/continuidade-de-sessao]]). O **roteamento pesado/leve** define o **modelo do Executor** (leve → {{MODELO_EXECUTOR_LEVE}}; pesado → {{MODELO_EXECUTOR_PESADO}}; trate os ids como exemplo/configuracao concreta e confirme o namespace real do adaptador), nunca se o Executor participa. O Executor devolve a **resposta crítica** (leitura/crítica/ajustes/execução/evidências/pendências). O Orquestrador **sempre audita** antes de comitar. Detalhe em [[decisions/0003-executor-bridge-orquestrador-invoca-executor]].

> Nota: qualquer tooling de swarm/orquestração de subagentes é **subordinado**, não o canal de governança. O canal de governança é **o engrama versionado + {{EXECUTOR_CMD}} (executor-bridge)**.

## Matriz de alçadas

Legenda: **D** dirige/delega · **E** executa · **C** critica/contesta · **R** revisa/audita · **A** aprova (ordem da Autoridade) · **AA** produção: ordem + 2ª confirmação · **I** informado.

| Ação | Orquestrador | Executor | Autoridade | Observação |
|------|--------------|----------|------------|------------|
| Leitura e análise (read-only) | E | E | I | ambos inspecionam tudo; sem aprovação |
| Diagnóstico, decomposição da fatia, critérios de aceite | **D** | **C** | I | Orquestrador define; Executor reage criticamente |
| Ordem operacional + invocação do Executor ({{EXECUTOR_CMD}}) | **E/D** | **C** | I | Orquestrador monta a ordem e chama o Executor; **Executor critica ativamente antes de executar** |
| Escrita de código da fatia | R | **E** | I | **Executor escreve**; Orquestrador só toca código p/ auditar/corrigir pontual (typo/lint/1–2 linhas) |
| **Discordância material do Executor sobre a ordem** | **R** | **C** | **A/AA** | Executor não executa, devolve objeção+justificativas; **Orquestrador apresenta à Autoridade**; Autoridade decide (Orquestrador **sem overrule**). "Material" = 4 gatilhos (perda de dados/quebra do fluxo/irreversível/contradição). **Override = AA** (2ª confirmação reconhecendo o gatilho); objeção sempre logada. Anti-loop: após 2 rodadas idênticas, só waiver/reformular/bloquear |
| Break-glass: código sem Executor disponível | **E** *(escopo mínimo)* | — | **A** | default = código **aguarda**; exceção só sob ordem da Autoridade + log + revisão retroativa do Executor |
| Auditoria + re-execução dos gates (QA) | **E** | C | I | Orquestrador re-roda `build`/`lint`/`test`/`e2e`; "verde do Executor ≠ verde verificado" |
| Decisão de commit (o quê/quando) + commit de código | **E** | C | I | Orquestrador tem a última palavra, **derivada da auditoria**; não comita trabalho não auditado |
| Edição de governança | **E** *(condicionada)* | **C** *(crítica obrigatória pré-commit)* | **A** | só comita após crítica do Executor + **consenso**; impasse → Autoridade; registra estado da crítica |
| Abertura de branch por fatia | **E/D** | I | I | Orquestrador abre e informa ao Executor |
| Subagentes (auditoria/pesquisa/análise) | **E** | I | I | lane do Orquestrador; **nunca** para escrever código de fatia |
| Subagente como executor de código (inclui gerar patch/diff aplicável) | — | — | — | **proibido** (colapsaria escritor≠auditor — autoria direta OU indireta) |
| Veredito técnico final | **E** | I | I | só o Orquestrador fecha a auditoria |
| **— Itens abaixo: INATIVOS até existir deploy/CI —** | | | | |
| Abrir+aprovar MR de staging | **E** | C | I | (quando houver remote/CI) Orquestrador autônomo em staging |
| Abrir MR de produção | **E/D** | C | I | Orquestrador abre e avisa; **nunca aprova** |
| Aprovar/mergear MR de produção | — | — | **AA** | Autoridade; Orquestrador nunca aprova |
| Deploy / migration / secrets — staging | **D/R** | **E** | **A** | só sob ordem da Autoridade |
| Deploy / migration / secrets — produção | **D/R** | **E** | **AA** | intocável: ordem + 2ª confirmação |
| Computer-use mutante (UI/dashboard) | **R** *(aprova escopo)* | **E** *(2 fases)* | **A/AA** | reconhecimento → aprovação → execução ([[decisions/0007-computer-use-duas-fases]]) |

## Regras de alçada

- **O Orquestrador tem visibilidade total, direção e autoridade de parada;** pode invalidar execução mal fundamentada e devolver ao Executor.
- **O Executor é obrigado a emitir opinião técnica;** nenhuma ordem é executada sem leitura crítica, riscos e ajustes.
- **Discordância material do Executor = escalonamento obrigatório à Autoridade.** O Orquestrador **não arbitra** a discordância: apresenta a objeção **fielmente** (como o Executor escreveu) + sua própria leitura, e a Autoridade decide. Ajuste menor que o Executor sugere e segue executando → Orquestrador incorpora e segue.
- **O Orquestrador não comita trabalho não auditado.** Validação cruzada estrutural (Executor escreve, Orquestrador audita).
- **Subagentes nunca escrevem código de fatia.** São ferramenta da lane do Orquestrador (auditoria/pesquisa/QA-análise).
- **Produção é intocável (ativa quando houver deploy):** escrita em prod = ordem + 2ª confirmação; o Orquestrador nunca aprova MR de prod.
- **Para cada ação sensível, registrar:** quem dirigiu, quem executou, quem contestou, quem auditou, quem aprovou, quem deve ser informado.
