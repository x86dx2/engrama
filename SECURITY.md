# Security Policy

Para reportar uma vulnerabilidade, use o **GitHub Security Advisories** deste repositório
(aba **Security → Report a vulnerability**, que abre um relato **privado** ao mantenedor)
ou, na ausência dele, abra uma issue mínima pedindo um canal privado **sem incluir o
detalhe sensível**. Não divulgue publicamente antes da correção.

Escopo honesto:

- O gate local (`critique-gate.sh`) é **cooperativo** — atrito útil no fluxo, deliberadamente
  burlável (`--no-verify`, fora do harness). Não é uma barreira de segurança por si só.
- O enforcement **vinculante** é o check de CI que reexecuta o gate contra o PR, marcado
  como **`required`** no branch protection. O **modo estrito** do diff-binding está
  religado na CI: o fingerprint vem do **diff real do PR** (`--range <base>...HEAD`),
  não do repo sintético. Em PRs com múltiplos commits, a cobertura é do **diff cumulativo**.
- Este repositório não deve receber **segredos** em commits, fixtures, docs ou exemplos
  (varredura `gitleaks` no CI). `.env`/`.env.*` e `.engrama.values` são **gitignored**;
  `.env` também é **negado de leitura** no harness (`.claude/settings.json`).
