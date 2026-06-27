---
codex-session: 019f0995-de3b-7003-82d5-2fc43f06a300
codex-session-source: stream
model: unknown
sandbox: read-only
label: 2026-06-27-pr16-critica-agregado
---

Vou cumprir o gate do repositório primeiro, em modo somente leitura, e só depois inspecionar o diff agregado solicitado.
Gate lido até o bootstrap: estou no papel de Executor Crítico em crítica read-only. O bootstrap está `active`, então posso seguir para apurar o topo do log e o estado git antes de revisar o agregado.
Handshaking conforme governança: papel assumido = Executor Crítico em crítica independente; alçada = leitura/análise read-only, sem editar, sem commitar, sem arbitrar merge. Estado factual do topo do log = branch `feat/disciplina-de-release-0.2.0` marcada como PR-ready para release 0.2.0, com push/PR/merge e tag `v0.2.0` dependentes da Autoridade; próximo passo seguro = inspecionar `origin/main...HEAD` e emitir veredito do agregado.
O estado git está limpo para arquivos rastreados no `HEAD` do PR, mas há um arquivo não rastreado de transcript da própria ordem atual fora do diff (`.engrama/evidence/transcripts/2026-06-27-...`). Vou ignorá-lo na crítica do agregado porque `origin/main...HEAD` não o inclui.
O fingerprint do diff combinado bate exatamente com a ordem (`sha256:c2752...d49ee8a`). Agora vou checar os pontos de acoplamento: gate de release, hasher, bridge, paridade raiz↔template e cobertura do changelog contra `v0.1.0..HEAD`.
A paridade raiz↔template dos dois scripts relevantes (`engrama-diff-hash.sh` e `exec-bridge.sh`) comparou sem diferença. Vou agora conferir o ledger de críticas e as ADRs/documentos novos para ver se o agregado está honestamente registrado e sem contradições internas.
A tentativa de executar `release-gate.sh --mode ci` bateu numa limitação do sandbox read-only daqui: o Bash não conseguiu criar arquivo temporário para um heredoc interno. Como inspeção, o `--print-hash` funcionou, então vou tratar a execução do gate como não reexecutada localmente e continuar por leitura/contrato.
O `git diff --check` sinalizou espaços finais em transcripts versionados, não em código/prosa normativa. Vou separar isso de regressão funcional: evidência verbatim pode carregar formatação da resposta original, e o lint do projeto já trata transcripts como evidência, não texto autoral.
A seção `0.1.0` do `CHANGELOG.md` bate por hash com a seção `0.1.0` da tag `v0.1.0`; a divergência inicial que tentei comparar era por ter incluído cabeçalho/topo do arquivo da tag, que naturalmente não é idêntico ao arquivo pós-0.2.0.
A fronteira repo-central-only parece preservada: `release-gate`, manifest e waivers estão rastreados só na raiz; `template/` não contém esses artefatos. Também confirmei que apenas os scripts compartilhados esperados aparecem dos dois lados.
Achei uma possível ressalva documental fora do eixo principal: a tabela manual em `docs/INSTANTIATE.md` ainda usa `0.1.0` como exemplo de `ENGRAMA_VERSION`. O caminho automático está correto porque lê `VERSION`; vou tratar isso como não bloqueante se não houver outro acoplamento.
**Leitura da ordem:** critiquei apenas o agregado `origin/main...HEAD`, sem editar nada.

**Achados não bloqueantes:**

- `bin/release-gate.sh:188`: em sandbox read-only, `bash ./bin/release-gate.sh --mode ci --base-ref origin/main` saiu `0`, mas emitiu `cannot create temp file for here document`. O agregado não depende de waiver e a CI normal deve ter `/tmp` gravável, então não é bloqueante; ainda assim, o parser de waiver deveria evitar heredoc/tempfile ou pular waiver quando `VERSION+CHANGELOG` já validam a release.

- `engrama.values.example:8` e `docs/INSTANTIATE.md:34`: ainda mostram `ENGRAMA_VERSION=0.1.0`, enquanto `VERSION:1` é `0.2.0`. O caminho automático está correto (`docs/INSTALL.md:28` aponta `cat /caminho/do/engrama/VERSION`), mas copiar o example como override pode instalar versão velha. Ressalva documental.

**Conferências principais:**

- Fingerprint do agregado bate: `sha256:c2752cf0039794c8deccb384187b58885170e15a6d5c932eb42cfb680d49ee8a`.
- `CHANGELOG.md:9` / `VERSION:1`: release `0.2.0` coerente; a seção `0.1.0` atual bate por hash com a seção `0.1.0` de `v0.1.0`.
- Paridade raiz↔template OK para `exec-bridge.sh` e `engrama-diff-hash.sh`.
- `release-gate` permaneceu root-only; não apareceu em `template/`.
- Ledger tem críticas fortes das 3 fatias (`.engrama/evidence/qa/criticas-do-executor.md:228`, `:235`, `:243`); falta só registrar esta crítica agregada com o hash `c2752...` antes do merge.

VEREDITO: ressalvas
