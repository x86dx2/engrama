Você é o EXECUTOR (Executor Crítico). Tier T3. Critique antes de executar. cwd = raiz do repo "engrama".

CONTEXTO: hoje a continuidade depende de DISCIPLINA MANUAL — o agente tem que lembrar de ler o topo do `.engrama/log.md` (o checkpoint) e de atualizar log/ledger. Absorção do ai-memory: usar hooks de ciclo de vida do Claude Code para AUTO-SURGIR o checkpoint no início da sessão e LEMBRAR de atualizá-lo, reduzindo cerimônia. SEJA HONESTO: isto é "auto-surface + lembrete", NÃO "auto-write" (escrever o log exige julgamento humano/do agente). Não prometa captura automática total.

ORDEM:
A) `.engrama/scripts/session-context.sh` (bash portável, `set -u`, read-only, NUNCA falha de forma a quebrar a sessão — sempre exit 0): imprime, para injeção de contexto no SessionStart:
   - o CHECKPOINT vivo: o bloco mais recente do `.engrama/log.md` (do primeiro `## [` até o próximo `## [` ou EOF);
   - o status do bootstrap: se `.engrama/project/bootstrap-do-projeto.md` está `proposed`/tem `TODO`, avisar que o bootstrap não está concluído;
   - um lembrete de 1 linha do handshake (papel · alçada · estado · próximo passo · o que depende da Autoridade).
   Tudo defensivo: se algum arquivo faltar, degrade silenciosamente (não quebre).
B) `.claude/settings.json` (raiz): MESCLAR (não substituir) um hook `SessionStart` que chama `bash "$CLAUDE_PROJECT_DIR/.engrama/scripts/session-context.sh"`, PRESERVANDO o `PreToolUse` (critique-gate-hook) e o `permissions`/`env` existentes. Use o formato de hook do Claude Code para SessionStart (stdout vira contexto; se preferir o formato com `hookSpecificOutput.additionalContext`, pode — mas mantenha o script imprimindo texto simples no stdout para robustez). Opcional: um hook `PreCompact` que chame o mesmo script (lembrar o checkpoint antes de compactar).
C) `tests/contract/session-context.test.sh` (padrão das suítes): prova que o script (i) imprime o bloco de checkpoint mais recente do log; (ii) degrada sem quebrar (exit 0) quando o log/bootstrap faltam; (iii) avisa quando o bootstrap está `proposed`.
D) Propagar ao template: `template/.engrama/scripts/session-context.sh` e o `SessionStart` no `template/.claude/settings.json`. Se for sincronizável, estenda `sync-template.sh` para cobrir o novo script (e mantenha `sync.test.sh` verde); senão, copie e documente.
E) `classify()`: `.claude/settings.json` já é `gate`; `session-context.sh` está sob `.engrama/scripts/` → já casa `.engrama/scripts/critique-gate*`? NÃO — só `critique-gate*`. Adicione `.engrama/scripts/*.sh) addcat gate` OU uma linha específica para `session-context.sh`. Mantenha sync/drift verde se mexer no gate.

FRONTEIRAS: não toque a lógica do gate (critique-gate.sh) nem a prosa de governança; não toque install/bootstrap. Portabilidade BSD/GNU. Não comite.

ACEITE (cole as saídas):
- `bash .engrama/scripts/session-context.sh` imprime o checkpoint atual do repo (o bloco do topo do log.md).
- `python3 -c 'import json;json.load(open(".claude/settings.json"))'` OK e o PreToolUse antigo CONTINUA presente.
- `bash tests/run.sh` verde incl. session-context.test.sh; `shellcheck` limpo nos scripts novos.
- se mexeu no gate/template: `sync.test.sh` verde.
- HONESTIDADE: no cabeçalho do script e/ou num comentário, deixe claro que é auto-surface + lembrete, não auto-write.

RESPONDA nos 6 itens do Executor. Em português.
