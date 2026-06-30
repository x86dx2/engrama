# INSTALL.md — Auto-instalação do Engrama (PLAYBOOK DO AGENTE)

> **Você (agente) está lendo isto** no repo-fonte do Engrama e pediram para **bootstrapar / instalar** o Engrama em outro projeto. Execute os passos abaixo na ordem. Onde estiver marcado **PERGUNTAR**, pergunte ao humano e **não invente**. Onde estiver **INFERIR**, descubra do repositório e **confirme** com o humano antes de gravar.

Resultado final: o repo passa a ter, na **raiz**, os gates `CLAUDE.md`/`AGENTS.md`, o `.engrama/` de governança, o `.claude/settings.json` com o hook do gate mecânico, `.github/workflows/ci.yml`, `.markdownlint-cli2.yaml` e o primeiro commit feito sob as próprias regras. Dentro de `.engrama/` ficam o CI-gate (`.engrama/engine/scripts/critique-gate-ci.sh`) e os transcripts versionados (`.engrama/evidence/transcripts/`). A partir daí, qualquer agente que abrir o repo cai no gate de governança e, no **primeiro startup**, é forçado a completar o bootstrap do projeto.

---

## Passo 0 — Pré-condições

1. Tenha o **caminho do repo-alvo**.
2. Se o diretório-alvo ainda não for um repo git, o `bin/bootstrap.sh` cria `git init -b main` para você.
3. Se já existirem `CLAUDE.md`, `AGENTS.md`, `.engrama/` ou `.claude/settings.json` na raiz do projeto-alvo, **não sobrescreva** — vá para a seção **Merge** no fim. Caso contrário, siga.

## Passo 1 — Coletar os valores (INFERIR + PERGUNTAR)

O `bin/bootstrap.sh` já infere defaults e instala direto na raiz do projeto-alvo. O arquivo de valores é **opcional** e serve só para override:

```bash
cp /caminho/do/engrama/engrama.values.example /tmp/finance.values
```

Defaults/heurísticas usados pelo bootstrap:

| Chave | Como obter | |
|---|---|---|
| `REPO_PATH` | **INFERIR**: `git rev-parse --show-toplevel` | |
| `ENGRAMA_VERSION` | **FONTE DE VERDADE**: `cat /caminho/do/engrama/VERSION` (fallback `0.0.0` se faltar) | |
| `DATA` | **INFERIR**: data de hoje (`YYYY-MM-DD`) | |
| `PROJETO` | **INFERIR** do nome do diretório / `package.json` / remote git → **confirmar** | |
| `STACK` | **INFERIR** do repo (`package.json`, `go.mod`, `requirements.txt`, `Cargo.toml`, `pom.xml`…) → **confirmar** | |
| `AUTORIDADE` | **INFERIR** de `git config user.email` → **confirmar** quem é a Autoridade de Mudança | |
| `ORQUESTRADOR` | **PADRÃO**: `Claude (Claude Code)` | |
| `DEV_URL` | **INFERIR** de engine/scripts/config (porta do dev) ou **PERGUNTAR** | |
| `EXECUTOR` | **PADRÃO**: `Codex` | |
| `EXECUTOR_CMD` | **ADAPTADOR CONCRETO atual do pack**: `codex exec` | |
| `MODELO_CRITICA` | **EXEMPLO atual do pack**: `gpt-5.5` — gravado em `models.conf`; confirme no adapter real | |
| `MODELO_EXECUTOR_PESADO` | **EXEMPLO atual do pack**: `gpt-5.4` — gravado em `models.conf`; confirme no adapter real | |
| `MODELO_EXECUTOR_LEVE` | **EXEMPLO atual do pack**: `gpt-5.4-mini` — gravado em `models.conf`; confirme no adapter real | |

> O bootstrap já assume o padrão operacional atual do pack. Pergunte só quando o projeto-alvo divergir do padrão ou quando a `AUTORIDADE`/`STACK`/`DEV_URL` não estiverem claros. Glossário completo de cada placeholder: [INSTANTIATE.md](INSTANTIATE.md).

Além disso, o bootstrap já semeia:
- `FINALIDADE_DO_PROJETO` = `TODO: confirmar com a Autoridade na primeira abertura`
- comandos canônicos inferidos (`CMD_DEV`, `CMD_BUILD`, `CMD_TEST`, `CMD_E2E`)
- `.engrama/memory/project/bootstrap-do-projeto.md` em `status: proposed`

