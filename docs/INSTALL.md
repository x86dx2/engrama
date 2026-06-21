# INSTALL.md — Auto-instalação do Engrama (PLAYBOOK DO AGENTE)

> **Você (agente) está lendo isto** no repo-fonte do Engrama e pediram para **bootstrapar / instalar** o Engrama em outro projeto. Execute os passos abaixo na ordem. Onde estiver marcado **PERGUNTAR**, pergunte ao humano e **não invente**. Onde estiver **INFERIR**, descubra do repositório e **confirme** com o humano antes de gravar.

Resultado final: o repo passa a ter, na **raiz**, os gates `CLAUDE.md`/`AGENTS.md`, o `.engrama/` de governança, o `.claude/settings.json` com o hook do gate mecânico, e o primeiro commit feito sob as próprias regras. A partir daí, qualquer agente que abrir o repo cai no gate de governança e, no **primeiro startup**, é forçado a completar o bootstrap do projeto.

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
| `DATA` | **INFERIR**: data de hoje (`YYYY-MM-DD`) | |
| `PROJETO` | **INFERIR** do nome do diretório / `package.json` / remote git → **confirmar** | |
| `STACK` | **INFERIR** do repo (`package.json`, `go.mod`, `requirements.txt`, `Cargo.toml`, `pom.xml`…) → **confirmar** | |
| `AUTORIDADE` | **INFERIR** de `git config user.email` → **confirmar** quem é a Autoridade de Mudança | |
| `ORQUESTRADOR` | **PADRÃO**: `Claude (Claude Code)` | |
| `DEV_URL` | **INFERIR** de scripts/config (porta do dev) ou **PERGUNTAR** | |
| `EXECUTOR` | **PADRÃO**: `Codex` | |
| `EXECUTOR_CMD` | **PADRÃO**: `codex exec` | |
| `MODELO_CRITICA` | **PADRÃO**: `gpt-5.5` | |
| `MODELO_EXECUTOR_PESADO` | **PADRÃO**: `gpt-5.4` | |
| `MODELO_EXECUTOR_LEVE` | **PADRÃO**: `gpt-5.4-mini` | |

> O bootstrap já assume o padrão operacional atual do pack. Pergunte só quando o projeto-alvo divergir do padrão ou quando a `AUTORIDADE`/`STACK`/`DEV_URL` não estiverem claros. Glossário completo de cada placeholder: [INSTANTIATE.md](INSTANTIATE.md).

Além disso, o bootstrap já semeia:
- `FINALIDADE_DO_PROJETO` = `TODO: confirmar com a Autoridade na primeira abertura`
- comandos canônicos inferidos (`CMD_DEV`, `CMD_BUILD`, `CMD_TEST`, `CMD_E2E`)
- `.engrama/project/bootstrap-do-projeto.md` em `status: proposed`

Esse arquivo é a trava do **primeiro startup**: enquanto estiver `proposed` ou com `TODO`, o Orquestrador precisa entrevistar a Autoridade e fechar finalidade, stack, comandos, fronteiras e superfícies sensíveis antes de trabalho substantivo.

## Passo 2 — Rodar o instalador mecânico

```bash
bash /caminho/do/engrama/bin/bootstrap.sh /caminho/do/projeto-alvo [/tmp/override.values]
```

Ele: cria/inicializa o repo-alvo se necessário, infere defaults, copia `template/` → raiz do repo, substitui **todos** os placeholders, instala `.claude/settings.json`, e ativa o hook (`core.hooksPath .engrama/githooks`). **Confirme** que a saída diz `Placeholders restantes: ''` (vazio). Se sobrou algum, ajuste o arquivo de override e rode de novo (o instalador recusa sobrescrever — veja Merge).

## Passo 3 — Adaptar o gate ao domínio (SEU julgamento)

Abra `.engrama/scripts/critique-gate.sh` e edite a função **`classify()`**:

- As categorias **universais** já vêm cabeadas (`governance`, `gate`, `contract`) — não remova.
- **Inspecione o código do projeto** e identifique as superfícies sensíveis reais. Mapeie cada uma para uma categoria de domínio:
  - `auth` — login/sessão/tokens/rate-limit/rotas de autenticação;
  - `rbac` — permissões/papéis/multi-tenant;
  - `financial` (ou o fluxo crítico do seu domínio) — serviços que movem **valor ou estado irreversível**;
  - `schema` — migrations / mudança de esquema de dados.
