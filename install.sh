#!/usr/bin/env bash
# install.sh — instalador MECÂNICO do Engrama (parte determinística).
# Roda de dentro de docs/engrama/ no repo-alvo. O playbook completo é o
# INSTALL.md; as partes de JULGAMENTO (mapa do gate em classify(), ritual de bootstrap
# e crítica) são do AGENTE, não deste script.
#
# Uso:  bash docs/engrama/install.sh [caminho/do/.engrama.values]
# Lê os valores de docs/engrama/.engrama.values por padrão.
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE="$HERE/template"
VALUES="${1:-$HERE/.engrama.values}"

[ -d "$TEMPLATE" ] || { echo "ERRO: não achei $TEMPLATE"; exit 1; }

ROOT="$(git -C "$HERE" rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$ROOT" ] || { echo "ERRO: rode dentro de um repo git (faça 'git init -b main' antes)"; exit 1; }
echo "Repo-alvo: $ROOT"

if [ ! -f "$VALUES" ]; then
  echo "ERRO: arquivo de valores não encontrado: $VALUES"
  echo "  cp \"$HERE/engrama.values.example\" \"$HERE/.engrama.values\" e preencha."
  exit 1
fi

# 1) colisões — não sobrescrever governança existente
coll=0
for p in CLAUDE.md AGENTS.md .engrama; do
  if [ -e "$ROOT/$p" ]; then echo "AVISO: $ROOT/$p já existe — não vou sobrescrever (faça merge; ver INSTALL.md)"; coll=1; fi
done
[ "$coll" = 1 ] && { echo "Resolva as colisões e rode de novo."; exit 2; }

# 2) copiar template -> raiz (inclui ocultos: .engrama, .gitignore)
cp -R "$TEMPLATE"/. "$ROOT"/ || { echo "ERRO ao copiar"; exit 1; }
echo "Copiado para a raiz: CLAUDE.md AGENTS.md .engrama/ .gitignore"

# 3) montar um programa sed a partir do values (portável: sed -f, sem -i)
SEDPROG="$(mktemp)"; trap 'rm -f "$SEDPROG"' EXIT
while IFS='=' read -r key val || [ -n "${key:-}" ]; do
  key="$(printf '%s' "${key:-}" | tr -d '[:space:]')"
  case "$key" in ''|\#*) continue;; esac
  val="${val%$'\r'}"                       # tira CR de arquivos salvos em Windows
  printf 's#{{%s}}#%s#g\n' "$key" "$val" >> "$SEDPROG"
done < "$VALUES"

# 4) aplicar a substituição SÓ nos arquivos instalados
find "$ROOT/.engrama" "$ROOT/CLAUDE.md" "$ROOT/AGENTS.md" -type f 2>/dev/null \
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
echo "  Passo 3) adaptar classify() em .engrama/scripts/critique-gate.sh às superfícies sensíveis deste projeto"
echo "  Passo 4) (opcional) cabear PreToolUse em .claude/settings.json"
echo "  Passo 5) bootstrap: crítica do Executor + ledger + log + aprovação da Autoridade -> 1º commit"
