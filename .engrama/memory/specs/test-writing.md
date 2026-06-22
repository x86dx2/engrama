---
type: spec
status: active
touches: [memory/specs/README, memory/specs/executor, memory/decisions/0005-orquestrador-qa-reexecucao-e-metricas]
date: 2026-06-20
source_refs:
  - .engrama/memory/specs/test-writing.md
---

Playbook de **escrita de teste** (aplicado pelo Executor sob spec do Orquestrador). É o **"como"** da disciplina de teste; o **"porquê/normativo"** (QA, re-execução, aceite) vive em [[memory/decisions/0005-orquestrador-qa-reexecucao-e-metricas]]. Esta página é **agnóstica de stack**: preserva a filosofia reaproveitável e deixa as convenções concretas do harness para você preencher.

## Princípio: a filosofia, não a ferramenta

Independente do framework, quatro invariantes valem para qualquer projeto deste pack:

1. **RED-first** — código novo nasce com teste que **falha pelo motivo certo** (a lógica ainda não existe), não por import/config quebrado. Vira verde na implementação.
2. **Golden/contract** — caracterizar o comportamento **REAL** de uma referência (sistema legado, contrato de API, baseline), não a spec idealizada.
3. **Cobertura em camadas** — unit/service (lógica), contract (fronteira/HTTP), e2e (fluxo de ponta a ponta). Cada camada cobre o que a de baixo não cobre.
4. **"Verde verificado"** — o verde do Executor **não basta**; o Orquestrador re-executa e anexa a saída real (ADR 0005).

## Stack e estrutura

> Template: preencha as convenções do harness do seu projeto. O pack é **agnóstico de stack** — defina o runner concreto, os caminhos e os comandos sem alterar a filosofia das quatro camadas acima.

- **Runner de unit/service/contract** e **runner de e2e** do seu projeto (`Markdown + Bash + Git hooks + Claude Code settings`). App no diretório-raiz do app.
- Estrutura de pastas de teste (ex.: `tests/{unit,service,contract}/` + `e2e/`) conforme o layout real.
- **Config do runner:** desligar paralelismo de arquivos quando o estado compartilhado (rate limit, sessão, banco) puder gerar **falso-verde** entre arquivos; ampliar `testTimeout`/`hookTimeout` o suficiente para evitar timeout flaky.

> Exemplo (troque pelo do seu projeto): um runner de unit/contract com `fileParallelism: false` + `testTimeout/hookTimeout: 30000`, e um runner de e2e separado para o navegador. O número e o nome importam menos que o **motivo**: evitar que arquivos rodando em paralelo poluam o estado um do outro e produzam verde falso.

## Camadas e estado esperado

- **Unit/service de código novo (RED test-first):** stub do módulo lançando um erro sentinela (ex.: `new Error("NOT_IMPLEMENTED")`); o teste falha **por esse sentinela** — não por import/config. Vira verde quando a implementação chega.
- **Contract/e2e (golden):** rodam contra uma **referência isolada** e devem passar **VERDE** (golden); depois são re-apontados ao app novo (ex.: via variável de ambiente de base URL).

> Template: defina qual é a sua "referência golden" (sistema legado, mock de contrato, baseline gravado). Se este modelo for portado de um projeto anterior, a referência pode ser o sistema antigo rodando isolado num host/porta dedicada (`N/A (sem servidor local)`) — caracterize o comportamento real dele, não o desejado.

## Harness HTTP (contract)

Princípios de um harness de contract robusto contra rate limit e poluição de estado (genéricos; adapte ao seu cliente):

- **Login cacheado por credencial** (escopo de módulo) — minimizar logins, já que rate limit costuma contar falhas por IP em janela de tempo (sucesso normalmente limpa o contador).
- **IP randomizado por processo** + **IP dedicado para casos negativos** (ex.: senha errada) — não poluir o IP do login válido com tentativas que falham de propósito.
- **Retry em resposta de throttle** (ex.: HTTP 429) respeitando o header de backoff (ex.: `Retry-After`).
- **Override de tempo de teste fora de produção** (ex.: header de "agora") quando a lógica depende de relógio.

> Exemplo (troque pelo do seu projeto): um arquivo de harness compartilhado (ex.: `tests/contract/http.ts`) que centraliza login cacheado, randomização de IP via header de origem, retry em 429 e um header de tempo controlado. O ponto não é o arquivo específico, mas isolar essas preocupações fora dos testes individuais.

## Regras de cobertura

- Cada regra de negócio: **≥1 caso feliz + ≥1 de bloqueio**.
- Cada rota mutável: teste de **autorização** (permitido + negado).
- **Caracterizar o comportamento REAL** da referência (não a spec idealizada); divergência suspeita → registrar como gap nas páginas de divergências/gaps do seu projeto.
- IDs estáveis da matriz de cobertura (ex.: `COV-*`) na rastreabilidade, se o projeto mantiver uma.

## Aceite (o Orquestrador re-executa — ADR 0005)

- **Contract:** suíte de contract **3× verdes** (idempotência forte, sem throttle/timeout intermitente).
- **E2E:** suíte golden verde estável (sem vermelho intermitente; flaky → skip com motivo registrado).
- **"Verde do Executor ≠ verde verificado":** o Orquestrador re-roda e anexa a saída real (ADR 0005).

> Template: substitua pelos comandos concretos do seu runner (ex.: o alvo que roda só os testes de contract; o alvo que roda a suíte golden de e2e). Mantenha a regra das **3× verdes** para contract e do **verde estável** para e2e — são a barra de aceite, não detalhe de ferramenta.

## Credenciais seed

> Template: documente aqui as credenciais/seed do **ambiente de teste isolado** do seu projeto (papéis × usuários × senha de seed), nunca de produção. Não commitar secrets reais — só credenciais de seed descartáveis do ambiente de teste.

> Exemplo (troque pelo do seu projeto): um conjunto de usuários seed cobrindo cada papel de RBAC (ex.: um admin, um operador de perfil A, um operador de perfil B), todos com a mesma senha de seed conhecida, criados no ambiente isolado de teste.
