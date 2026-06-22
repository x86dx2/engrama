---
type: domain
status: active
touches: [decisions/0001-governanca-tres-papeis, decisions/0004-executor-critica-ativa-discordancia-escala-a-autoridade, decisions/0006-governanca-nao-se-autoaprova, decisions/0011-diff-binding-atestacao-verificavel, qa/criticas-do-executor]
date: 2026-06-21
source_refs:
  - .engrama/decisions/0001-governanca-tres-papeis.md
  - .engrama/decisions/0004-executor-critica-ativa-discordancia-escala-a-autoridade.md
  - .engrama/decisions/0006-governanca-nao-se-autoaprova.md
  - .engrama/decisions/0011-diff-binding-atestacao-verificavel.md
  - .engrama/qa/criticas-do-executor.md
  - .engrama/scripts/critique-gate.sh
reconcilia: ADD
---

**Validação cruzada estrutural** é o padrão pelo qual o Engrama separa quem **escreve**, quem **critica/audita** e quem **arbitra**. A origem conceitual vem do debate de AI-memory sobre validação de fatos, mas aqui a implementação é deliberadamente mais forte: não é "o mesmo agente pensando duas vezes", e sim **papéis/processos distintos** com gate mecânico e rastro versionado.

## Contraste útil

Sistemas como mem0 costumam usar o **mesmo modelo** para extrair candidatos e depois validar conflito/duplicata. Isso ajuda a manter coerência local, mas deixa um ponto cego: escritor e auditor compartilham o mesmo processo epistemológico.

O Engrama endurece essa fronteira:
- [[decisions/0001-governanca-tres-papeis]] separa estruturalmente **Orquestrador**, **Executor** e **Autoridade**.
- [[decisions/0004-executor-critica-ativa-discordancia-escala-a-autoridade]] transforma o Executor em **freio ativo**; objeção material não volta para o Orquestrador como mera sugestão.
- [[decisions/0006-governanca-nao-se-autoaprova]] exige que governança e superfícies sensíveis passem pela crítica registrada em [[qa/criticas-do-executor]] antes do commit.
- [[decisions/0011-diff-binding-atestacao-verificavel]] liga essa crítica ao **diff exato** quando há `sha256`, evitando que um "confirmo" antigo libere qualquer mudança futura da branch.

## Implementação superior no Engrama

O ganho não está em "mais inteligência", e sim em **mais separação de funções**:

1. **Escritor ≠ auditor.**
   - O Executor escreve a fatia.
   - O Orquestrador audita e reexecuta os gates.
   - A Autoridade arbitra a discordância material.
2. **Há gate mecânico, não só disciplina verbal.**
   - `.engrama/scripts/critique-gate.sh` cobra branch + categoria + veredito no ledger.
   - O ledger [[qa/criticas-do-executor]] torna a crítica um artefato verificável do processo.
3. **Há vínculo opcional ao conteúdo do diff.**
   - O `sha256` de [[decisions/0011-diff-binding-atestacao-verificavel]] prova que a crítica cobria **este diff**, não um diff qualquer.
4. **Há enforcement server-side no merge.**
   - O modelo assume CI/reexecução do gate como freio vinculante no PR, em vez de confiar só no hook local.

O resultado prático é melhor que "extrair e validar com o mesmo modelo": a crítica deixa de ser autocorrelação e vira **validação cruzada estrutural**.

## O que este padrão prova

Ele prova bem **cobertura de processo**:
- houve um escritor distinto;
- houve um auditor/gate separado;
- houve um rastro versionado;
- em modo forte, a crítica cobria o diff em questão.

## Teto honesto

Este padrão **não** prova a identidade independente do crítico. O próprio ADR [[decisions/0011-diff-binding-atestacao-verificavel]] documenta o furo R1: o gate prova melhor o **que** foi coberto (`sha256`), mas não resolve definitivamente **quem** escreveu `confirmo`. A independência aqui é **estrutural**, não criptograficamente atestada.

Por isso, o claim correto é:
- o Engrama entrega uma separação escritor≠auditor **melhor que mem0 no contraste citado**;
- o gate prova **cobertura**;
- a **identidade** do crítico continua um teto aberto.

Ver também [[domain/escopo-e-identidade]] e [[domain/ponto-de-vista-e-representacao]].
