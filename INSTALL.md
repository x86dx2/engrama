# INSTALL.md — Auto-instalação do Engrama (PLAYBOOK DO AGENTE)

> **Você (agente) está lendo isto** porque a pasta `docs/engrama/` foi copiada para um projeto e pediram para **instalar / configurar o Engrama**. Execute os passos abaixo na ordem. Onde estiver marcado **PERGUNTAR**, pergunte ao humano e **não invente**. Onde estiver **INFERIR**, descubra do repositório e **confirme** com o humano antes de gravar.

Resultado final: o repo passa a ter, na **raiz**, os gates `CLAUDE.md`/`AGENTS.md`, o `.engrama/` de governança, o gate mecânico `.engrama/scripts/critique-gate.sh` ativo, e o primeiro commit feito sob as próprias regras. A partir daí, qualquer agente que abrir o repo cai no gate de governança.

---

## Passo 0 — Pré-condições

1. Estar num repositório git. Se não houver, criar: `git init -b main`.
2. Checar colisão: se já existirem `CLAUDE.md`, `AGENTS.md` ou `.engrama/` na raiz, **não sobrescreva** — vá para a seção **Merge** no fim. Caso contrário, siga.

## Passo 1 — Coletar os valores (INFERIR + PERGUNTAR)

Monte o arquivo de valores. Copie o exemplo e preencha:

```bash
cp docs/engrama/engrama.values.example docs/engrama/.engrama.values
```

Preencha cada chave (sem as chaves `{{ }}`):

| Chave | Como obter | |
|---|---|---|
| `REPO_PATH` | **INFERIR**: `git rev-parse --show-toplevel` | |
| `DATA` | **INFERIR**: data de hoje (`YYYY-MM-DD`) | |
| `PROJETO` | **INFERIR** do nome do diretório / `package.json` / remote git → **confirmar** | |
| `STACK` | **INFERIR** do repo (`package.json`, `go.mod`, `requirements.txt`, `Cargo.toml`, `pom.xml`…) → **confirmar** | |
| `AUTORIDADE` | **INFERIR** de `git config user.email` → **confirmar** quem é a Autoridade de Mudança | |
| `ORQUESTRADOR` | **INFERIR**: você mesmo (o agente que está instalando; ex.: "Claude (Claude Code)") | |
| `DEV_URL` | **INFERIR** de scripts/config (porta do dev) ou **PERGUNTAR** | |
| `EXECUTOR` | **PERGUNTAR**: qual agente fará o papel de Executor Crítico (ex.: "Codex") | |
| `EXECUTOR_CMD` | **PERGUNTAR**: comando que invoca o Executor (ex.: `codex exec`). Dica: cheque o `PATH` (`command -v codex`). | |
| `MODELO_CRITICA` | **PERGUNTAR**: maior modelo aprovado, reservado ao papel de crítica | |
| `MODELO_EXECUTOR_PESADO` | **PERGUNTAR**: modelo forte de execução | |
| `MODELO_EXECUTOR_LEVE` | **PERGUNTAR**: modelo barato/rápido de execução | |

> Os 4 itens de modelo + o `EXECUTOR_CMD` + quem é a `AUTORIDADE` **não são inferíveis com segurança** — pergunte. O resto, infira e confirme. Glossário completo de cada placeholder: [INSTANTIATE.md](INSTANTIATE.md).

## Passo 2 — Rodar o instalador mecânico

```bash
bash docs/engrama/install.sh
```

Ele: copia `template/` → raiz do repo, substitui **todos** os placeholders a partir do `.engrama.values`, e ativa o hook (`core.hooksPath .engrama/githooks`). **Confirme** que a saída diz `Placeholders restantes: ''` (vazio). Se sobrou algum, complete o `.engrama.values` e rode de novo (o instalador recusa sobrescrever — veja Merge).

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
- [ ] **Teste do gate**: encene um commit tocando `.engrama/governance/` **sem** entrada no ledger para a branch → deve **bloquear** (🚫). Isso confirma que a regra está viva neste projeto.
- [ ] Declare o **handshake** de abertura: papel · alçada · estado factual (topo do `.engrama/log.md`) · próximo passo seguro · o que depende da Autoridade.
- [ ] (opcional) remova `docs/engrama/` ou mantenha como referência/fonte do template.

---

## Merge — se o projeto JÁ tinha `CLAUDE.md`/`AGENTS.md`/`.engrama/`

O instalador **recusa sobrescrever**. Nesse caso, faça merge manual:

- **`CLAUDE.md` existente** → intercale a seção `## Gate operacional obrigatório` (ordem de leitura + handshake) e o `## Modelo em uma página` no topo do arquivo atual, preservando o conteúdo do projeto.
- **`.engrama/` existente** → copie só o que falta (`.engrama/governance/`, `.engrama/decisions/0001-0010`, `.engrama/specs/`, `.engrama/qa/criticas-do-executor.md`, e o schema `.engrama/CLAUDE.md` se não houver um) e reconcilie a numeração de ADR.
- **`.engrama/scripts/critique-gate.sh` existente** → reconcilie a `classify()`.
- Depois, rode a substituição de placeholders à mão (ou um `install.sh` apontando para uma cópia limpa) e siga do Passo 3.

## Limites honestos (não é zero-touch — por design)

O agente faz **todo o trabalho mecânico** e **propõe tudo**, mas 4 coisas exigem o humano, porque o modelo é construído **em torno da Autoridade humana**:

1. a ferramenta e os **modelos do Executor** (`EXECUTOR_CMD` / `MODELO_*`);
2. **quem é a Autoridade** de Mudança;
3. o **mapa de superfície sensível** do gate (`classify()`) — depende do domínio;
4. a **aprovação do 1º commit** (e de toda promoção sensível dali em diante).

Tudo o mais é automático.