Esse arquivo é a trava do **primeiro startup**: enquanto estiver `proposed` ou com `TODO`, o Orquestrador precisa entrevistar a Autoridade e fechar finalidade, stack, comandos, fronteiras e superfícies sensíveis antes de trabalho substantivo.

## Passo 2 — Rodar o instalador mecânico

```bash
bash /caminho/do/engrama/bin/bootstrap.sh /caminho/do/projeto-alvo [/tmp/override.values]
```

Ele: cria/inicializa o repo-alvo se necessário, infere defaults, copia `template/` → raiz do repo, substitui **todos** os placeholders, instala `.claude/settings.json`, registra `.engrama/VERSION`, e ativa o hook (`core.hooksPath .engrama/engine/githooks`). **Confirme** que a saída diz `Placeholders restantes: ''` (vazio). Se sobrou algum, ajuste o arquivo de override e rode de novo (o instalador recusa sobrescrever — veja Merge).

## Passo 3 — Adaptar o gate ao dominio (OBRIGATORIO antes do 1o commit de codigo de dominio)

Abra `.engrama/engine/scripts/critique-gate.sh` e edite a função **`classify()`**:

- As categorias **universais** já vêm cabeadas (`governance`, `gate`, `contract`) — não remova.
- **Mapeie os arquivos sensíveis do SEU dominio antes do 1o commit de codigo de dominio.** O que não entrar no `case` passa **SEM revisão** por este gate.
- Exemplos curtos por stack:
  - app web / API: rotas de `auth`, guardas de sessão, middleware de permissão, handlers de API que mudam estado irreversível;
  - serviço financeiro / fluxo crítico: serviços que movem valor, conciliação, ledger, aprovação, cobrança, liquidação;
  - banco / schema: `migrations/*`, mudanças de esquema, scripts de backfill que alteram dado persistido.
- **APRESENTE o mapa proposto à Autoridade** (arquivo→categoria) e ajuste conforme a resposta. Mantenha-o em sincronia com a frase de categorias de `.engrama/evidence/qa/criticas-do-executor.md`.
- Esquecer esse passo = deixar superfície sensível **fora do gate**.

## Passo 4 — (opcional) Cabear o gate no harness do Orquestrador

Defesa extra contra `git commit --no-verify`. Se o seu harness suporta hooks (ex.: Claude Code), crie/edite `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [
        { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.engrama/engine/scripts/critique-gate-hook.sh\"" }
      ] }
    ]
  }
}
```

## Passo 5 — Ritual de bootstrap (ADR 0006: a governança se aplica a si mesma)

A governança instalada **é** uma edição de governança → passa pelo próprio gate antes do 1º commit.

Se você usou `bin/bootstrap.sh`, o instalador **já semeia** no ledger uma linha `dispensada` da **Autoridade (via bin/bootstrap.sh)**, amarrada por `sha256` ao **snapshot staged** que ele acabou de instalar. Isso destrava o commit mecânico inicial, mas **só** esse diff.

1. Revise o Engrama instalado (placeholders trocados, `classify()` adaptado).
2. Rode a **crítica do Executor** (read-only) sobre a governança instalada:
   `bash ./.engrama/engine/scripts/exec-bridge.sh --role critique --tier T4 --sandbox read-only -- "<ordem de crítica>"` (sem patch).
3. Revise a linha `dispensada` semeada pelo instalador. Se o 1º commit for **o snapshot mecânico staged pelo bootstrap**, ela já cobre o diff. Se você editar arquivos sensíveis antes de commitar (por exemplo `classify()`, `.engrama/log.md` ou docs/ADRs de governança), o `sha256` fica obsoleto e você precisa **substituir** a dispensa por crítica real ou registrar o ledger manualmente.
4. **Antes de commitar** (logar precede commit): registre a crítica em `.engrama/evidence/qa/criticas-do-executor.md` **e** a 1ª entrada em `.engrama/log.md` (substitua o exemplo seed; inclua o próximo passo seguro) sempre que o diff já não for mais o snapshot puro do instalador.
5. **Consenso** → aprovação da **Autoridade** → 1º commit. **Impasse** → a Autoridade arbitra (o Executor tem voz, não veto).

## Passo 6 — Ativar enforcement server-side

