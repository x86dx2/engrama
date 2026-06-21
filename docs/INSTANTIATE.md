# Instanciar o Engrama num projeto novo

Guia passo a passo (**manual / referência**) para adotar este modelo em outro repositório. Tempo típico: ~20 min + o ritual de bootstrap.

> **Prefere que o agente faça sozinho?** Use **[INSTALL.md](INSTALL.md)** e rode `bash /caminho/do/engrama/bin/bootstrap.sh /caminho/do/projeto-novo`. Este arquivo é a versão manual, útil como referência e para o glossário de placeholders.

---

## Passo 1 — Copiar a árvore

Copie **o conteúdo de `template/`** para a **raiz** do projeto novo:

```bash
cp -R /caminho/do/engrama/template/. /caminho/do/projeto-novo/
cd /caminho/do/projeto-novo
chmod +x .engrama/scripts/*.sh .engrama/githooks/pre-commit
```

Ficam na raiz: `CLAUDE.md`, `AGENTS.md`, `.engrama/`.

> Se você estiver seguindo o fluxo canônico herdado do `Ruflos`, copie também `.claude/settings.json` para ativar o hook `PreToolUse` do gate mecânico.

---

## Passo 2 — Trocar os placeholders

Todos os pontos variáveis usam `{{CHAVE}}`. Defina os valores do seu projeto:

| Placeholder | O que é | Exemplo (Ruflos) |
|---|---|---|
| `{{PROJETO}}` | nome do projeto | `Ruflos` |
| `{{REPO_PATH}}` | caminho absoluto do repo (para `source_refs`) | `/Users/x86/git-projects/Ruflos` |
| `{{ENGRAMA_VERSION}}` | versão do pack que gerou a instalação (`.engrama/VERSION`) | `0.1.0` |
| `{{ORQUESTRADOR}}` | agente no papel de Orquestrador/Auditor | `Claude (Claude Code)` |
| `{{EXECUTOR}}` | agente no papel de Executor Crítico | `Codex` |
| `{{AUTORIDADE}}` | quem é a Autoridade de Mudança | `Humano (voce@exemplo.com)` |
| `{{EXECUTOR_CMD}}` | comando que invoca o Executor (adaptador concreto do projeto) | `codex exec` |
| `{{MODELO_CRITICA}}` | modelo independente usado na crítica | `gpt-5.5` *(exemplo; confirme o id real contra o seu `codex exec`)* |
| `{{MODELO_EXECUTOR_PESADO}}` | modelo do Executor para tarefas pesadas | `gpt-5.4` *(exemplo; confirme o id real contra o seu `codex exec`)* |
| `{{MODELO_EXECUTOR_LEVE}}` | modelo do Executor para tarefas leves | `gpt-5.4-mini` *(exemplo; confirme o id real contra o seu `codex exec`)* |
| `{{STACK}}` | stack do projeto | `Cloudflare Workers + Next.js + D1` |
| `{{DEV_URL}}` | URL/porta do dev local | `localhost:3000` |
| `{{DATA}}` | data de instanciação (frontmatter/log) | `2026-06-17` |

Busque o que falta trocar:

```bash
grep -rno '{{[A-Z_]*}}' . --include='*.md' --include='*.sh' --include='VERSION' | sort -u
```

Substituição em lote (revise antes — o `{{REPO_PATH}}` e `{{DATA}}` têm `/` e devem ir primeiro):

```bash
# exemplo macOS/BSD sed; em Linux use sed -i (sem o '')
grep -rl '{{PROJETO}}' . | xargs sed -i '' 's#{{PROJETO}}#Ruflos#g'
grep -rl '{{EXECUTOR_CMD}}' . | xargs sed -i '' 's#{{EXECUTOR_CMD}}#codex exec#g'
# … repita por placeholder …
```

> `{{ENGRAMA_VERSION}}` deve receber a versão do pack-fonte que você está instalando (tipicamente `cat /caminho/do/engrama/VERSION`). `{{MODELO_*}}` são **exemplos**: confirme os ids reais no namespace do seu `codex exec` antes de gravar.

> **Decisão de estilo:** o modelo é *"papéis por função, não por vendor"*. Na prosa normativa, os papéis aparecem como **Orquestrador / Executor / Autoridade** (canônicos). Os `{{ORQUESTRADOR/EXECUTOR/AUTORIDADE}}` aparecem **uma vez**, na tabela "Mapeamento atual" de `.engrama/governance/papeis-e-alcadas.md`. Trocar quem ocupa cada papel = editar só essa tabela.

