---
type: governance
status: active
touches: [memory/governance/papeis-e-alcadas, memory/governance/cadeia-de-comando, memory/governance/modelo-operacional, memory/decisions/0003-executor-bridge-orquestrador-invoca-executor, memory/decisions/0004-executor-critica-ativa-discordancia-escala-a-autoridade]
date: 2026-06-20
source_refs:
  - CLAUDE.md
---

Protocolos de **continuidade operacional**: como abrir, trabalhar e encerrar uma sessão; o handoff Orquestrador↔Executor pelo executor-bridge; e os pacotes mínimos que tornam a retomada independente de prompt longo.

## Protocolo de abertura de sessão

1. Ler a ordem mínima de [[memory/governance/index]] (papéis → cadeia → modelo → continuidade → ADRs → topo do [[log]]).
2. Identificar **seu papel** ([[memory/governance/papeis-e-alcadas]]) e o que a alçada permite.
3. Ler [[memory/project/bootstrap-do-projeto]] e verificar se o bootstrap do projeto está concluído.
4. Apurar o **estado factual atual** pelo topo do [[log]].
5. Confirmar branch atual, commit base e se há trabalho não-commitado.

## Handshake obrigatório (primeiro retorno útil)

O agente declara: (1) papel assumido; (2) alçada; (3) estado factual lido no topo do [[log]]; (4) próximo passo seguro dentro da alçada; (5) o que depende de aprovação da Autoridade. **Sem o handshake, a sessão não está corretamente aberta.**

Se [[memory/project/bootstrap-do-projeto]] estiver `proposed` ou com **campos pendentes**, o próximo passo seguro do Orquestrador é **entrevistar a Autoridade e concluir o bootstrap**, não avançar no produto.

## Ordem mínima do Orquestrador para o Executor (executor-bridge)

Toda invocação `codex exec` carrega, no mínimo:
1. objetivo da fatia;
2. estado factual conhecido;
3. escopo da execução;
4. restrições e fronteiras (o que NÃO tocar);
5. critérios de aceite;
6. validações esperadas;
7. riscos já conhecidos;
8. o que depende de aprovação da Autoridade;
9. próximo passo seguro após a execução;
10. **modelo/tier** escolhido (ex.: um tier pesado e um leve do adaptador configurado; confirme os ids reais) e por quê.

## Resposta mínima obrigatória do Executor

1. **Leitura da ordem** — o que entendeu.
2. **Crítica técnica** — riscos, lacunas, inconsistências, pré-condições. **Vem ANTES da execução** e pode bloqueá-la.
3. **Veredito sobre a ordem** — `concordo` | `ajuste-menor` (assumo e sigo) | `discordo` (não executo; justificativas).
4. **Execução** — o que de fato fez (se concordou/ajustou).
5. **Evidências** — comandos, saídas, diffs, estados verificados.
6. **Pendências e bloqueios** — o que ficou aberto, o que depende de aprovação, próximo passo.

> Se o veredito é `discordo`, o Executor **não executa**; os itens 4–5 ficam vazios e o Orquestrador leva a objeção à Autoridade.

## Quando o Executor deve parar e devolver objeção

Risco material de: perda de dados; quebra do fluxo principal; violação de governança/alçada; execução irreversível sem aprovação; contradição séria entre estado real e instrução; (quando houver deploy) contaminação staging/prod ou deploy no ambiente errado. → objeção fundamentada + caminho mais seguro; decisão **vai à Autoridade via Orquestrador**.

## Protocolo de trabalho

1. Definir a **menor fatia** com começo e fim verificáveis.
2. Validar coerência com .engrama/ADRs **antes** de mudar; contradição → resolver explicitamente.
3. **Se a fatia é código:** montar a ordem e invocar o Executor (executor-bridge). **Se é governança:** autorar e **submeter à crítica do Executor antes do commit** (ADR 0006).
4. Atualizar o engrama **antes** do commit não-trivial.
5. Auditar como QA: **re-executar** os gates e registrar a saída real.
6. Antes de encerrar, declarar o **destino de cada commit** (MR / estacionamento formal).

