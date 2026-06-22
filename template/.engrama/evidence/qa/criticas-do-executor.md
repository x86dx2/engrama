---
type: workflow
status: active
touches: [memory/decisions/0006-governanca-nao-se-autoaprova, memory/decisions/0010-roteamento-modelo-effort-do-executor, memory/decisions/0011-diff-binding-atestacao-verificavel, memory/governance/modelo-operacional]
date: {{DATA}}
source_refs:
  - .engrama/engine/scripts/critique-gate.sh
---

# Ledger de críticas do Executor ({{MODELO_CRITICA}}) — gate de superfície sensível

Registro **append-only** de toda **crítica do Executor no papel de crítica** (modelo independente, read-only) exigida pelo **ADR 0006 item 7** e pelo **ADR 0010**.

**Verificado mecanicamente** por `.engrama/engine/scripts/critique-gate.sh` (git pre-commit + PreToolUse do harness). Um commit que toca superfície sensível é **bloqueado** se faltar, para CADA categoria tocada, uma entrada CONCLUÍDA referenciando a **branch**. O gate lê a versão **staged/HEAD** do ledger (não o working-tree), rejeita `<pendente>` e bloqueia `objeção` sem `waiver`.

**Diff-binding verificável (ADR 0011):** o campo 4 (`ref`) pode carregar um token `sha256:<hex>` calculado por `bash ./.engrama/engine/scripts/engrama-diff-hash.sh`. Quando presente, o gate compara esse token ao fingerprint atual do diff alvo (staged no local; `ENGRAMA_DIFF_HASH` quando a CI injeta o hash do diff real do PR), sempre excluindo o próprio ledger:
- **match forte** (`sha256` bate) — a crítica cobre **este diff**;
- **hash obsoleto** (`sha256` não bate) — a crítica fica vinculada a **outro diff** e não satisfaz o gate;
- **sem `sha256:`** — caminho **legado** (branch+categoria+veredito), preservado por compatibilidade.

**Modo estrito:** com `ENGRAMA_REQUIRE_DIFF_BIND=1`, só o **match forte** satisfaz; entradas legadas sem hash deixam de contar. Isto prova **cobertura do diff**, não **identidade independente do crítico** — esse teto exigiria assinatura/chave ou outra identidade que o seu executor-bridge não expõe hoje.

**Categorias** (a lista operacional vigente de arquivo→categoria é o `case` de `.engrama/engine/scripts/critique-gate.sh`, não esta prosa):
- **`governance`** · **`gate`** · **`contract`** — universais (vêm pré-cabeados no gate).
- **`financial`** · **`rbac`** · **`auth`** · **`schema`** — superfícies de domínio; **adapte ao seu projeto** no `classify()` do gate.

> **Template:** ajuste a frase de categorias acima quando mapear as superfícies reais do seu domínio.

**Formato:** `## [data] branch | [cat1][cat2] superfície | veredito | ref`
Vereditos OK: `confirmo` · `confirmo-bug` · `ressalvas` · `N/A: <motivo>` · `waiver <quem/quando>` · `dispensada`. `objeção` só passa com `waiver` na mesma linha (arbitragem da Autoridade registrada).

> O `ref` pode incluir o token `sha256:<hex>` calculado por `bash ./.engrama/engine/scripts/engrama-diff-hash.sh` (local: diff staged; CI: `--range <base>...HEAD`).

> **Convenção fail-closed (o gate detecta `waiver` por substring):** escreva o waiver SEMPRE no positivo — `waiver <quem/quando>` — e **nunca** a palavra `waiver` numa negação na mesma linha de uma objeção (ex.: evite "objeção sem waiver"). Caso contrário o gate pode ler a negação como waiver presente.

---

<!-- Exemplo de entrada (apague ao instanciar):

## [{{DATA}}] chore/bootstrap-governanca | [governance] engrama inicial submetido à crítica do Executor | ressalvas → incorporadas (consenso) | <ref do output da crítica>
- {{MODELO_CRITICA}} (read-only): veredito + ressalvas incorporadas; sem objeção material.
- Auditoria do Orquestrador (ADR 0005): <o que foi re-verificado>.

-->