- **APRESENTE o mapa proposto à Autoridade** (arquivo→categoria) e ajuste conforme a resposta. Mantenha-o em sincronia com a frase de categorias de `.engrama/qa/criticas-do-executor.md`.

## Passo 4 — (opcional) Cabear o gate no harness do Orquestrador

Defesa extra contra `git commit --no-verify`. Se o seu harness suporta hooks (ex.: Claude Code), crie/edite `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [
        { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.engrama/scripts/critique-gate-hook.sh\"" }
      ] }
    ]
  }
}
```

## Passo 5 — Ritual de bootstrap (ADR 0006: a governança se aplica a si mesma)

A governança instalada **é** uma edição de governança → passa pelo próprio gate antes do 1º commit:

1. Revise o Engrama instalado (placeholders trocados, `classify()` adaptado).
2. Rode a **crítica do Executor** (read-only) sobre a governança instalada:
   `<EXECUTOR_CMD> -m <MODELO_CRITICA>` com uma ordem de crítica read-only (sem patch).
3. **Antes de commitar** (logar precede commit): registre a crítica em `.engrama/qa/criticas-do-executor.md` **e** a 1ª entrada em `.engrama/log.md` (substitua o exemplo seed; inclua o próximo passo seguro). A entrada do ledger precisa conter a **branch atual** + as **tags de categoria** tocadas (no 1º commit, tipicamente `[governance][gate]`) + um veredito OK.
4. **Consenso** → aprovação da **Autoridade** → 1º commit (Engrama + ledger + log juntos). **Impasse** → a Autoridade arbitra (o Executor tem voz, não veto).

## Passo 6 — Verificação final (prove que replicou)

- [ ] `grep -rho '{{[A-Z_]*}}' CLAUDE.md AGENTS.md .engrama` retorna **vazio**.
- [ ] `git config core.hooksPath` = `.engrama/githooks`.
- [ ] `.claude/settings.json` existe e chama `.engrama/scripts/critique-gate-hook.sh`.
- [ ] **Teste do gate**: encene um commit tocando `.engrama/governance/` **sem** entrada no ledger para a branch → deve **bloquear** (🚫). Isso confirma que a regra está viva neste projeto.
- [ ] Declare o **handshake** de abertura: papel · alçada · estado factual (topo do `.engrama/log.md`) · próximo passo seguro · o que depende da Autoridade.
- [ ] O repo-alvo ficou com `CLAUDE.md`, `AGENTS.md`, `.engrama/` e `.claude/settings.json` na raiz, sem copiar `docs/engrama/`.
- [ ] `project/bootstrap-do-projeto.md` foi lido e, se ainda estiver `proposed`, o Orquestrador iniciou a entrevista de bootstrap com a Autoridade.

---

## Merge — se o projeto JÁ tinha `CLAUDE.md`/`AGENTS.md`/`.engrama/`

O instalador **recusa sobrescrever**. Nesse caso, faça merge manual:

- **`CLAUDE.md` existente** → intercale a seção `## Gate operacional obrigatório` (ordem de leitura + handshake) e o `## Modelo em uma página` no topo do arquivo atual, preservando o conteúdo do projeto.
- **`.engrama/` existente** → copie só o que falta (`.engrama/governance/`, `.engrama/decisions/0001-0010`, `.engrama/specs/`, `.engrama/qa/criticas-do-executor.md`, e o schema `.engrama/CLAUDE.md` se não houver um) e reconcilie a numeração de ADR.
- **`.engrama/scripts/critique-gate.sh` existente** → reconcilie a `classify()`.
- **`.claude/settings.json` existente** → mescle o hook `PreToolUse` que chama `.engrama/scripts/critique-gate-hook.sh`.
- Depois, rode a substituição de placeholders à mão (ou um `bin/install.sh` apontando para um arquivo de override) e siga do Passo 3.

## Limites honestos (não é zero-touch — por design)

O agente faz **todo o trabalho mecânico** e **propõe tudo**, mas 3 coisas ainda exigem o humano, porque o modelo é construído **em torno da Autoridade humana**:

1. **quem é a Autoridade** de Mudança, quando a inferência não bastar ou estiver errada;
2. o **mapa de superfície sensível** do gate (`classify()`) — depende do domínio;
3. a **aprovação do 1º commit** (e de toda promoção sensível dali em diante).

`EXECUTOR`, `EXECUTOR_CMD` e `MODELO_*` já saem preenchidos com o padrão atual do pack; só mude se o projeto-alvo divergir.

Tudo o mais é automático.