## Protocolo de encerramento

1. Engrama atualizado (log/gap/ADR conforme o que mudou).
2. Árvore git em estado declarado (branch, commits, stashes).
3. Declarar se há commit local sem MR e por quê está estacionado.
4. Entregar a devolutiva com o **pacote mínimo de handoff** (abaixo).
5. Marcar o que ficou pendente de aprovação e o **próximo passo seguro**.

## Pacote mínimo de handoff

1. Fase do projeto · 2. Objetivo da sessão · 3. Branch atual · 4. Commit base e final · 5. Destino do commit · 6. Arquivos alterados · 7. ADRs/logs relevantes · 8. Ambiente(s) tocado(s) · 9. Comandos executados · 10. Validações (saída real) · 11. Riscos abertos · 12. Bloqueios · 13. Próximo passo seguro · 14. O que depende de aprovação da Autoridade · 15. Discordâncias do Executor pendentes de arbitragem.

## Devolutiva mínima do Orquestrador para a Autoridade

- Veredito técnico
- **Veredito de qualidade (QA):** saída real dos gates re-executados + estado das métricas
- Riscos remanescentes
- Pronto ou bloqueado
- Ações que exigem autorização da Autoridade
- **Discordâncias Executor↔Orquestrador a arbitrar** (objeção fiel do Executor + leitura do Orquestrador)

## Memória quente vs fria

Inspirado na distinção de working vs long-term representation do Honcho, o Engrama separa duas camadas operacionais:

- **Memória quente** = o checkpoint vivo no topo de [[log]] e o contexto factual recompilável da sessão atual. Ela muda por append e serve para retomada rápida.
- **Memória fria** = `memory/governance/`, `memory/decisions/`, `memory/specs/` e as páginas duráveis de domínio do projeto. Ela muda devagar e por revisão explícita.

O Engrama **não** faz decay, expiry ou TTL automático em nenhuma das duas camadas. O que sai da memória quente e entra na fria passa por **consolidação manual**, normalmente via ADR, spec ou página de domínio; o que perde utilidade no topo do `log.md` some só porque novos fatos append-only empurram o checkpoint adiante.

## Checkpoint vivo (estado de retomada)

O **estado vivo** (onde o trabalho parou, próximo passo) mora no **topo do [[log]]** — padrão recomendado. É versionado e portável (sobrevive a clone), centralizando memória factual e ponto-de-retomada num lugar só. O `log.md` permanece append-only; o item mais recente no topo **é** o checkpoint. (Trade-off aceito: mistura registro factual com estado-de-retomada — escolha por simplicidade e fonte única.)

> **Template:** este é o **padrão recomendado** (checkpoint vivo no topo do `log.md`), mas a Autoridade do seu projeto pode decidir de outra forma — por exemplo, manter o ponto-de-retomada num arquivo separado (`STATE.md`/board externo) se preferir não misturar registro factual com estado-de-retomada. Decida e registre a escolha num ADR do seu projeto.

## Checklist mínimo de continuidade

- [ ] Li o topo do [[log]] e sei o estado factual.
- [ ] Sei meu papel e minha alçada; declarei no primeiro retorno.
- [ ] Sei branch, commit base, stash/pendências.
- [ ] **Código → invoco o Executor** (não escrevo fatia eu mesmo).
- [ ] **Discordância do Executor → apresento à Autoridade** (não faço overrule).
- [ ] **QA:** re-executei os gates e anexei a saída real antes de comitar.
- [ ] **Governança → crítica do Executor antes do commit** (consenso, ou escala o impasse).
- [ ] **Subagente nunca escreve código de fatia.**
- [ ] **Transparência do bridge:** colei para a Autoridade a **ordem enviada ao Executor (verbatim)** e a **resposta dele na íntegra** (ADR 0003).