O template já trouxe `.github/workflows/ci.yml`, `.engrama/engine/scripts/critique-gate-ci.sh` e `.markdownlint-cli2.yaml` para o repo-alvo. Isso **não** vira freio vinculante sozinho: sem push no GitHub + *branch protection*, o projeto novo fica só com o **freio local burlável**.

1. Dê push do repo-alvo para o GitHub (ou confirme que a branch default já está lá).
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

## Passo 7 — Verificação final (prove que replicou)

- [ ] `grep -rho '{{[A-Z_]*}}' CLAUDE.md AGENTS.md .engrama` retorna **vazio**.
- [ ] `git config core.hooksPath` = `.engrama/engine/githooks`.
- [ ] `.claude/settings.json` existe e chama `.engrama/engine/scripts/critique-gate-hook.sh`.
- [ ] `.github/workflows/ci.yml` e `.markdownlint-cli2.yaml` existem na raiz do repo-alvo.
- [ ] `.engrama/engine/scripts/critique-gate-ci.sh` e `.engrama/evidence/transcripts/README.md` existem no repo-alvo.
- [ ] **Teste do gate (deterministico):** num repo limpo, rode em branch descartável para não herdar a entrada do bootstrap na `main`:

  ```bash
  git checkout -b _gate-selftest
  touch .engrama/memory/governance/teste.md && git add .engrama/memory/governance/teste.md
  git commit -m "selftest gate"   # -> 🚫 GATE DE CRITICA
  git restore --staged .engrama/memory/governance/teste.md && rm .engrama/memory/governance/teste.md
  git checkout -
  git branch -D _gate-selftest
  ```

  A linha do bootstrap na `main` cobriria `governance`; na branch descartável não há entrada cobrindo esse diff, então o bloqueio é real.
- [ ] No GitHub do repo-alvo, o *branch protection* da branch default exige PR, bloqueia *force-push* e marca o check `gate` como obrigatório. Sem isso, o enforcement segue só local/cooperativo.
- [ ] Declare o **handshake** de abertura: papel · alçada · estado factual (topo do `.engrama/log.md`) · próximo passo seguro · o que depende da Autoridade.
- [ ] O repo-alvo ficou com `CLAUDE.md`, `AGENTS.md`, `.engrama/` e `.claude/settings.json` na raiz, sem copiar `docs/engrama/`.
- [ ] `memory/project/bootstrap-do-projeto.md` foi lido e, se ainda estiver `proposed`, o Orquestrador iniciou a entrevista de bootstrap com a Autoridade.

---

## Merge — se o projeto JÁ tinha `CLAUDE.md`/`AGENTS.md`/`.engrama/`

O instalador **recusa sobrescrever**. Nesse caso, faça merge manual:

- **`CLAUDE.md` existente** → intercale a seção `## Gate operacional obrigatório` (ordem de leitura + handshake) e o `## Modelo em uma página` no topo do arquivo atual, preservando o conteúdo do projeto.
- **`.engrama/` existente** → copie só o que falta (`.engrama/memory/governance/`, `.engrama/memory/decisions/0001-0010`, `.engrama/memory/specs/`, `.engrama/evidence/qa/criticas-do-executor.md`, e o schema `.engrama/CLAUDE.md` se não houver um) e reconcilie a numeração de ADR.
- **`.engrama/engine/scripts/critique-gate.sh` existente** → reconcilie a `classify()`.
- **`.claude/settings.json` existente** → mescle o hook `PreToolUse` que chama `.engrama/engine/scripts/critique-gate-hook.sh`.
- Depois, rode a substituição de placeholders à mão (ou um `bin/install.sh` apontando para um arquivo de override) e siga do Passo 3.

## Limites honestos (não é zero-touch — por design)

O agente faz **todo o trabalho mecânico** e **propõe tudo**, mas 3 coisas ainda exigem o humano, porque o modelo é construído **em torno da Autoridade humana**:

1. **quem é a Autoridade** de Mudança, quando a inferência não bastar ou estiver errada;
2. o **mapa de superfície sensível** do gate (`classify()`) — depende do domínio;
3. a **aprovação do 1º commit** (e de toda promoção sensível dali em diante).

`EXECUTOR`, `EXECUTOR_CMD` e `MODELO_*` já saem preenchidos com os adaptadores concretos atuais do pack. Trate `MODELO_*` como **EXEMPLO** e confirme os ids reais contra o namespace do seu `codex exec`; `ENGRAMA_VERSION` sai do `VERSION` do repo-fonte (fallback `0.0.0` se faltar).

Tudo o mais é automático.
