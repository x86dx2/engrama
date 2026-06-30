# Instanciar o Engrama num projeto novo

Guia passo a passo (**manual / referência**) para adotar este modelo em outro repositório. Tempo típico: ~20 min + o ritual de bootstrap.

> **Prefere que o agente faça sozinho?** Use **[INSTALL.md](INSTALL.md)** e rode `bash /caminho/do/engrama/bin/bootstrap.sh /caminho/do/projeto-novo`. Este arquivo é a versão manual, útil como referência e para o glossário de placeholders.

---

## Passo 1 — Copiar a árvore

Copie **o conteúdo de `template/`** para a **raiz** do projeto novo:

```bash
cp -R /caminho/do/engrama/template/. /caminho/do/projeto-novo/
cd /caminho/do/projeto-novo
chmod +x .engrama/engine/scripts/*.sh .engrama/engine/githooks/pre-commit
```

Ficam na raiz: `CLAUDE.md`, `AGENTS.md`, `.engrama/`, `.github/workflows/ci.yml` e `.markdownlint-cli2.yaml`.
Dentro de `.engrama/` ficam `.engrama/engine/scripts/critique-gate-ci.sh` e `.engrama/evidence/transcripts/`.

> Se você estiver seguindo o fluxo canônico herdado do `Ruflos`, copie também `.claude/settings.json` para ativar o hook `PreToolUse` do gate mecânico.

---

## Passo 2 — Trocar os placeholders

Todos os pontos variáveis usam `{{CHAVE}}`. Defina os valores do seu projeto:

| Placeholder | O que é | Exemplo (`engrama.values.example`) |
|---|---|---|
| `{{PROJETO}}` | nome do projeto | `MeuProjeto` |
| `{{REPO_PATH}}` | caminho absoluto do repo (para `source_refs`) | `/caminho/absoluto/do/repo` |
| `{{ENGRAMA_VERSION}}` | versão do pack que gerou a instalação (`.engrama/VERSION`) | `0.3.0` |
| `{{ORQUESTRADOR}}` | agente no papel de Orquestrador/Auditor | `Claude (Claude Code)` |
| `{{EXECUTOR}}` | agente no papel de Executor Crítico | `Codex` |
| `{{AUTORIDADE}}` | quem é a Autoridade de Mudança | `Humano (voce@exemplo.com)` |
| `{{FINALIDADE_DO_PROJETO}}` | finalidade inicial registrada no bootstrap do projeto | `preencher na primeira abertura` |
| `{{EXECUTOR_CMD}}` | comando que invoca o Executor (adaptador concreto do projeto) | `codex exec` |
| `{{MODELO_CRITICA}}` | modelo independente usado na crítica | `gpt-5.5` *(exemplo; gravado em `models.conf`, confirme no adapter real)* |
| `{{MODELO_EXECUTOR_PESADO}}` | modelo do Executor para tarefas pesadas | `gpt-5.4` *(exemplo; gravado em `models.conf`, confirme no adapter real)* |
| `{{MODELO_EXECUTOR_LEVE}}` | modelo do Executor para tarefas leves | `gpt-5.4-mini` *(exemplo; gravado em `models.conf`, confirme no adapter real)* |
| `{{STACK}}` | stack do projeto | `Node + Postgres` |
| `{{DEV_URL}}` | URL/porta do dev local | `localhost:3000` |
| `{{CMD_DEV}}` | comando canônico de desenvolvimento | `npm run dev` |
| `{{CMD_BUILD}}` | comando canônico de build | `npm run build` |
| `{{CMD_TEST}}` | comando canônico de teste | `npm test` |
| `{{DATA}}` | data de instanciação (frontmatter/log) | `2026-01-01` |

> Inventário canônico dos placeholders/defaults do bootstrap: `engrama.values.example`. No caminho manual, confira a sua lista contra ele antes de substituir em lote.

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

