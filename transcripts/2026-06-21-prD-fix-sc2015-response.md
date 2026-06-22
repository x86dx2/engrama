---
codex-session: 019eecb9-e0bd-76b3-99d3-d8592fa5e7f7
codex-session-source: stream
model: unknown
sandbox: workspace-write
label: prD-fix-sc2015
---

Papel presumido nesta sessão: Executor Crítico. Vou abrir primeiro os artefatos obrigatórios do Engrama na ordem prescrita, confirmar alçada e estado factual no topo do `.engrama/log.md`, e só então tocar no fix do `SC2015`.
Estou concluindo o gate de sessão obrigatório. Em seguida confirmo explicitamente a leitura da ordem, a crítica técnica e o veredito antes da edição.
Papel: `Executor Crítico`. Alçada: escrever a fatia solicitada na branch atual, sem commit; sem arbitrar governança nem fazer ação irreversível. Estado factual no topo do `.engrama/log.md`: branch `feat/p1-atritos-do-adotante`, PR-D aberto, foco em atritos do bootstrap, QA do Orquestrador já registrou suite/lint/shellcheck/smoke verdes nessa fatia. Próximo passo seguro: localizar a linha de `SC2015` em `bin/bootstrap.sh`, buscar gêmeas nas rotinas `seed_bootstrap_dispensa` e `stage_bootstrap_snapshot`, e aplicar uma reescrita sem alterar o comportamento. Dependência de aprovação da Autoridade: nenhuma para este ajuste local sem commit; qualquer ação irreversível ou exceção de processo continuaria dependendo dela.

Leitura da ordem: corrigir o antipadrão `A && B || C` que a CI nova interpreta como `SC2015`, garantir que `bin/bootstrap.sh` fique limpo nesse ponto sem novos achados, e revalidar com `shellcheck`, `bash tests/run.sh` e `bash .engrama/scripts/lint.sh`.

Crítica técnica: a direção está correta e é mínima. O único cuidado é preservar o comportamento de “engolir falha e cair para string vazia” sem mover o redirecionamento `2>/dev/null` para fora do escopo pretendido; também preciso conferir se existem gêmeas sem depender do shellcheck local, porque a sua observação sobre versão divergente é plausível.

Veredito: `concordo`.
Encontrei um único `SC2015` material em `bin/bootstrap.sh:188`. Vou editar só esse trecho para manter o fallback no escopo do subshell inteiro e depois validar o restante por busca e shellcheck.
Vou trocar a captura de `diff_hash` por um bloco explícito com fallback fora do `&&`, preservando o mesmo resultado de `string vazia` quando a coleta falhar.
A primeira edição precisa de um ajuste imediato: vou verificar a sintaxe gerada e corrigir para um `if` shell válido antes de rodar os gates.
A reescrita ficou no formato certo. Agora vou validar em três frentes: busca visual por padrões `&& ... || ...` relevantes, `shellcheck -S info` no escopo pedido, e depois suíte + lint.
`shellcheck -S info` terminou limpo. Vou rodar a suíte completa e o lint do Engrama; se algum deles variar, eu trato antes de encerrar.
A suíte ainda está no trecho mais longo (`fuzz`/contratos). O lint já saiu sem diagnóstico e sem erro; estou esperando o término do `tests/run.sh` para fechar com evidência completa.
O runner não está emitindo nada novo há alguns ciclos, então estou tratando isso como teste ainda em execução, não como sucesso presumido. Vou esperar o fim explícito do processo antes de reportar verde.
Os gates fecharam verdes. Vou só extrair o diff exato da linha tocada e o estado do arquivo para te devolver a evidência objetiva, sem inventário desnecessário.
**Leitura da ordem**

Corrigir o `SC2015` em `bin/bootstrap.sh` sem mudar comportamento, verificar que não ficou nenhum gêmeo relevante no código novo dessa fatia, e revalidar com `shellcheck`, `bash tests/run.sh` e `bash .engrama/scripts/lint.sh`, sem commit.

**Crítica técnica**

A direção era correta e mínima. O ponto sensível era manter o mesmo fallback para `diff_hash=""` quando o cálculo falhasse, mas movendo o `||` para fora do `cd && bash ...`.

**Veredito**

`concordo`

**Execução**

Toquei só [bin/bootstrap.sh](/Users/x86/git-projects/engrama/bin/bootstrap.sh:188). A linha virou:

```sh
if ! diff_hash="$( (cd "$ROOT" && bash ./.engrama/scripts/engrama-diff-hash.sh --cached) 2>/dev/null )"; then
  diff_hash=""
fi
```

Diff aplicado:

```diff
-  diff_hash="$(cd "$ROOT" && bash ./.engrama/scripts/engrama-diff-hash.sh --cached 2>/dev/null || true)"
+  if ! diff_hash="$( (cd "$ROOT" && bash ./.engrama/scripts/engrama-diff-hash.sh --cached) 2>/dev/null )"; then
+    diff_hash=""
+  fi
```

**Evidências**

`shellcheck -S info bin/*.sh .engrama/scripts/*.sh .engrama/githooks/pre-commit tests/run.sh tests/gate/*.test.sh tests/contract/*.test.sh`
Resultado: exit `0`, sem saída, zero achados novos; `bin/bootstrap.sh` ficou limpo.

Busca visual por `&& ... || ...` no escopo validado:
- Restaram só formas seguras em `.engrama/scripts/session-context.sh:12`, `.engrama/scripts/session-context.sh:18` e `.engrama/scripts/critique-gate.sh:177`.
- Nenhuma gêmea adicional em `seed_bootstrap_dispensa` ou `stage_bootstrap_snapshot`.

`bash tests/run.sh`
Resultado: exit `0`, `TODAS AS SUITES VERDES`, incluindo `C12` e `C13`.

`bash .engrama/scripts/lint.sh`
Resultado: exit `0`, sem saída.

**Pendências**

Nenhuma pendência técnica desta ordem. Não comitei. Há um arquivo não rastreado já presente no worktree, `transcripts/2026-06-21-prD-fix-sc2015-order.md`, que não foi alterado por mim.
