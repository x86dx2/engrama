# Governance Pack — modelo portável de governança entre agentes (padrão LLM-Wiki)

Este diretório é um **template auto-contido** para replicar, em **qualquer projeto novo**, o modelo de governança entre agentes que amadurecemos no Ruflos — estruturado no **mesmo padrão do "LLM Wiki" de Andrej Karpathy** ([gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)).

- **`template/`** — a árvore que você **copia para a raiz** do projeto novo (gates + `.engrama/`).
- **`INSTANTIATE.md`** — passo a passo de adoção (placeholders, ativação do gate, ritual de bootstrap).
- **este `README.md`** — a análise do padrão e como o pack o encarna.

---

## 1. A ideia do LLM Wiki (análise do gist)

O gist propõe uma **alternativa ao RAG**. No RAG clássico, a cada pergunta você **recupera documentos crus** e o modelo re-deriva a resposta do zero. Karpathy inverte: um LLM **constrói e mantém incrementalmente** um wiki em markdown, **persistente e interligado**, onde as **conexões e sínteses já estão compiladas** — não são reconstruídas a cada query. O wiki é um **artefato que compõe** (compounding): cada ingestão o deixa mais valioso.

**Três camadas:**

| Camada | O que é | Mutabilidade |
|---|---|---|
| **Raw sources** | a coleção curada de fontes (docs, artigos, dados) | imutável |
| **The wiki** | diretório de markdown mantido pelo LLM: resumos, páginas de entidade, páginas de conceito, com cross-links | mantido pelo LLM |
| **The schema** | as instruções que definem como o wiki é estruturado e como o LLM o mantém | config |

**Três operações:**

- **Ingest** — chega uma fonte nova; o LLM lê, extrai, integra em ~10–15 páginas, atualiza cross-references e mantém a consistência.
- **Query** — você pergunta; o LLM busca as páginas certas e sintetiza com citações. Análises valiosas viram páginas novas.
- **Lint** — varredura periódica de saúde: contradições, afirmações obsoletas, páginas órfãs, cross-links faltando.

**Por que funciona** (o argumento central): manter uma base de conhecimento é **trabalho tedioso de bookkeeping** — atualizar referências, anotar contradições, manter coerência. *"Humanos abandonam wikis porque o custo de manutenção cresce mais rápido que o valor. LLMs não se entediam"* e tocam vários arquivos de uma vez. O humano **curadora as fontes e faz perguntas**; o LLM **faz a manutenção**. É o **Memex de Vannevar Bush** — conhecimento pessoal, curado, com conexões valiosas — resolvendo justamente o problema de manutenção que Bush não conseguiu resolver.

---

## 2. O insight deste pack: governança **é** um LLM Wiki

A virada aqui é aplicar o padrão não a uma base de conhecimento de fontes externas, mas à **própria governança** — às regras de como os agentes colaboram. O "conhecimento" que compõe é o **modelo operacional**: papéis, alçadas, decisões, incidentes e críticas. O resultado é uma governança **versionada, portável e auto-mantida**, que sobrevive a sessão, a clone novo e à troca de quem ocupa cada papel.

O mapeamento é direto:

| Camada do LLM Wiki | No governance pack |
|---|---|
| **Raw sources** (imutável) | `.engrama/log.md` (factual, append-only) + o **ledger de críticas** (`.engrama/qa/criticas-do-executor.md`) — o registro do que aconteceu/foi decidido/foi criticado |
| **The wiki** (mantido pelo LLM) | `.engrama/governance/*` + `.engrama/decisions/*` (ADRs) + `.engrama/specs/*` + `.engrama/index.md` — o modelo normativo interligado por `[[wikilinks]]` |
| **The schema** (config) | `.engrama/CLAUDE.md` (o schema do Engrama) **+** `CLAUDE.md` / `AGENTS.md` (os **gates** que dizem ao agente como ler e manter o Engrama) |

| Operação do LLM Wiki | No governance pack |
|---|---|
| **Ingest** | uma decisão/incidente/crítica nova → atualiza ADR/governança + `.engrama/log.md` + cross-links (workflow em `.engrama/CLAUDE.md`) |
| **Query** | **abertura de sessão**: ler gate → governança → topo do `.engrama/log.md`; responder "qual é meu papel / qual o estado / próximo passo seguro" (o *handshake* obrigatório) |
| **Lint** | a varredura de saúde do Engrama **+** o **gate mecânico de crítica** (`.engrama/scripts/critique-gate.sh`) — um lint **contínuo e imposto** sobre superfície sensível, que bloqueia o commit sem a crítica registrada |

> Em uma frase: o Karpathy resolve *"humanos abandonam wikis porque manter cansa"*; este pack aplica isso à governança — **o modelo operacional não apodrece** porque o agente o mantém, e o **gate** lembra/impõe a crítica no caminho cooperativo do commit.

