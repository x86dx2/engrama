1. **Leitura da ordem**  
Entendi a fatia como: entregar `lint.sh` portável e estrito por padrão, uma suíte de contrato para ele, uma suíte de fuzz determinística para o gate, CI com `bash lint.sh` + `gitleaks` + `markdownlint`, e ajustar `classify()` para tratar `lint.sh` como `gate`, sem mexer na lógica do gate além disso e sem comitar.

2. **Crítica técnica antes de executar**  
A ordem estava coerente. O único ajuste que fiz por conta própria foi propagar `lint.sh` também para `template/`, porque `install.sh` copia `template/` inteiro; deixar o linter só na instância viva criaria drift novo no artefato distribuído. Não houve objeção material.

3. **Veredito sobre a ordem**  
`ajuste-menor`

4. **Execução**  
Implementei [lint.sh](/Users/x86/git-projects/engrama/lint.sh), [tests/contract/lint.test.sh](/Users/x86/git-projects/engrama/tests/contract/lint.test.sh), [tests/gate/fuzz.test.sh](/Users/x86/git-projects/engrama/tests/gate/fuzz.test.sh) e ampliei [.github/workflows/ci.yml](/Users/x86/git-projects/engrama/.github/workflows/ci.yml) com `bash lint.sh`, `gitleaks` e `markdownlint` via [.github/markdownlint-cli2.yaml](/Users/x86/git-projects/engrama/.github/markdownlint-cli2.yaml).  
Também ajustei [.engrama/scripts/critique-gate.sh](/Users/x86/git-projects/engrama/.engrama/scripts/critique-gate.sh) para `lint.sh -> gate`, atualizei [sync-template.sh](/Users/x86/git-projects/engrama/sync-template.sh) para sincronizar `template/lint.sh`, mantive [tests/contract/sync.test.sh](/Users/x86/git-projects/engrama/tests/contract/sync.test.sh) verde e corrigi 2 wikilinks triviais em [.engrama/gaps/auditoria-e-plano-de-remediacao.md](/Users/x86/git-projects/engrama/.engrama/gaps/auditoria-e-plano-de-remediacao.md).

5. **Evidências**  
`bash lint.sh`
```text
(sem saída; exit 0)
```

`bash sync-template.sh`
```text
synced: template/.engrama/scripts/critique-gate.sh
unchanged: template/.engrama/scripts/critique-gate-hook.sh
synced: template/lint.sh
```

`bash tests/run.sh`
```text
==================== critique-gate.test.sh ====================
Resumo: 12 asserts batidos, 0 divergentes | 1 casos marcados FURO (a corrigir)

==================== fuzz.test.sh ====================
Resumo: 200 asserts batidos, 0 divergentes | 0 casos marcados FURO (a corrigir)

==================== lint.test.sh ====================
Resumo: 7 asserts batidos, 0 divergentes | 0 casos marcados FURO (a corrigir)

==================== sync.test.sh ====================
Resumo: 6 asserts batidos, 0 divergentes | 0 casos marcados FURO (a corrigir)

TODAS AS SUITES VERDES
```

`shellcheck lint.sh tests/contract/lint.test.sh tests/gate/fuzz.test.sh`
```text
(sem saída; exit 0)
```

Validação de YAML do workflow
```text
YAML OK: .github/workflows/ci.yml
```

6. **Pendências e bloqueios**  
Sem bloqueios para esta fatia e sem dependência nova de aprovação da Autoridade. A única pendência factual que continua aberta é a já conhecida `R1` do gate local, ainda rastreada por `critique-gate.test.sh`; não foi criada nem agravada por esta entrega. Não comitei.
