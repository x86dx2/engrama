---
type: workflow
status: active
touches: [decisions/0006-governanca-nao-se-autoaprova, decisions/0010-roteamento-modelo-effort-do-executor, governance/modelo-operacional]
date: {{DATA}}
source_refs:
  - {{REPO_PATH}}/.engrama/scripts/critique-gate.sh
---

# Ledger de críticas do Executor ({{MODELO_CRITICA}}) — gate de superfície sensível

Registro **append-only** de toda **crítica do Executor no papel de crítica** (modelo independente, read-only) exigida pelo **ADR 0006 item 7** e pelo **ADR 0010**.

**Verificado mecanicamente** por `.engrama/scripts/critique-gate.sh` (git pre-commit + PreToolUse do harness). Um commit que toca superfície sensível é **bloqueado** se faltar, para CADA categoria tocada, uma entrada CONCLUÍDA referenciando a **branch**. O gate lê a versão **staged/HEAD** do ledger (não o working-tree), rejeita `<pendente>` e bloqueia `objeção` sem `waiver`.

**Categorias** (a lista operacional vigente de arquivo→categoria é o `case` de `.engrama/scripts/critique-gate.sh`, não esta prosa):
- **`governance`** · **`gate`** · **`contract`** — universais (vêm pré-cabeados no gate).
- **`financial`** · **`rbac`** · **`auth`** · **`schema`** — superfícies de domínio; **adapte ao seu projeto** no `classify()` do gate.

> **Template:** ajuste a frase de categorias acima quando mapear as superfícies reais do seu domínio.

**Formato:** `## [data] branch | [cat1][cat2] superfície | veredito | ref`
Vereditos OK: `confirmo` · `confirmo-bug` · `ressalvas` · `N/A: <motivo>` · `waiver <quem/quando>` · `dispensada`. `objeção` só passa com `waiver` na mesma linha (arbitragem da Autoridade registrada).

> **Convenção fail-closed (o gate detecta `waiver` por substring):** escreva o waiver SEMPRE no positivo — `waiver <quem/quando>` — e **nunca** a palavra `waiver` numa negação na mesma linha de uma objeção (ex.: evite "objeção sem waiver"). Caso contrário o gate pode ler a negação como waiver presente.

---

<!-- Exemplo de entrada (apague ao instanciar):

## [{{DATA}}] chore/bootstrap-governanca | [governance] engrama inicial submetido à crítica do Executor | ressalvas → incorporadas (consenso) | <ref do output da crítica>
- {{MODELO_CRITICA}} (read-only): veredito + ressalvas incorporadas; sem objeção material.
- Auditoria do Orquestrador (ADR 0005): <o que foi re-verificado>.

-->