> `{{ENGRAMA_VERSION}}` deve receber a versão do pack-fonte que você está instalando (tipicamente `cat /caminho/do/engrama/VERSION`; no estado atual deste repo, `0.3.0`). `{{MODELO_*}}` são **exemplos**: confirme os ids reais no namespace do seu `codex exec` antes de gravar. Para o inventário completo de overrides/defaults do bootstrap (incluindo `CMD_E2E`), confira `engrama.values.example`.

> **Decisão de estilo:** o modelo é *"papéis por função, não por vendor"*. Na prosa normativa, os papéis aparecem como **Orquestrador / Executor / Autoridade** (canônicos). Os `{{ORQUESTRADOR/EXECUTOR/AUTORIDADE}}` aparecem **uma vez**, na tabela "Mapeamento atual" de `.engrama/memory/governance/papeis-e-alcadas.md`. Trocar quem ocupa cada papel = editar só essa tabela.

---

## Passo 3 — Adaptar o gate mecanico ao seu dominio (OBRIGATORIO antes do 1o commit de codigo de dominio)

Abra `.engrama/engine/scripts/critique-gate.sh` e edite a função **`classify()`**:

- As categorias **universais** já vêm cabeadas: `governance` (.engrama/memory/governance, .engrama/memory/decisions, AGENTS.md, CLAUDE.md), `gate` (.engrama/engine/scripts/critique-gate*, .engrama/engine/githooks, .claude/settings.json), `contract` (tests/contract).
- As de **domínio** vêm como **exemplos comentados** — descomente e troque pelos caminhos reais: `financial`, `rbac`, `auth`, `schema`.
- O que nao entrar no `case` passa **SEM revisao** por este gate. Exemplos: app web -> rotas de `auth` e guards de sessao; servico financeiro -> servicos que movem valor/estado irreversivel; banco -> `migrations/*` e mudancas de schema.
- Atualize a frase "Categorias" em `.engrama/evidence/qa/criticas-do-executor.md` para refletir o que você mapeou.

Princípio: mapeie **superfície sensível** (RBAC, fluxo de valor, auth, migrations, contratos) — onde um erro custa caro. Não cabeie o repo inteiro: o gate deve ser uma rede sob o que importa, não burocracia.
Esquecer esse passo = deixar superficie sensivel fora do gate.

---

## Passo 4 — Ativar o gate

```bash
git config core.hooksPath .engrama/engine/githooks   # pre-commit do git delega ao gate
```

E, no harness do Orquestrador (defesa contra `git commit --no-verify`), cabeie o wrapper. Em Claude Code, em `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.engrama/engine/scripts/critique-gate-hook.sh\"" }
        ]
      }
    ]
  }
}
```

Teste o gate de forma deterministica (deve **bloquear**):

```bash
git checkout -b _gate-selftest
touch .engrama/memory/governance/teste.md && git add .engrama/memory/governance/teste.md
git commit -m "selftest gate"   # → 🚫 GATE DE CRITICA … commit BLOQUEADO
git restore --staged .engrama/memory/governance/teste.md && rm .engrama/memory/governance/teste.md
git checkout -
git branch -D _gate-selftest
```

Faca assim porque a entrada do bootstrap na `main` pode cobrir `governance`; na branch descartavel nao ha ledger cobrindo esse diff.

---

## Passo 5 — Ritual de bootstrap (a governança se aplica a si mesma)

Pelo **ADR 0006**, governança não se autoaprova. O Engrama inicial **é** uma edição de governança — então ele mesmo passa pelo gate:

1. O **Orquestrador** revisa o Engrama instanciado (placeholders trocados, gate adaptado).
2. Submete à **crítica do Executor** (`exec-bridge.sh --role critique --tier T4 --sandbox read-only`): coerência, contradições, riscos.
3. **Antes de commitar (logar precede commit não-trivial):** registra a crítica no ledger `.engrama/evidence/qa/criticas-do-executor.md` **e** a 1ª entrada em `.engrama/log.md` (substitua o exemplo, com o **próximo passo seguro**).
4. **Consenso →** aprovação da **Autoridade** → 1º commit (Engrama + ledger + log no mesmo commit).
   **Impasse →** a Autoridade arbitra (o Executor tem voz, não veto).

