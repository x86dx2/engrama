# ORDEM (FASE 2 — EXECUÇÃO, workspace-write) — implementar o release-gate repo-central-only

Você é o Executor Crítico. **Critique a ordem ANTES de executar**; concorda/ajuste-menor → execute; discordância material → não execute, devolve objeção. Sandbox = workspace-write. Devolva os 6 itens da resposta mínima.

## 1. Objetivo
Implementar a fatia 2 **exatamente conforme o desenho fechado que VOCÊ autorou** em `.engrama/evidence/transcripts/2026-06-24-fase2-release-gate-design-response.md` (leia-o — é a spec). Steps 1–5 do seu fatiamento (CÓDIGO). **NÃO** autore ADR (o Orquestrador autora a governança). **NÃO** faça o bump 0.2.0 (é a fatia 3).

## 2. Estado factual
- Fatia 1 (bridge-hardening) committada (ADR 0013). Branch `feat/disciplina-de-release-0.2.0`.
- O seu desenho fechado define: path `bin/release-gate.sh` root-only; manifest explícito; superfície (payload) incluindo `.markdownlint-cli2.yaml`; interface `--mode ci|warn [--base-ref] [--print-hash]`; acoplamento VERSION⇄CHANGELOG root-only; escape `.engrama/evidence/qa/release-waivers.md` bound-by-hash; CI step no job `test` (PR+ubuntu); zero mudança no template/instalador/hook.

## 3. Escopo da execução (steps 1–5 do seu desenho)
1. **Manifest + gramática do escape** (root-only). O manifest é a fonte de verdade da superfície (NÃO reusar `classify()`).
2. **Generalizar `engrama-diff-hash.sh` com flags EXPLÍCITAS** de include/exclude/manifest. **RISCO CRÍTICO/RESTRIÇÃO DURA:** o `critique-gate.sh` e o `critique-gate-ci.sh` dependem do `engrama-diff-hash.sh` — o comportamento **default (sem as novas flags) deve permanecer BIT-A-BIT idêntico** para os callers atuais. Prove: a suíte inteira (incl. todos os casos do critique-gate + `sync.test`) continua verde, e o `sha256` do critique-gate não muda. Se não der para generalizar sem risco, **prefira um segundo entrypoint/flag opcional** a mudar o caminho default.
3. **`bin/release-gate.sh`** com a lógica de payload/bump/changelog/escape e os exit codes (0 pass/warn, 1 config, 2 policy-violation-ci) do seu desenho.
4. **CI:** step novo no job `test` do `.github/workflows/ci.yml` da raiz, restrito a `pull_request` + `matrix.os == 'ubuntu-latest'`, com fetch do base antes; `bash ./bin/release-gate.sh --mode ci --base-ref "origin/${{ github.base_ref }}"`. Herdar o required-check existente (NÃO mexer em branch protection).
5. **Testes** (não-vácuos): `tests/gate/release-gate.test.sh` com TODA a matriz do seu desenho (payload sem bump→falha; bump+changelog→passa; escape válido→passa; escape stale→falha; VERSION sem heading→falha; release-only→passa; delete conta; rename conta; warn sem base/tag→exit 0 com skip) + `tests/contract/release-surface.test.sh` (manifest bate com o que `sync-template.sh` realmente sincroniza E o `release-gate.sh` root-only NÃO é distribuído) + extensão do `bootstrap.test.sh` (adotante instala/bootstrappa sem o gate e sem novo ponto de falha).

## 4. Restrições e fronteiras (NÃO tocar)
- **NÃO** tocar `VERSION` nem `CHANGELOG.md` (fatia 3).
- **NÃO** colocar `release-gate.sh` sob `.engrama/engine/scripts/` (vazaria pelo sync) — é `bin/release-gate.sh` root-only, fora do payload.
- **NÃO** acoplar a política de release ao `lint.sh` compartilhado.
- **NÃO** mudar o comportamento default do `engrama-diff-hash.sh` para os callers atuais (restrição dura do step 2).
- **NÃO** mexer em `template/**`, `bin/install.sh`, `bin/bootstrap.sh`, hook ou settings de forma que altere o que o adotante recebe.
- **NÃO** autore ADR/governança (prosa normativa é do Orquestrador). Pode adicionar comentários no código.
- **NÃO** mutar git do repo real; smoke só em `mktemp` com `git -C`. **Reverifique `git config user.email` antes de qualquer git op.**

## 5. Critérios de aceite
- `bin/release-gate.sh` implementa o contrato; `--print-hash` reproduzível.
- Suíte inteira VERDE (`bash tests/run.sh`), incluindo os testes novos **não-vácuos** (cada um falha sem a regra correspondente) E **todos os casos pré-existentes do critique-gate + sync.test intactos** (prova da backward-compat do hasher).
- `shellcheck -S info` limpo nos scripts novos/tocados. `lint.sh` exit 0.
- `release-surface.test.sh` prova: manifest ≡ conjunto sincronizado; gate root-only não distribuído.

## 6. Validações esperadas
`bash tests/run.sh`; `shellcheck -S info` (release-gate.sh + engrama-diff-hash.sh + testes novos); `bash .engrama/engine/scripts/lint.sh`; prova explícita da backward-compat do `engrama-diff-hash.sh` (sha256 do critique-gate inalterado); reprodução isolada de ≥1 caso não-vácuo novo.

## 7. Riscos conhecidos
- **#1:** generalizar o `engrama-diff-hash.sh` quebrar o critique-gate (mude só com flags opt-in; default intacto; prove).
- Falso-negativo: esquecer `.markdownlint-cli2.yaml` no manifest (ele É sincronizado).
- Falso-positivo: incluir tooling de mantenedor (`bin/sync-template.sh`) no payload.
- Rename/delete: usar `git diff --raw -z` (old+new path), não só glob.

## 8. O que depende da Autoridade
Nada novo (desenho e direção já aprovados). Commit/PR depois da auditoria + ADR 0014 + crítica-gate.

## 9. Próximo passo seguro após a execução
Orquestrador audita (re-roda gates + prova backward-compat do hasher), autora ADR 0014 + nota no CONTRIBUTING (governança, com sua crítica), registra ledger, e committa a fatia 2.

## 10. Modelo/tier
workspace-write; modelo = default do codex. Tarefa de média/alta complexidade (lógica de gate + backward-compat de script crítico).
