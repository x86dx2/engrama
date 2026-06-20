#!/usr/bin/env bash
# install.sh — instalador MECÂNICO do Engrama (parte determinística).
# Copia o template para a raiz do repo-alvo, substitui placeholders e ativa o gate.
# O playbook completo é o INSTALL.md; as partes de JULGAMENTO (mapa do gate em
# classify(), ritual de bootstrap e crítica) são do AGENTE, não deste script.
#
# Uso recomendado:
#   bash ./install.sh /caminho/do/repo-alvo [/caminho/do/values]
#
# Compatibilidade (legado):
#   cd /repo-alvo && bash /caminho/do/engrama/install.sh [/caminho/do/values]
set -u

usage() {
  cat <<'EOF'
Uso:
  bash ./install.sh /caminho/do/repo-alvo [/caminho/do/values]

Se o arquivo de valores não for informado, o instalador procura:
  /caminho/do/repo-alvo/.engrama.values
EOF
}

HERE="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE="$HERE/template"

[ -d "$TEMPLATE" ] || { echo "ERRO: não achei $TEMPLATE"; exit 1; }

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
esac

TARGET_INPUT="${1:-$PWD}"
VALUES_INPUT="${2:-}"

if [ -f "$TARGET_INPUT" ] && [ -z "$VALUES_INPUT" ]; then
  TARGET_DIR="$PWD"
  VALUES="$TARGET_INPUT"
else
  TARGET_DIR="$TARGET_INPUT"
  VALUES="${VALUES_INPUT:-$TARGET_DIR/.engrama.values}"
fi

ROOT="$(git -C "$TARGET_DIR" rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$ROOT" ] || {
  echo "ERRO: repo-alvo inválido: $TARGET_DIR"
  echo "  Rode dentro de um repo git ou inicialize antes com 'git init -b main'."
  exit 1
}
echo "Repo-alvo: $ROOT"

if [ ! -f "$VALUES" ]; then
  echo "ERRO: arquivo de valores não encontrado: $VALUES"
  echo "  Use o bootstrap.sh para inferir defaults ou forneça um arquivo override."
  exit 1
fi

# 1) colisões — não sobrescrever governança/config canônica existente
coll=0
for p in CLAUDE.md AGENTS.md .engrama; do
  if [ -e "$ROOT/$p" ]; then echo "AVISO: $ROOT/$p já existe — não vou sobrescrever (faça merge; ver INSTALL.md)"; coll=1; fi
done
[ -f "$ROOT/.claude/settings.json" ] && {
  echo "AVISO: $ROOT/.claude/settings.json já existe — não vou sobrescrever (faça merge; ver INSTALL.md)"
  coll=1
}
[ "$coll" = 1 ] && { echo "Resolva as colisões e rode de novo."; exit 2; }

# 2) copiar template -> raiz (sem lixo local, ex.: .DS_Store)
rsync -a --exclude '.DS_Store' "$TEMPLATE"/. "$ROOT"/ || { echo "ERRO ao copiar"; exit 1; }
echo "Copiado para a raiz: CLAUDE.md AGENTS.md .engrama/ .claude/settings.json"

# 3) montar um programa sed a partir do values (portável: sed -f, sem -i)
SEDPROG="$(mktemp)"; trap 'rm -f "$SEDPROG"' EXIT
while IFS='=' read -r key val || [ -n "${key:-}" ]; do
  key="$(printf '%s' "${key:-}" | tr -d '[:space:]')"
  case "$key" in ''|\#*) continue;; esac
  val="${val%$'\r'}"                       # tira CR de arquivos salvos em Windows
  printf 's#{{%s}}#%s#g\n' "$key" "$val" >> "$SEDPROG"
done < "$VALUES"

# 4) aplicar a substituição SÓ nos arquivos textuais instalados
find "$ROOT/.engrama" "$ROOT/CLAUDE.md" "$ROOT/AGENTS.md" \
  \( -name '*.md' -o -name '*.sh' -o -name '.gitignore' -o -name 'pre-commit' \) -type f 2>/dev/null \
  | while IFS= read -r f; do
      sed -f "$SEDPROG" "$f" > "$f.govtmp" && mv "$f.govtmp" "$f"
    done

# 5) ativar o gate
chmod +x "$ROOT"/.engrama/scripts/*.sh "$ROOT"/.engrama/githooks/* 2>/dev/null || true
git -C "$ROOT" config core.hooksPath .engrama/githooks
echo "Gate ativado: core.hooksPath=.engrama/githooks"

# 6) relatório
rem="$(grep -rho '{{[A-Z_]*}}' "$ROOT/CLAUDE.md" "$ROOT/AGENTS.md" "$ROOT/.engrama" 2>/dev/null | sort -u | tr '\n' ' ')"
echo ""
echo "Placeholders restantes: '${rem}'  (vazio = ok)"
echo ""
echo "PRÓXIMO (julgamento do AGENTE — ver INSTALL.md):"
echo "  Passo 3) concluir o bootstrap do projeto em .engrama/project/bootstrap-do-projeto.md"
echo "  Passo 4) adaptar classify() em .engrama/scripts/critique-gate.sh às superfícies sensíveis deste projeto"
echo "  Passo 5) revisar/mesclar .claude/settings.json se o projeto já tiver config própria do Claude Code"
echo "  Passo 6) bootstrap: crítica do Executor + ledger + log + aprovação da Autoridade -> 1º commit"
