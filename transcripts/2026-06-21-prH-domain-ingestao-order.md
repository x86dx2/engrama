# Ordem ao Executor — PR-H: absorção mem0/Honcho (docs — nomear padrões + ingestão)

Branch já criada: `feat/absorcao-domain-ingestao`. Sandbox: workspace-write. **NÃO comitar.** Critique antes.

## ⚠️ ISOLAMENTO (regra pós-incidente)
NUNCA `git config`/`git add`/`git commit`/`git checkout` no repo real. Smoke com git só em `mktemp` com `git -C`. Não altere a config git do repo real.

## Contexto
Segunda fatia da absorção verificada (Honcho/mem0). Esta é a parte de DOCUMENTAÇÃO: nomear padrões que o engrama JÁ pratica + formalizar o fluxo de ingestão. Zero infra. Use o ADR 0012 (`reconcilia:`, já mergeado) e **dogfoode** `reconcilia: ADD` no frontmatter das páginas novas. Todas as páginas precisam de frontmatter válido (o lint valida `type/status/source_refs` e wikilinks), `source_refs` **relativos à raiz**, e estar **linkadas no `.engrama/index.md`** (senão o lint acusa órfã). Mantenha o estilo denso e cross-linkado (wikilinks `[[...]]`).

## Distinção framework vs instância (siga a convenção do repo — confira como specs/ADRs já são espelhados raiz↔template)
- **Framework (espelhar em `template/` se a convenção do repo espelhar specs/governance):** o spec de ingestão; a extensão de working/long-term em `governance/continuidade-de-sessao.md`; a nota no ADR 0006.
- **Instância-só (só na raiz `.engrama/`, NÃO no template):** as 3 páginas `domain/` — descrevem padrões deste engrama; o adotante cria as suas. Mantenha o template enxuto.
Se discordar dessa divisão, diga o porquê.

## Item 1 — specs/ingestao-memoria-dois-fases.md (framework)
Playbook operacional do fluxo que o engrama já faz implícito, agora formalizado (de mem0): **Fase I** (candidato — formato + pré-checks: tipo da página, frontmatter, source_refs), **Fase II** (reconciliação — busca de duplicata via `grep`/`rg`, árvore de decisão: novo→ADD / complementa→UPDATE / supersede→DELETE+`status: superseded`+ponteiro / reafirma→NOOP). Casa com o campo `reconcilia:` (ADR 0012) e com o workflow "Ingest" do `.engrama/CLAUDE.md`. Teto honesto: dedup é humano + `grep` (escala ~500-1000 fatos), não motor semântico.

## Item 2 — domain/validacao-cruzada-estrutural.md (instância)
Nomeia o padrão (origem conceitual em mem0/AI-memory) e mostra a implementação SUPERIOR no engrama: mem0 usa o MESMO modelo p/ extrair e validar (falha escritor≠auditor); o engrama separa papéis (Executor≠Orquestrador≠Autoridade) + gate mecânico + diff-binding sha256 + enforcement server-side. Linke ADRs 0001/0004/0006/0011 e o ledger. Teto honesto: o gate prova COBERTURA (sha256), não a IDENTIDADE do crítico (furo R1).

## Item 3 — domain/escopo-e-identidade.md (instância)
Mapeia o namespacing multi-camada do mem0 (user/session/agent/org) aos mecanismos concretos do engrama: papel↔user, agente↔papel, `codex-session:<id>`↔session, repo↔org, branch+categoria↔inquiry/escopo do gate. Cross-link com `governance/papeis-e-alcadas` e `critique-gate.sh` (como `classify()` define o escopo visível ao gate).

## Item 4 — domain/ponto-de-vista-e-representacao.md (instância)
Nomeia auto-representação (Orquestrador em `specs/orquestrador` + `governance/`) vs representação-de-outros (crítica do Executor no ledger `qa/`, com o veredito `confirmo|discordo|ajuste-menor` tipificando a observação) — conceito do Honcho (theory-of-mind/observer). **Fase 1 só documentação** (sem mudar schema). Deixe claro que NÃO resolve o teto de identidade do crítico (ADR 0011) — só nomeia o registro.

## Item 5 — working vs long-term (framework: em governance/continuidade-de-sessao.md)
Acrescente uma seção curta nomeando memória **quente** (checkpoint vivo no topo do `log.md`, recompilável) vs **fria** (governance/decisions/specs, muda só via ADR), de Honcho (working vs long-term representation). **Explicitamente SEM decay/expiry** (o engrama rejeita decaimento automático por arquitetura) — a transição quente→fria é consolidação MANUAL via ADR. Espelhe no template se continuidade for espelhada.

## Item 6 — nota no ADR 0006 (framework, raiz+template)
Nota curta cruzando `domain/validacao-cruzada-estrutural`: a separação escritor≠auditor é estrutural (processos/modelos distintos), e o caso mem0 (mesmo modelo extrai+valida) ilustra por contraste por que a tríade importa.

## Item 7 — index + cross-links
Adicione TODAS as páginas novas ao `.engrama/index.md` (crie uma seção `domain/` se não houver) e garanta que cada `domain/` linke sua fonte no repo (convenção do schema: domain sempre linka a fonte). Rode o lint p/ confirmar zero órfãs/wikilinks quebrados.

## Saída
Liste arquivos tocados + a divisão framework/instância que você aplicou. Rode `bash tests/run.sh`, `bash .engrama/scripts/lint.sh` (deve ficar 0, sem órfã/wikilink quebrado), `shellcheck -S info` se tocar script, `bash tests/contract/sync.test.sh`.