---

## Passo 3 — Adaptar o gate mecânico ao seu domínio

Abra `.engrama/scripts/critique-gate.sh` e edite a função **`classify()`**:

- As categorias **universais** já vêm cabeadas: `governance` (.engrama/governance, .engrama/decisions, AGENTS.md, CLAUDE.md), `gate` (.engrama/scripts/critique-gate*, .engrama/githooks, .claude/settings.json), `contract` (tests/contract).
- As de **domínio** vêm como **exemplos comentados** — descomente e troque pelos caminhos reais: `financial`, `rbac`, `auth`, `schema`.
- Atualize a frase "Categorias" em `.engrama/qa/criticas-do-executor.md` para refletir o que você mapeou.

Princípio: mapeie **superfície sensível** (RBAC, fluxo de valor, auth, migrations, contratos) — onde um erro custa caro. Não cabeie o repo inteiro: o gate deve ser uma rede sob o que importa, não burocracia.

---

## Passo 4 — Ativar o gate

```bash
git config core.hooksPath .engrama/githooks   # pre-commit do git delega ao gate
```

E, no harness do Orquestrador (defesa contra `git commit --no-verify`), cabeie o wrapper. Em Claude Code, em `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.engrama/scripts/critique-gate-hook.sh\"" }
        ]
      }
    ]
  }
}
```

Teste o gate (deve **bloquear**):

```bash
touch .engrama/governance/teste.md && git add .engrama/governance/teste.md
git commit -m "teste"     # → 🚫 GATE DE CRÍTICA … commit BLOQUEADO
git restore --staged .engrama/governance/teste.md && rm .engrama/governance/teste.md
```

---

## Passo 5 — Ritual de bootstrap (a governança se aplica a si mesma)

Pelo **ADR 0006**, governança não se autoaprova. O Engrama inicial **é** uma edição de governança — então ele mesmo passa pelo gate:

1. O **Orquestrador** revisa o Engrama instanciado (placeholders trocados, gate adaptado).
2. Submete à **crítica do Executor** (`{{EXECUTOR_CMD}} -m {{MODELO_CRITICA}}`, read-only): coerência, contradições, riscos.
3. **Antes de commitar (logar precede commit não-trivial):** registra a crítica no ledger `.engrama/qa/criticas-do-executor.md` **e** a 1ª entrada em `.engrama/log.md` (substitua o exemplo, com o **próximo passo seguro**).
4. **Consenso →** aprovação da **Autoridade** → 1º commit (Engrama + ledger + log no mesmo commit).
   **Impasse →** a Autoridade arbitra (o Executor tem voz, não veto).

A partir daí, a regra vale para si mesma: toda mudança futura de governança repete o ciclo.

---

## Passo 6 — Crescer o Engrama no padrão

Conforme o projeto avança, **ingira** conhecimento no Engrama (workflow em `.engrama/CLAUDE.md`):

- **decisão de arquitetura/domínio** → novo ADR `0011+` em `.engrama/decisions/`;
- **invariante de negócio** → página em `domain/` (linka a fonte no código via `source_refs`);
- **fatia/WP** → página em `roadmap/`;
- **débito/contradição/dúvida** → página em `gaps/`;
- todo fato relevante → entrada em `.engrama/log.md`; cross-links (`touches`) atualizados.

Rode o **Lint** periodicamente (páginas órfãs, `source_refs` que mudaram, ADRs `superseded` sem ponteiro, contradições) e registre o resultado.

---

## Checklist de adoção

- [ ] `template/` copiado para a raiz; scripts executáveis.
- [ ] Todos os `{{PLACEHOLDERS}}` trocados (`grep -rno '{{[A-Z_]*}}'` retorna vazio).
- [ ] `classify()` do gate adaptado ao domínio; frase de categorias do ledger alinhada.
- [ ] `core.hooksPath .engrama/githooks` setado; wrapper PreToolUse cabeado; gate testado (bloqueia).
- [ ] Ritual de bootstrap concluído (crítica do Executor + aprovação da Autoridade + ledger).
- [ ] 1ª entrada real no `.engrama/log.md` com o próximo passo seguro.
- [ ] Handshake de abertura de sessão validado (papel · alçada · estado · próximo passo · o que depende de aprovação).
