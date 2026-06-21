1. **Leitura da ordem**  
Entendi a fatia como: mecanizar a transparência do executor-bridge sem tocar os transcripts históricos existentes, sem mudar a lógica do gate além do `classify()`, sem chamar o `codex` real nos testes e sem commit.

2. **Crítica técnica antes de executar**  
A ordem estava executável, mas com um ajuste menor necessário: se as ADRs do template passassem a afirmar transparência mecanizada por `bin/exec-bridge.sh`, o template também precisava distribuir esse wrapper e um `transcripts/README.md`; sem isso, a doc do template ficaria em overclaim.  
Também tentei inspecionar `codex exec --json` ao vivo, mas o CLI falhou neste ambiente com `failed to initialize in-process app-server client: Operation not permitted`; por isso ancorei o parser em sessões reais já persistidas em `~/.codex/sessions/*.jsonl`, onde o id aparece em `session_meta.payload.id`, o modelo em `turn_context.payload.model` e a resposta em `response_item.payload.message.content[].output_text`.

3. **Veredito sobre a ordem**  
`ajuste-menor`

4. **Execução**  
Implementei [bin/exec-bridge.sh](/Users/x86/git-projects/engrama/bin/exec-bridge.sh), com `--order`, `--label`, `--sandbox`, `--date`, passthrough de flags extras, captura `--json`, extração de `codex-session`, fallback `derived`, gravação em `transcripts/` e stdout no formato pedido.  
Adicionei [tests/contract/exec-bridge.test.sh](/Users/x86/git-projects/engrama/tests/contract/exec-bridge.test.sh), propaguei o wrapper ao template via [bin/sync-template.sh](/Users/x86/git-projects/engrama/bin/sync-template.sh), criei [template/transcripts/README.md](/Users/x86/git-projects/engrama/template/transcripts/README.md), ajustei o gate do template para classificar `bin/exec-bridge.sh` como `gate`, e atualizei ADR 0003/0011 + [criticas-do-executor.md](/Users/x86/git-projects/engrama/.engrama/qa/criticas-do-executor.md) para transparência mecanizada e `codex-session:<id>` como evidência fraca.  
`.gitignore` ficou inalterado e continua sem ignorar `transcripts/`.

5. **Evidências**  
`bash tests/contract/exec-bridge.test.sh`
```text
[ok] E1 ... salva order+response ...
[ok] E2 ... response.md carrega cabecalho YAML ...
[ok] E3 ... stdout imprime ... codex-session:<id>
[ok] E4 ... deriva um id ... derived
[ok] E5 ... falta de --order ...
[ok] E6 ... falta de --label ...
Resumo: 6 asserts batidos, 0 divergentes
```

`bash tests/run.sh`
```text
TODAS AS SUITES VERDES
```

`shellcheck bin/exec-bridge.sh tests/contract/exec-bridge.test.sh`
```text
sem saida; exit 0
```

`bash ./.engrama/scripts/lint.sh`
```text
sem saida; exit 0
```

`bash tests/contract/sync.test.sh`
```text
[ok] S1 ...
...
[ok] S5 ...
Resumo: 13 asserts batidos, 0 divergentes
```

Demo com stub:
```text
transcripts/2026-06-21-demo-order.md
transcripts/2026-06-21-demo-response.md
codex-session:demo-session-20260621
```

O response gerado ficou com o cabeçalho esperado em [transcripts/2026-06-21-demo-response.md](/Users/x86/git-projects/engrama/transcripts/2026-06-21-demo-response.md).

6. **Pendências e bloqueios**  
Não houve bloqueio material e não comitei. Permanecem no working tree os arquivos alterados desta fatia e os transcripts de demo `transcripts/2026-06-21-demo-{order,response}.md`; os transcripts históricos preexistentes não foram modificados.
