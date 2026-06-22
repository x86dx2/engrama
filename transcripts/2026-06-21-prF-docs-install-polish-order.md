# Ordem ao Executor — PR-F (P2/P3): polimento de docs/install do bootstrap

Branch já criada: `feat/p3-docs-install-polish`. Sandbox: workspace-write. **NÃO comitar.** Critique antes; escale se discordar.

## ⚠️ ISOLAMENTO (incidente real nesta sessão)
NUNCA rode `git config`/`git add`/`git commit`/`git checkout` no repo de trabalho. Todo smoke/teste com git roda em `T=$(mktemp -d)` com `git -C "$T"` e identidade só no temp. Não altere a config git do repo real. (O `bin/install.sh` já usa `git -C "$ROOT"` corretamente — mantenha esse padrão.)

Última fatia da remediação da auditoria de prontidão. Itens P2/P3 restantes, todos baratos.

## F1 — Tabela de placeholders completa (INSTANTIATE Passo 2)
A tabela do Passo 2 em `docs/INSTANTIATE.md` lista 13 dos placeholders, mas o template usa 17 (faltam `{{CMD_DEV}}`, `{{CMD_BUILD}}`, `{{CMD_TEST}}`, `{{FINALIDADE_DO_PROJETO}}`). Por isso o próprio checklist da doc ("`grep` retorna vazio") falha no caminho manual.
- Reconcilie a tabela para conter **exatamente** os placeholders que aparecem no `template/` (rode `grep -rho '{{[A-Z_]*}}' template | sort -u` para a lista canônica). Use `engrama.values.example` (raiz) como fonte dos exemplos de valor (ex.: `CMD_DEV=npm run dev`, `CMD_TEST=npm test`, `FINALIDADE_DO_PROJETO=...`).
- Acrescente uma linha apontando `engrama.values.example` como o **inventário canônico** dos placeholders (pra quem segue o caminho manual conferir contra ele).

## F2 — install.sh: smoke de integridade + checklist pós-instalação completo
Em `bin/install.sh` (hoje termina num bloco "PRÓXIMO" com passos 3-6):
1. **Smoke de integridade** (sem efeito colateral, sem commit): antes do relatório final, valide que os scripts críticos copiados pro alvo não vieram truncados — `bash -n` (syntax-check) em `$ROOT/.engrama/scripts/critique-gate.sh`, `engrama-diff-hash.sh`, `critique-gate-hook.sh`, `lint.sh` e `$ROOT/bin/critique-gate-ci.sh`; e uma invocação seca de `engrama-diff-hash.sh` no alvo provando que emite `sha256:<hex>` (ex.: contra um índice vazio/HEAD, o que não cria commit). Se algo falhar, avise claramente (não precisa abortar se o resto foi ok — mas reporte).
2. **Estenda o checklist final** para incluir o passo server-side que o PR-E adicionou e a limpeza do exemplo seed: acrescente "Passo 7) ativar enforcement server-side (push + branch protection — ver docs/INSTALL.md/INSTANTIATE.md)" e "Passo 8) revisar/apagar o exemplo seed em `.engrama/log.md` e `.engrama/qa/criticas-do-executor.md`". Mantenha o estilo das linhas existentes.

## F3 — Nota de numeração de ADR (CONTRIBUTING.md)
`CONTRIBUTING.md` não diz nada sobre ADRs. O template distribui os ADRs `0001-0011` (que documentam o PRÓPRIO modelo de governança — referência valiosa, mantenha). Adicione uma nota curta: os ADRs `0001-00NN` que vêm no pack são **referência do framework** (o porquê do modelo); os ADRs **do seu projeto começam em 0012**. (Confirme o maior número de ADR existente em `.engrama/decisions/` e use NN+1 como o "começa em".)

## F4 — (pequeno) fidelidade do INSTANTIATE Passo 1 + CLAUDE.md
- `docs/INSTANTIATE.md` Passo 1: a lista "Ficam na raiz" não menciona `transcripts/` (o `cp -R` o traz). Acrescente-o para fidelidade.
- `template/CLAUDE.md` (e raiz, se fizer sentido manter espelhado): uma linha curta deixando claro que as categorias universais (governance/gate/contract) **nascem protegidas** e que adaptar `classify()` às superfícies do domínio é **obrigação do adotante** (cross-ref ao gate). Só se não ficar redundante com o que o PR-D já colocou no `classify()`.

## Saída esperada
Liste os arquivos tocados. Rode: `bash tests/run.sh`, `bash .engrama/scripts/lint.sh`, `shellcheck` (incl. `bin/install.sh`), `bash tests/contract/sync.test.sh`. Prove o smoke de integridade rodando `bash bin/install.sh` num `mktemp` (com `git -C`) e mostrando o checklist + a checagem de integridade no output. Diga o que não foi exercível localmente.
