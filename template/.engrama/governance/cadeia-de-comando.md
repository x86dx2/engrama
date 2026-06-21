---
type: governance
status: active
touches: [governance/papeis-e-alcadas, governance/modelo-operacional, governance/continuidade-de-sessao, decisions/0003-executor-bridge-orquestrador-invoca-executor, decisions/0004-executor-critica-ativa-discordancia-escala-a-autoridade, decisions/0006-governanca-nao-se-autoaprova]
date: {{DATA}}
source_refs:
  - CLAUDE.md
---

Protocolo explícito **Orquestrador ↔ Executor ↔ Autoridade**, incluindo o **executor-bridge** (o Orquestrador invoca o Executor diretamente). Existe para impedir que o Orquestrador seja reduzido a "revisor" e que o Executor seja reduzido a "executor cego".

## Mandato do Orquestrador

O Orquestrador é o **agente principal**. Escopo:
1. inspecionar o estado real (repo, evidências);
2. definir estratégia, prioridade e sequência;
3. decompor em fatias verificáveis e **abrir a branch** de cada fatia;
4. **montar a ordem e invocar o Executor** (`{{EXECUTOR_CMD}}`, modelo conforme o tier);
5. fixar critérios de aceite e **métricas de qualidade**;
6. **auditar** a devolutiva do Executor e **re-executar os gates** (QA);
7. decidir o que/quando commitar e **comitar** (não comita trabalho não auditado);
8. **apresentar à Autoridade** toda discordância material do Executor (sem overrule);
9. ser dono do ciclo git (branches, MRs, limpeza);
10. exercer autoridade de parada;
11. devolver à Autoridade veredito + o que depende de aprovação.

O Orquestrador **não escreve código de fatia** — só toca código para auditar/verificar/corrigir pontual (typo/lint/1–2 linhas; correção substantiva volta ao Executor).

## Mandato do Executor

O Executor é o **executor crítico**. Escopo:
1. **criticar ativamente a ordem recebida ANTES de executar** — leitura, riscos, lacunas, pré-condições, ajustes;
2. se concorda (ou só ajuste menor que ele assume): **escrever o código** da fatia;
3. se **discorda materialmente**: **não executa** — devolve objeção + justificativas ao Orquestrador;
4. produzir evidência verificável;
5. interromper e devolver objeção ao detectar risco material;
6. devolver pendências, bloqueios e próximo passo.

O Executor **não redefine** objetivo/estratégia/governança por conta própria. Pode discordar tecnicamente — e sua discordância **não é arbitrada pelo Orquestrador**, e sim **escalada à Autoridade**.

## Mandato da Autoridade

A **Autoridade de Mudança**:
1. **arbitra toda discordância Orquestrador↔Executor** — o ponto central deste modelo;
2. aprova/mergeia MR de produção (o Orquestrador nunca aprova) — *quando houver deploy*;
3. dá a 2ª confirmação de escrita em produção — *quando houver deploy*;
4. aprova exceções de processo e ações irreversíveis.

## Executor-bridge: fluxo decisório padrão (código)

```
1. Orquestrador inspeciona o estado real e define a fatia + critérios de aceite.
2. Orquestrador abre a branch e consulta o roteamento (pesado/leve → modelo do Executor).
3. Orquestrador monta a ORDEM mínima e invoca:  {{EXECUTOR_CMD}} --model <tier> [--output-schema]
4. Executor CRITICA a ordem ativamente:
     ├─ concorda / ajuste menor que assume → escreve o código + devolve os 6 itens
     └─ DISCORDA materialmente → NÃO executa; devolve objeção + justificativas
            → Orquestrador APRESENTA o conflito (ordem × objeção, fiel) à Autoridade → Autoridade decide → vira nova ordem
5. Orquestrador AUDITA: re-roda build/lint/test, confere evidência.
     ├─ reprovado → devolve ao Executor com ajuste recomendado
     └─ aprovado → Orquestrador comita (materializa "auditei e aceito")
6. staging: Orquestrador autônomo (quando houver CI) · PRODUÇÃO: para → Autoridade (AA)
7. Branch promovida a staging E produção → Orquestrador limpa (local + remota).
```