A partir daí, a regra vale para si mesma: toda mudança futura de governança repete o ciclo.

---

## Passo 6 — Ativar enforcement server-side

O template manual já entregou `.github/workflows/ci.yml`, `.engrama/engine/scripts/critique-gate-ci.sh` e `.markdownlint-cli2.yaml`. Isso **não** basta sozinho: sem push no GitHub + *branch protection*, o projeto novo continua só com o **freio local burlável**.

1. Dê push do repo para o GitHub (ou confirme que a branch default já existe lá).
2. Descubra `owner/repo` e a branch default, se precisar:

```bash
gh api repos/<owner>/<repo> --jq '{full_name: .full_name, default_branch: .default_branch}'
```

3. Aplique o *branch protection* tornando o job `gate` um *required check*, exigindo PR e bloqueando *force-push*:

```bash
OWNER_REPO="<owner>/<repo>"
DEFAULT_BRANCH="<default>"

gh api -X PUT "repos/$OWNER_REPO/branches/$DEFAULT_BRANCH/protection" --input - <<'JSON'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["gate"]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false,
    "required_approving_review_count": 1
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": true,
  "lock_branch": false,
  "allow_fork_syncing": false
}
JSON
```

4. Confirme o estado aplicado:

```bash
gh api "repos/$OWNER_REPO/branches/$DEFAULT_BRANCH/protection" --jq '{
  required_checks: .required_status_checks.contexts,
  enforce_admins: .enforce_admins.enabled,
  approving_reviews: .required_pull_request_reviews.required_approving_review_count,
  allow_force_pushes: .allow_force_pushes.enabled
}'
```

## Passo 7 — Crescer o Engrama no padrão

Conforme o projeto avança, **ingira** conhecimento no Engrama (workflow em `.engrama/CLAUDE.md`):

- **decisão de arquitetura/domínio** → novo ADR `0011+` em `.engrama/memory/decisions/`;
- **invariante de negócio** → página em `memory/domain/` (linka a fonte no código via `source_refs`);
- **fatia/WP** → página em `memory/roadmap/`;
- **débito/contradição/dúvida** → página em `memory/gaps/`;
- todo fato relevante → entrada em `.engrama/log.md`; cross-links (`touches`) atualizados.

Rode o **Lint** periodicamente (páginas órfãs, `source_refs` que mudaram, ADRs `superseded` sem ponteiro, contradições) e registre o resultado.

---

## Checklist de adoção

- [ ] `template/` copiado para a raiz; scripts executáveis.
- [ ] Todos os `{{PLACEHOLDERS}}` da tabela foram trocados, conferidos contra `engrama.values.example`, e `grep -rno '{{[A-Z_]*}}'` retorna vazio.
- [ ] `classify()` do gate adaptado ao domínio; frase de categorias do ledger alinhada.
- [ ] `core.hooksPath .engrama/engine/githooks` setado; wrapper PreToolUse cabeado; gate testado (bloqueia).
- [ ] Ritual de bootstrap concluído (crítica do Executor + aprovação da Autoridade + ledger).
- [ ] `.github/workflows/ci.yml` e `.markdownlint-cli2.yaml` estão na raiz do projeto novo.
- [ ] `.engrama/engine/scripts/critique-gate-ci.sh` e `.engrama/evidence/transcripts/README.md` estão no projeto novo.
- [ ] No GitHub do projeto novo, a branch default exige PR, bloqueia *force-push* e marca o check `gate` como obrigatório. Sem isso, o enforcement segue só local/cooperativo.
- [ ] 1ª entrada real no `.engrama/log.md` com o próximo passo seguro.
- [ ] Handshake de abertura de sessão validado (papel · alçada · estado · próximo passo · o que depende de aprovação).
