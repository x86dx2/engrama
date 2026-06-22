#!/usr/bin/env bash
# install.sh — instalador MECÂNICO do Engrama (parte determinística).
# Copia o template para a raiz do repo-alvo, substitui placeholders e ativa o gate.
# O playbook completo é o docs/INSTALL.md; as partes de JULGAMENTO (mapa do gate em
# classify(), ritual de bootstrap e crítica) são do AGENTE, não deste script.
#
# Uso recomendado:
#   bash ./bin/install.sh /caminho/do/repo-alvo [/caminho/do/values]
#
# Compatibilidade (legado):
#   cd /repo-alvo && bash /caminho/do/engrama/bin/install.sh [/caminho/do/values]
set -u

escape_sed_replacement() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/&/\\&/g; s/#/\\#/g'
}

report_remaining_placeholders() {
  local root="$1" rem
  rem="$(grep -rho '{{[A-Z_]*}}' "$root/CLAUDE.md" "$root/AGENTS.md" "$root/.engrama" 2>/dev/null | sort -u | tr '\n' ' ' || true)"
  echo ""
  echo "Placeholders restantes: '${rem}'  (vazio = ok)"
  echo ""
  [ -z "$rem" ]
}

run_integrity_smoke() {
  local root="$1" failed=0 rel out rc
  echo "Smoke de integridade (syntax-check + diff-hash):"
  for script in \
    "$root/.engrama/engine/scripts/critique-gate.sh" \
    "$root/.engrama/engine/scripts/engrama-diff-hash.sh" \
    "$root/.engrama/engine/scripts/critique-gate-hook.sh" \
    "$root/.engrama/engine/scripts/lint.sh" \
    "$root/.engrama/engine/scripts/critique-gate-ci.sh"
  do
    rel="${script#"$root"/}"
    out="$(bash -n "$script" 2>&1)"
    rc=$?
    if [ "$rc" -eq 0 ]; then
      echo "  OK    bash -n $rel"
    else
      echo "  FALHA bash -n $rel"
      printf '    %s\n' "$out"
      failed=1
    fi
  done

  out="$(cd "$root" && bash ./.engrama/engine/scripts/engrama-diff-hash.sh 2>&1)"
  rc=$?
  if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -Eq '^sha256:[0-9a-f]{64}$'; then
    echo "  OK    engrama-diff-hash.sh -> $out"
  else
    echo "  FALHA engrama-diff-hash.sh"
    printf '    %s\n' "${out:-<vazio>}"
    failed=1
  fi
  echo ""
  return "$failed"
}

usage() {
  cat <<'EOF'
Uso:
  bash ./bin/install.sh /caminho/do/repo-alvo [/caminho/do/values]

Se o arquivo de valores não for informado, o instalador procura:
  /caminho/do/repo-alvo/.engrama.values
EOF
}

HERE="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE="$HERE/../template"

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
  echo "  Use o bin/bootstrap.sh para inferir defaults ou forneça um arquivo override."
  exit 1
fi

# 1) colisões — não sobrescrever governança/config canônica existente
coll=0
for p in CLAUDE.md AGENTS.md .engrama; do
  if [ -e "$ROOT/$p" ]; then echo "AVISO: $ROOT/$p já existe — não vou sobrescrever (faça merge; ver docs/INSTALL.md)"; coll=1; fi
done
[ -f "$ROOT/.claude/settings.json" ] && {
  echo "AVISO: $ROOT/.claude/settings.json já existe — não vou sobrescrever (faça merge; ver docs/INSTALL.md)"
  coll=1
}
[ "$coll" = 1 ] && { echo "Resolva as colisões e rode de novo."; exit 2; }

# 2) copiar template -> raiz (sem lixo local, ex.: .DS_Store)
rsync -a --exclude '.DS_Store' "$TEMPLATE"/. "$ROOT"/ || { echo "ERRO ao copiar"; exit 1; }
echo "Copiado para a raiz: CLAUDE.md AGENTS.md .engrama/ .claude/settings.json"

# 3) montar um programa sed a partir do values (portável: sed -f, sem -i)
SEDPROG="$(mktemp)" || { echo "ERRO ao criar arquivo temporário"; exit 1; }
trap 'rm -f "$SEDPROG"' EXIT
while IFS='=' read -r key val || [ -n "${key:-}" ]; do
  key="$(printf '%s' "${key:-}" | tr -d '[:space:]')"
  case "$key" in ''|\#*) continue;; esac
  val="${val%$'\r'}"                       # tira CR de arquivos salvos em Windows
  val="$(escape_sed_replacement "$val")" || {
    echo "ERRO ao preparar valor do placeholder: $key"
    exit 1
  }
  printf 's#{{%s}}#%s#g\n' "$key" "$val" >> "$SEDPROG" || {
    echo "ERRO ao montar programa de substituição"
    exit 1
  }
done < "$VALUES"

# 4) aplicar a substituição SÓ nos arquivos textuais instalados
apply_failed=0
while IFS= read -r -d '' f; do
  if ! sed -f "$SEDPROG" "$f" > "$f.govtmp"; then
    rm -f "$f.govtmp"
    echo "ERRO ao substituir placeholders em: $f"
    apply_failed=1
    break
  fi
  if ! mv "$f.govtmp" "$f"; then
    rm -f "$f.govtmp"
    echo "ERRO ao gravar arquivo substituído: $f"
    apply_failed=1
    break
  fi
done < <(
  find "$ROOT/.engrama" "$ROOT/CLAUDE.md" "$ROOT/AGENTS.md" -type f \
    \( -name '*.md' -o -name '*.sh' -o -name '.gitignore' -o -name 'pre-commit' -o -name 'VERSION' \) \
    -print0 2>/dev/null
)
[ "$apply_failed" -eq 0 ] || {
  report_remaining_placeholders "$ROOT"
  exit 1
}

# 5) ativar o gate
chmod +x "$ROOT"/.engrama/engine/scripts/*.sh "$ROOT"/.engrama/engine/githooks/* 2>/dev/null || true
git -C "$ROOT" config core.hooksPath .engrama/engine/githooks
echo "Gate ativado: core.hooksPath=.engrama/engine/githooks"

# 6) relatório
if ! report_remaining_placeholders "$ROOT"; then
  echo "ERRO: substituição incompleta; abortando."
  exit 1
fi
if [ -f "$ROOT/.engrama/VERSION" ]; then
  printf 'Versao instalada do pack: %s\n' "$(sed -n '1{s/\r$//;p;q;}' "$ROOT/.engrama/VERSION" 2>/dev/null)"
fi
if run_integrity_smoke "$ROOT"; then
  echo "Smoke de integridade: OK"
else
  echo "AVISO: smoke de integridade encontrou falhas no artefato instalado. Revise os itens FALHA acima."
fi
echo ""
echo "PRÓXIMO (julgamento do AGENTE — ver docs/INSTALL.md):"
echo "  Passo 3) concluir o bootstrap do projeto em .engrama/memory/project/bootstrap-do-projeto.md"
echo "  Passo 4) adaptar classify() em .engrama/engine/scripts/critique-gate.sh às superfícies sensíveis deste projeto"
echo "  Passo 5) revisar/mesclar .claude/settings.json se o projeto já tiver config própria do Claude Code"
echo "  Passo 6) bootstrap: crítica do Executor + ledger + log + aprovação da Autoridade -> 1º commit"
echo "  Passo 7) ativar enforcement server-side (push + branch protection — ver docs/INSTALL.md/INSTANTIATE.md)"
echo "  Passo 8) revisar/apagar o exemplo seed em .engrama/log.md e .engrama/evidence/qa/criticas-do-executor.md"