> **Nada de relay humano na rotina:** o passo 3 é o Orquestrador chamando o Executor direto. A Autoridade só aparece em (4) discordância e (6) fronteira de produção.

## Governança: crítica do Executor antes do commit (ADR 0006)

Para **código**, a validação cruzada é estrutural (Executor escreve, Orquestrador audita). Para **governança**, o Orquestrador autora **e** comitaria — auto-aprovação. Fecha-se assim:

1. O Orquestrador **autora** a mudança e **invoca o Executor** com o pedido de crítica (diff + intenção + fronteiras).
2. O Executor devolve **crítica técnica** (riscos, incoerências, contradições, melhorias).
3. **Consenso → o Orquestrador comita.** **Discordância/impasse → o Orquestrador apresenta à Autoridade**, que decide (o Executor tem voz, não veto; a Autoridade pode dispensar a crítica para uma mudança específica).
4. Sem Executor disponível: a governança **aguarda** no pré-commit (salvo dispensa da Autoridade).

Escopo amplo: `.engrama/governance/*`, ADRs, `AGENTS.md`, seções de governança do `CLAUDE.md`. **Item 7:** análise de causa-raiz/veredito do Orquestrador em **superfície sensível** (fluxo principal, invariante, RBAC, segurança, arquitetura operacional — tipicamente nas páginas de gaps/ do seu projeto) também passa por crítica do Executor como **gate de uso** (não de commit): registrar o fato é livre; **usar** a análise exige a crítica. Estado em `critica_tecnica` no front matter.

## Computer-use / browser em duas fases (ADR 0007)

`mutating_ui_task` (dashboards/admin/infra/save/delete/config/deploys via UI) é do **Executor**, nunca cego: **Fase 1 reconhecimento read-only** → **Orquestrador aprova `approved_action_scope`** (alvo/estado-esperado/permitido/proibido/parada) → **Fase 2 execução** do exatamente-aprovado (para se a UI divergir). `read_only_lookup` fica fora — uma fase, livre.

## Regra de discordância técnica

Quando o Executor discorda: (1) explicita a objeção; (2) aponta o risco concreto e **qual gatilho de materialidade** atinge; (3) propõe alternativa; (4) **a decisão vai à Autoridade via Orquestrador** — não ao Orquestrador sozinho. O Orquestrador apresenta a objeção **fielmente**.

**O que é "discordância material" (4 gatilhos fechados):** (1) risco de perda de dados; (2) quebra do fluxo principal; (3) ação irreversível sem aprovação; (4) contradição séria com o estado real ou com a governança/alçada. (Com deploy: + contaminação staging/prod, deploy no ambiente errado.) Fora desses → `ajuste-menor`, o Executor assume e segue. **Quem marca a materialidade é o Executor** (com justificativa objetiva); **a Autoridade arbitra o mérito, não a existência** da objeção — o Orquestrador não pode descartá-la como "não-material".

**Override (decisão da Autoridade):** a Autoridade é a palavra final, mas para passar por cima de uma objeção material precisa de **2ª confirmação explícita** reconhecendo o gatilho específico (espelha produção intocável). A objeção fica **sempre logada**.

**Anti-loop:** se o mesmo conflito repetir após **2 rodadas** (`ordem → objeção → Autoridade → mesma ordem → mesma objeção`), só são permitidas 3 saídas: **waiver da Autoridade registrado**, **reformular a fatia**, **bloqueio formal** nas páginas de gaps/ do seu projeto. Sem 3ª rodada idêntica.

## Regra de conclusão

Uma tarefa **não** fecha porque o Executor disse que terminou, o diff parece ok, ou o pipeline ficou verde. Fecha quando o **Orquestrador** confirma, por evidência, que o estado real corresponde ao objetivo — e **só então comita**. O commit materializa "auditei e aceito".
