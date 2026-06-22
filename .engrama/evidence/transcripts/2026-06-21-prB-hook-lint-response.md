---
codex-session: 019eeb13-1795-7f40-92cf-3e02e3066e21
codex-session-source: stream
model: unknown
sandbox: workspace-write
label: 2026-06-21-prB-hook-lint
---

1. **Leitura da ordem**  
Entendi a fatia na branch `feat/hook-test-lint-completo`: fechar o item 2 com uma suíte nova para o wrapper [tests/gate/hook.test.sh](/Users/x86/git-projects/engrama/tests/gate/hook.test.sh), e fechar o item 4 ampliando o lint em [.engrama/scripts/lint.sh](/Users/x86/git-projects/engrama/.engrama/scripts/lint.sh), com cobertura contratual em [tests/contract/lint.test.sh](/Users/x86/git-projects/engrama/tests/contract/lint.test.sh), sem alterar a lógica do gate e sem commit.

2. **Crítica técnica antes de executar**  
A ordem está coerente. O único ajuste técnico necessário foi no caso “sem `python3`”: para provar o fail-closed do wrapper eu precisei simular um `PATH` mínimo com `bash/git/grep/...`, removendo só `python3`; se eu removesse tudo, o teste deixaria de validar o wrapper e passaria a validar um ambiente quebrado.  
Também havia um `TODO` cru real em [.engrama/governance/continuidade-de-sessao.md](/Users/x86/git-projects/engrama/.engrama/governance/continuidade-de-sessao.md); como o lint novo passa a bloquear isso, fiz um ajuste textual mínimo ali e no template correspondente para manter o repo verde.

3. **Veredito sobre a ordem**  
`ajuste-menor`

4. **Execução**  
Implementei:
- [tests/gate/hook.test.sh](/Users/x86/git-projects/engrama/tests/gate/hook.test.sh): cobre `git commit -m`, `git commit --no-verify`, `git status`, `ls`, ausência de `python3` e JSON malformado com payload de commit.
- [.engrama/scripts/lint.sh](/Users/x86/git-projects/engrama/.engrama/scripts/lint.sh): adiciona páginas órfãs, gaps de numeração de ADR, `status:` inválido e `TODO/FIXME/XXX` em docs normativos.
- [tests/contract/lint.test.sh](/Users/x86/git-projects/engrama/tests/contract/lint.test.sh): agora prova sensibilidade de cada check novo com pares bloqueia/libera.
- `bash bin/sync-template.sh`: propagou o `lint.sh` novo para `template/.engrama/scripts/lint.sh`.
- Ajuste textual mínimo em [.engrama/governance/continuidade-de-sessao.md](/Users/x86/git-projects/engrama/.engrama/governance/continuidade-de-sessao.md) e [template/.engrama/governance/continuidade-de-sessao.md](/Users/x86/git-projects/engrama/template/.engrama/governance/continuidade-de-sessao.md) para remover `TODO` cru normativo.

5. **Evidências**  
`bash tests/gate/hook.test.sh`
```text
[ok] H1 ... git commit simples ...
[ok] H2 ... git commit --no-verify ...
[ok] H3 ... git status e ignorado
[ok] H4 ... comando nao-git e ignorado
[ok] H5 ... ausencia de python3 ...
[ok] H6 ... JSON malformado ...
Resumo: 6 asserts batidos, 0 divergentes
```

`bash .engrama/scripts/lint.sh`
```text
sem saída; exit 0
```

`bash tests/contract/sync.test.sh`
```text
[ok] S3B ... lint.sh do template identico ao da raiz
Resumo: 13 asserts batidos, 0 divergentes
```

`bash tests/run.sh`
```text
hook.test.sh: 6 asserts batidos, 0 divergentes
lint.test.sh: 17 asserts batidos, 0 divergentes
sync.test.sh: 13 asserts batidos, 0 divergentes
TODAS AS SUITES VERDES
```

`shellcheck`
```text
sem saída; exit 0
```

Sensibilidade dos checks novos ficou provada em `lint.test.sh`:
```text
L10/L11  pagina orfa: bloqueia -> libera
L12/L13  gap de ADR: bloqueia -> libera
L14/L15  status invalido: bloqueia -> libera
L16/L17  TODO normativo: bloqueia; TODO no bootstrap: permitido
```

6. **Pendências e bloqueios**  
Sem bloqueio técnico e sem dependência nova de aprovação da Autoridade nesta fatia. Não comitei.  
Há um untracked pré-existente preservado e não tocado: `transcripts/2026-06-21-2026-06-21-prB-hook-lint-order.md`.
