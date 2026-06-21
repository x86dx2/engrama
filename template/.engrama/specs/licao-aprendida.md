---
type: spec
status: active
touches: [governance/modelo-operacional, decisions/0006-governanca-nao-se-autoaprova, qa/criticas-do-executor, specs/README]
date: {{DATA}}
source_refs:
  - {{REPO_PATH}}/.engrama/qa/criticas-do-executor.md
  - {{REPO_PATH}}/.engrama/log.md
---

Playbook do **loop falha→regra**: como toda falha relevante vira uma **regra durável** (gate, lint, teste, ADR ou princípio), para que a memória institucional **componha** em vez de só acumular. Operacionaliza o princípio 12 de [[governance/modelo-operacional]] (honestidade de claims).

## Princípio

**A falha que não vira regra tende a se repetir.** Registrar o fato (no `log.md`/ledger) é necessário, mas não suficiente: sem um freio mecânico, a disciplina de memória falha. Uma lição está **fechada** quando tem um **destino durável** que **reduz a reincidência** e, idealmente, a torna **detectável por teste/CI** — não que a elimine por decreto.

## Gatilhos (o que vira lição)

- **Objeção material do Executor** (veredito `discordo`). *(Um `ajuste-menor` recorrente sobre o mesmo tema também sinaliza regra faltando — ver o gatilho "mesmo erro 2×".)*
- **Auditoria reprovada** (falso-verde, flakiness, regressão pega tarde).
- **Overclaim ou contradição** detectada entre prosa e código (princípio 12).
- **Mesmo erro 2×** (sinal forte de regra faltando — espelha o anti-loop do [[decisions/0004-executor-critica-ativa-discordancia-escala-a-autoridade]]).
- **Referência quebrada / drift** pega por linter ou teste de contrato.

## Fluxo

1. **Registrar** o fato onde ele já mora (entrada de `log.md` + ledger se houver crítica). Isso é livre e imediato.
2. **Triar o destino durável** — escolher pelo menos um, do mais forte ao mais fraco:
   - **(a) Regra de gate** — novo caso em `classify()`/parser de `.engrama/scripts/critique-gate.sh` **+ teste** (superfície sensível).
   - **(b) Regra de lint** — nova checagem no linter **+ teste** (integridade de doc/estrutura).
   - **(c) Teste** — caso de regressão que fixa o comportamento correto (RED→GREEN; ver [[specs/test-writing]]).
   - **(d) ADR** — quando a lição muda uma decisão/política (`decisions/NNNN`).
   - **(e) Princípio/spec** — quando é norma transversal (`governance/` ou um spec).
3. **Fechar** a lição: o commit que adiciona a regra **referencia o fato de origem** (na mensagem e/ou no `log.md`). Quando houve crítica, o ledger já registra o fato — mas **o destino da lição vive no commit/log, não num campo do ledger** (o ledger tem gramática fixa de 4 campos; ver [[qa/criticas-do-executor]]).

## Anti-cerimônia

Nem toda falha exige todos os destinos. **Trivial mecânico** (typo, link quebrado já corrigido) fecha só com o conserto + a checagem que o pegaria de novo. Reserve ADR/princípio para o que **muda política**. O objetivo é uma rede sob o que importa, não burocracia.

> Template: registre aqui, conforme o projeto avança, os exemplos reais de lições que viraram regra (objeção → gate/teste; overclaim → princípio; drift → checagem de CI). É o que torna esta página **prova viva** de que a memória compõe.

> Em uma frase: cada falha é matéria-prima de uma regra. O Engrama fica mais valioso a cada incidente — não apesar deles.