> **Honestidade sobre o enforcement (o que o gate é e o que não é).** O `critique-gate.sh` é um **freio cooperativo local**: bloqueia o commit pelo hook do git **e** pelo `PreToolUse` do harness do Orquestrador. Mas um hook local é **deliberadamente burlável** — `git commit --no-verify`, `git -c core.hooksPath=/dev/null`, ou um commit fora desse harness passam por cima dele. A garantia vinculante de "escritor ≠ auditor" exige **enforcement server-side**. A CI ([.github/workflows/ci.yml](.github/workflows/ci.yml)) **reexecuta o gate contra o diff do PR** via [critique-gate-ci.sh](critique-gate-ci.sh) — o controle passa a existir num lugar **não-burlável pelo autor** (reusa a mesma `classify()` + parsing do ledger por campo). Falta **um** passo, que é configuração do repositório e não código: marcar esse check como **required** no *branch protection* para ele **bloquear o merge**. Hoje, portanto: hook local = atrito útil + registro; **CI reexecuta o gate**; o que falta para o enforcement ser vinculante é o *required check* ligado (config de repo). O furo **R1** (auto-aprovação local) fica **mitigado server-side** quando o required check estiver ativo. O gate garante que a crítica esteja **registrada** — **não** que um agente independente de fato a tenha produzido (ver [plano de remediação](.engrama/gaps/auditoria-e-plano-de-remediacao.md)).

---

## 3. O modelo de governança em uma página

**Tríade de papéis (por função, não por vendor — o mapeamento é mutável):**

- **Orquestrador / Auditor / QA / Arquiteto** — dirige, decompõe a menor fatia segura, **invoca o Executor**, audita (re-executa os gates), é dono do git, emite o veredito. **Não escreve código de fatia.**
- **Executor Crítico** — **escreve o código** da ordem; **nunca cego**: critica ativamente antes; discordância material → **não executa**, escala (via Orquestrador) à Autoridade.
- **Autoridade de Mudança** — aprova o sensível/irreversível; **arbitra toda discordância** Orquestrador↔Executor; dá a 2ª confirmação de produção.

**Os pilares (detalhe nos ADRs 0001–0010):**

1. **Validação cruzada estrutural** — quem escreve ≠ quem audita ≠ quem aprova. O executor não se autoaprova.
2. **Executor-bridge** — o Orquestrador **invoca o Executor diretamente** (`{{EXECUTOR_CMD}}`), sem relay humano de rotina. O roteamento escolhe o **modelo** do Executor, não *se* ele participa: **não há caminho de código sem o Executor**.
3. **Executor é freio ativo** — critica toda ordem; objeção material escala à Autoridade. O Orquestrador **não tem overrule**.
4. **Governança não se autoaprova** — toda edição de governança passa por **crítica independente do Executor antes do commit**, imposta por **gate mecânico** (não depende de memória).
5. **Auditoria sempre** — "verde reportado ≠ verde verificado"; o commit materializa *"auditei e aceito"*.
6. **Subagentes só na lane do Orquestrador** (auditoria/pesquisa) — **nunca** escrevem código de fatia.
7. **Produção intocável** — escrita em prod = ordem + 2ª confirmação (inativo até existir deploy).

---

## 4. O que tem no pack

```
template/
├── CLAUDE.md                      # gate do Orquestrador (entry-point)
├── AGENTS.md                      # gate neutro (qualquer agente)
└── .engrama/                      # memória institucional + scripts (o "Engrama")
    ├── CLAUDE.md                  # SCHEMA do Engrama (frontmatter, ingest/query/lint)
    ├── index.md                   # catálogo navegável
    ├── log.md                     # factual append-only (+ checkpoint vivo no topo)
    ├── governance/                # papéis, alçadas, cadeia de comando, continuidade
    │   ├── index.md
    │   ├── papeis-e-alcadas.md
    │   ├── cadeia-de-comando.md
    │   ├── modelo-operacional.md
    │   └── continuidade-de-sessao.md
    ├── decisions/                 # ADRs de PROCESSO (0001–0010) — o "porquê"
    │   ├── 0001-governanca-tres-papeis.md
    │   ├── … (0002–0009)
    │   └── 0010-roteamento-modelo-effort-do-executor.md
    ├── specs/                     # playbooks operacionais — o "como"
    │   ├── README.md
    │   ├── orquestrador.md · executor.md · executor-order.md · commit.md
    │   └── test-writing.md · infra-runbook.md   (esqueletos por-stack)
    ├── qa/
    │   └── criticas-do-executor.md   # ledger de críticas (lido pelo gate)
    ├── scripts/
    │   ├── critique-gate.sh       # gate mecânico (bloqueia commit sem crítica)
    │   └── critique-gate-hook.sh  # wrapper PreToolUse do harness
    └── githooks/pre-commit        # ativa o gate de crítica no git
```

> Os ADRs de **domínio/stack/sequenciamento** do projeto original (stack, ordem de migração) **não entram** no template — são específicos. No projeto novo eles nascem a partir de `0011+`, ao lado das pastas `domain/`, `roadmap/` e `gaps/` que você cria conforme o trabalho avança.

---

## 5. Como usar

Dois caminhos:

- **Auto-instalação pelo agente (recomendado):** rode o bootstrap do repo-fonte apontando para o projeto novo: `bash /caminho/do/engrama/bootstrap.sh /caminho/do/projeto-novo`. O **[INSTALL.md](INSTALL.md)** é o playbook imperativo: ele usa os defaults padrão do pack herdados do `Ruflos`, infere o que der do repo-alvo, instala `CLAUDE.md`/`AGENTS.md`/`.engrama/`/`.claude/settings.json` na raiz e, no **primeiro startup**, força o Orquestrador a entrevistar a Autoridade para fechar finalidade, stack, comandos e superfícies sensíveis do projeto.
- **Manual (referência):** **[INSTANTIATE.md](INSTANTIATE.md)** — os mesmos passos feitos à mão, com o glossário completo dos 12 placeholders.

Em ambos vale o **ritual de bootstrap** (ADR 0006): a governança se aplica a si mesma — o Engrama inicial vai à crítica do Executor e à aprovação da Autoridade antes do 1º commit.
