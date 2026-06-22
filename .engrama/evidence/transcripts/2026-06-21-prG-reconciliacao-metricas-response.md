---
codex-session: 019eecfc-218a-73a0-8993-b37a21ece384
codex-session-source: stream
model: unknown
sandbox: workspace-write
label: prG-reconciliacao-metricas
---

Vou tratar isso como Executor Crítico na branch `feat/absorcao-reconciliacao-metricas`. Primeiro vou reexecutar o gate obrigatório do Engrama, confirmar o estado factual no topo de `.engrama/log.md`, e só depois entro na crítica técnica e na implementação.
Papel: `Executor Crítico`. Alçada: escrever a fatia na branch indicada, criticar a ordem antes de executar, e não tocar `git config/add/commit/checkout` no repo real; estado factual no topo do `log.md`: PR-F fechou o polimento de docs/install e o bootstrap está operacionalmente `ready`; próximo passo seguro: confirmar o padrão atual de ADR/schema/lint/testes e então aplicar a mudança mantendo a paridade raiz↔template; o que depende da Autoridade: a adoção final do ADR 0012 como governança canônica se houver objeção material, além de qualquer ação irreversível ou de produção.

Minha leitura da ordem: a fatia é coerente e autocontenida, mas mexe em governança, schema, lint e contrato de template ao mesmo tempo, então o risco principal é introduzir drift entre raiz e `template/` ou validar `reconcilia:` de um jeito que não respeite o resolvedor já existente. Crítica de mérito do ADR 0012: a decisão é boa se ficar explícito que `reconcilia:` é disciplina humana validável, não mecanismo semântico; o ponto mais forte é reduzir ambiguidade entre "atualiza", "supera" e "reafirma", e o principal cuidado é não vender `ADD/UPDATE/DELETE/NOOP` como deduplicação automática nem confundir `DELETE` com remoção física em vez de supersession documental. Veredito: `concordo`.
Já confirmei a branch e o padrão da casa: há espelho completo de ADRs no `template/`, o schema atual não conhece `reconcilia:` e o lint já tem resolvedor de wikilink reaproveitável. Agora vou fechar a inspeção do resto do lint/testes e editar em lote para evitar drift entre documentação, validação e contrato.
O lint e o contrato já deixam claro onde encaixar a mudança: `reconcilia:` pode reutilizar o mesmo resolvedor de wikilink/slug, e o warning de staleness precisa ficar fora do contador de erros. Antes de editar, vou olhar o `sync-template.sh` e o gate raiz para não quebrar a paridade que `sync.test` cobra.
Encontrei o ponto de atenção de paridade: `sync-template.sh` só propaga scripts e settings, não ADRs nem índices. Então vou espelhar manualmente o ADR 0012 no `template/` e ajustar o `template/.engrama/index.md` só para esse ADR; o gap de métricas fica apenas na instância viva, porque o template hoje não carrega `gaps/` próprios.
Vou entrar em edição agora. O pacote de mudanças será: ADR 0012 raiz+template, schema raiz+template, lint/testes, índice raiz+template, gap só na instância viva, e uma menção curta no gate raiz se ela couber sem virar duplicação de schema.
As edições principais já estão no lugar. Antes da bateria completa, vou fazer uma checagem curta de consistência em `reconcilia:`/staleness e depois sincronizar o template para que `sync.test` compare estado final, não intermediário.
A implementação está fechada e o template já foi sincronizado. Agora vou rodar exatamente a bateria pedida no estado final da branch; se algo falhar, ajusto antes de encerrar.
A sincronização contratual já fechou verde. Ainda estou aguardando a suíte completa, o lint do repo e o `shellcheck`; se aparecer algum desvio, corrijo antes de fechar.
1. `Leitura da ordem`: implementei a fatia de reconciliação explícita de memória e métricas do Engrama na branch `feat/absorcao-reconciliacao-metricas`, sem commit e sem usar `git config`/`git add`/`git commit`/`git checkout` no repo real.

2. `Crítica técnica`: o ADR 0012 tem mérito. Ele melhora rastreabilidade e reduz ambiguidade entre “novo”, “complementa”, “supera” e “reafirma”, desde que fique explícito o limite correto: `reconcilia:` é disciplina validável em markdown, não motor de deduplicação semântica. O cuidado material era não confundir `DELETE` com remoção física nem vender automação que o repo não tem; isso ficou documentado.

3. `Veredito`: `concordo`. Veredito de mérito sobre o ADR 0012: favorável.

4. `Execução`: criei o ADR 0012 raiz+template, documentei `reconcilia:` no schema raiz+template e no gate raiz/template, estendi o lint para validar `reconcilia:` e emitir warning de staleness por último commit (`ENGRAMA_NOW` suportado), nomeei a métrica de órfãs como densidade de enlaces, criei o gap de métricas, atualizei índices e sincronizei o template com `bash bin/sync-template.sh`.

5. `Evidências`:
- `bash tests/run.sh` → verde; inclui `lint.test.sh` com `22` asserts e `sync.test.sh` com `21` asserts.
- `bash .engrama/scripts/lint.sh` → `exit 0`, sem warnings; o check de staleness ficou latente, sem stale hoje.
- `shellcheck -S info bin/*.sh .engrama/scripts/*.sh tests/contract/*.sh tests/gate/*.sh` → limpo.
- `bash tests/contract/sync.test.sh` → `21` asserts, verde.

6. `Pendências`: não comitei, como pedido. Se isso for promovido depois, falta só a entrada correspondente em `.engrama/log.md` no fluxo normal de governança. O worktree também contém um untracked fora da fatia, [transcripts/2026-06-21-prG-reconciliacao-metricas-order.md](/Users/x86/git-projects/engrama/transcripts/2026-06-21-prG-reconciliacao-metricas-order.md), que eu não editei.

**Arquivos tocados**
- [.engrama/decisions/0012-reconciliacao-de-memoria.md](/Users/x86/git-projects/engrama/.engrama/decisions/0012-reconciliacao-de-memoria.md)
- [template/.engrama/decisions/0012-reconciliacao-de-memoria.md](/Users/x86/git-projects/engrama/template/.engrama/decisions/0012-reconciliacao-de-memoria.md)
- [.engrama/gaps/metricas-de-engrama.md](/Users/x86/git-projects/engrama/.engrama/gaps/metricas-de-engrama.md)
- [.engrama/CLAUDE.md](/Users/x86/git-projects/engrama/.engrama/CLAUDE.md)
- [template/.engrama/CLAUDE.md](/Users/x86/git-projects/engrama/template/.engrama/CLAUDE.md)
- [CLAUDE.md](/Users/x86/git-projects/engrama/CLAUDE.md)
- [template/CLAUDE.md](/Users/x86/git-projects/engrama/template/CLAUDE.md)
- [.engrama/index.md](/Users/x86/git-projects/engrama/.engrama/index.md)
- [template/.engrama/index.md](/Users/x86/git-projects/engrama/template/.engrama/index.md)
- [.engrama/scripts/lint.sh](/Users/x86/git-projects/engrama/.engrama/scripts/lint.sh)
- [template/.engrama/scripts/lint.sh](/Users/x86/git-projects/engrama/template/.engrama/scripts/lint.sh)
- [tests/contract/lint.test.sh](/Users/x86/git-projects/engrama/tests/contract/lint.test.sh)
