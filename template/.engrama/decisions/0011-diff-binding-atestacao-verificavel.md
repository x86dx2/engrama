---
type: decision
status: active
touches: [decisions/0006-governanca-nao-se-autoaprova, qa/criticas-do-executor, governance/modelo-operacional]
date: {{DATA}}
source_refs:
  - {{REPO_PATH}}/.engrama/scripts/critique-gate.sh
  - {{REPO_PATH}}/.engrama/scripts/engrama-diff-hash.sh
---

**A crítica registrada no ledger pode ser vinculada ao conteúdo exato do diff staged.** O objetivo é fechar o furo da branch inteira: uma crítica antiga não deve mais liberar automaticamente um diff novo quando houver prova verificável melhor disponível.

## Contexto
O gate do ADR [[decisions/0006-governanca-nao-se-autoaprova]] já impõe branch + categoria + veredito, mas isso ainda deixava dois vazamentos locais:
1. uma linha `confirmo` podia liberar **qualquer diff futuro** da mesma branch+categoria;
2. o ledger provava que houve um registro, mas **não** que esse registro cobria **este diff**.

Se o seu projeto mantiver um gap/plano de auditoria equivalente, ligue este ADR a essa página para registrar a origem da remediação.

## Decisão
1. Introduzir `engrama-diff-hash.sh` como **fonte única** do fingerprint do diff staged. O cálculo usa `git diff --cached --raw -z -- . ':(exclude).engrama/qa/criticas-do-executor.md'` e o passa por SHA-256.
2. Estender a gramática do ledger: o campo 4 (`ref`) continua livre, mas pode conter opcionalmente um token `sha256:<hex>`.
3. Quando o token `sha256:<hex>` estiver presente, o gate compara esse valor ao fingerprint atual:
   - **match forte**: a crítica conta para este diff;
   - **mismatch**: a crítica fica explicitamente vinculada a outro diff e não satisfaz o gate.
4. Entradas **sem** `sha256:` permanecem válidas no **modo legado**, por compatibilidade retroativa com o histórico e com projetos já instanciados.
5. Com `ENGRAMA_REQUIRE_DIFF_BIND=1`, o gate entra em **modo estrito**: só o **match forte** satisfaz. Este é o modo esperado para CI e outros pontos de enforcement opt-in.

## Alternativas consideradas
### Hash do patch textual
Rejeitado. O patch textual (`git diff`) é mais sensível a formatação e contexto do que o `--raw`, que ancora o fingerprint nos blob SHAs do diff staged.

### Assinatura criptográfica do crítico
É o teto ideal de atestação, mas foi rejeitada por ora porque o seu executor-bridge atual pode não expor uma identidade/chave verificável do crítico. Sem isso, a assinatura vira promessa vazia.

## Consequências
- Uma crítica com `sha256` passa a valer para **um diff específico**, não para a branch inteira.
- Editar um arquivo não-ledger após a crítica invalida o binding e exige nova crítica (ou novo waiver).
- O caminho legado continua funcionando por padrão, para não quebrar o histórico existente nem as suítes antigas.
- O modo estrito permite endurecer CI/enforcement sem forçar uma migração big-bang do ledger.
- **Teto honesto:** este mecanismo prova que a crítica registrada cobre **este diff**. Ele **não prova independência de identidade do crítico**. Para isso, seria necessária uma identidade verificável externa ao conteúdo do repo (assinatura/chave/atestado do executor-bridge).

## Relações
- Complementa [[decisions/0006-governanca-nao-se-autoaprova]]: o ledger continua sendo o artefato do gate, mas agora pode carregar prova verificável melhor do que a convenção branch+categoria.
- Se o seu projeto usar um gap/plano de auditoria equivalente, ligue-o aqui para registrar a origem da remediação.
