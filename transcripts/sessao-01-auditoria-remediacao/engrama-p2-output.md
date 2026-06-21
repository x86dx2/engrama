1. **Leitura da ordem**

Entendi a fatia como Executor Crítico T4 na branch `remediacao/p2-sync-template`:  
A) propagar para `template/` toda a lógica endurecida do gate da raiz, preservando só placeholders e o `classify()` universal do template;  
B) criar o gerador idempotente `sync-template.sh` na raiz, sem reverse-sub cega em prosa;  
C) criar `tests/contract/sync.test.sh` para detectar drift lógico, hook divergente e a referência fantasma a `sync-template.sh`.

Estado factual lido no topo do log: a raiz já tinha R2/R5, R3/R4 e hook fail-closed corrigidos; o próximo passo seguro registrado era exatamente P2, sincronizar raiz↔template e resolver `sync-template.sh`.

2. **Crítica técnica antes de executar**

A ordem estava correta. O único cuidado material era a mecânica da sincronização: fazer replace textual amplo no gate do template seria frágil e poderia manter drift ou quebrar a ordem do script. O caminho seguro é composição por seções: `prefixo da raiz + vars placeholder do template + lógica comum da raiz + classify do template + cauda da raiz`, e limitar o escopo do sincronizador a arquivos mecânicos.

Também tratei `sync-template.sh` como fonte operacional, mas sem tocar prosa normativa, `install.sh`, `bootstrap.sh` ou as suítes existentes, como pedido.

3. **Veredito**

`concordo`

4. **Execução**

Criei [sync-template.sh](/Users/x86/git-projects/engrama/sync-template.sh:1) para sincronizar os scripts do template a partir da raiz canônica, com extração por seções da lógica da raiz e reaplicação do bloco de configuração do template. Ele imprime `synced:`/`unchanged:` e é idempotente.

Criei [tests/contract/sync.test.sh](/Users/x86/git-projects/engrama/tests/contract/sync.test.sh:1) para comparar a lógica raiz/template excluindo vars/classify, garantir hook idêntico, validar a existência de `sync-template.sh` e travar placeholders + exemplos comentados do template.

Rodei o sincronizador e regenerei [template/.engrama/scripts/critique-gate.sh](/Users/x86/git-projects/engrama/template/.engrama/scripts/critique-gate.sh:1) e [template/.engrama/scripts/critique-gate-hook.sh](/Users/x86/git-projects/engrama/template/.engrama/scripts/critique-gate-hook.sh:1). Não toquei prosa de governança, `bootstrap.sh`, `install.sh` nem as suítes existentes.

5. **Evidências**

```text
$ grep -c 'is_ok_verdict' template/.engrama/scripts/critique-gate.sh
2
```

```text
$ grep -n -- 'git diff --cached --name-only -z\|HEAD destacado (detached HEAD)\|if \[ -z "\$BRANCH" \]' template/.engrama/scripts/critique-gate.sh
104:done < <(git diff --cached --name-only -z 2>/dev/null)
109:if [ -z "$BRANCH" ]; then
114:    echo "HEAD destacado (detached HEAD) em mudança sensível."
```

```text
$ diff template/.engrama/scripts/critique-gate-hook.sh .engrama/scripts/critique-gate-hook.sh
<sem saída>
```

```text
$ grep -n -- '{{EXECUTOR_CMD}}\|{{MODELO_CRITICA}}\|src/server/services/agreements\.\*\|src/server/permissions\.\*\|src/server/auth\.\*\|migrations/\*' template/.engrama/scripts/critique-gate.sh
24:EXECUTOR_CMD="{{EXECUTOR_CMD}}"            # ex.: "codex exec"
25:CRITIQUE_MODEL="{{MODELO_CRITICA}}"        # ex.: "gpt-5.5"
90:    # src/server/services/agreements.*|src/server/services/ledger.*)    addcat financial ;;
92:    # src/server/permissions.*|src/server/services/users.*)             addcat rbac ;;
94:    # src/server/auth.*|src/app/api/*/auth/*)                           addcat auth ;;
96:    # migrations/*)                                                     addcat schema ;;
```

```text
$ bash sync-template.sh
unchanged: template/.engrama/scripts/critique-gate.sh
unchanged: template/.engrama/scripts/critique-gate-hook.sh

$ git diff --stat -- template/
 template/.engrama/scripts/critique-gate-hook.sh |  66 +++++++++---
 template/.engrama/scripts/critique-gate.sh      | 127 +++++++++++++++++++-----
 2 files changed, 155 insertions(+), 38 deletions(-)

$ bash sync-template.sh
unchanged: template/.engrama/scripts/critique-gate.sh
unchanged: template/.engrama/scripts/critique-gate-hook.sh

IDEMPOTENT_AFTER_PATCH=1
```

```text
$ bash bootstrap.sh /private/tmp/eg-smoke-13535
BOOTSTRAP_RC=0
IS_OK_VERDICT_COUNT=2
PLACEHOLDER_COUNT=0
```

```text
$ bash tests/run.sh
==================== critique-gate.test.sh ====================
...
Resumo: 12 asserts batidos, 0 divergentes | 1 casos marcados FURO (a corrigir)

==================== bootstrap.test.sh ====================
...
Resumo: 9 asserts batidos, 0 divergentes | 0 casos marcados FURO (a corrigir)

==================== sync.test.sh ====================
...
Resumo: 5 asserts batidos, 0 divergentes | 0 casos marcados FURO (a corrigir)

TODAS AS SUITES VERDES
```

```text
$ shellcheck sync-template.sh template/.engrama/scripts/*.sh tests/contract/sync.test.sh
<sem saída>
```

6. **Pendências**

Não há bloqueio técnico nesta fatia. Nada aqui depende de aprovação adicional da Autoridade; o próximo passo seguro do Orquestrador é auditar o diff local e decidir o commit. Não comitei. O único risco remanescente relevante continua sendo o R1 já conhecido do gate local/cooperativo, que esta fatia não reabriu nem agravou.
