1. **Leitura da ordem**  
Sou o **Executor Crítico**, com alçada para escrever a fatia e criticar a ordem antes de executar. Estado factual do topo do log: o repo já registrava **P2b** como próximo passo seguro para mitigar **R1** com reexecução server-side do gate no PR. Entendi o objetivo como: adicionar enforcement em `pull_request` sem alterar o comportamento do caminho local do pre-commit.

2. **Crítica técnica**  
A mecânica de menor risco é **não mexer no gate local** e criar um wrapper de CI que o **reutiliza integralmente**. Alterar `.engrama/scripts/critique-gate.sh` exigiria preservar markers do sync/template e aumentaria o risco de regressão em G1–G7/R2–R5 sem ganho funcional.

Há dois caveats honestos:
- O controle agora roda **server-side na CI**, mas o bloqueio de merge como política ainda depende de marcar esse job/check como **required** no GitHub. Isso é fora do código e depende da Autoridade/admin do repositório.
- README/ADR 0006 continuam dizendo “pendente”; não atualizei essa prosa por fronteira explícita da ordem.

3. **Veredito**  
`ajuste-menor`  
Implementei a solução via wrapper `critique-gate-ci.sh` em vez de editar o gate principal. O objetivo foi atendido com menor risco ao modo local.

4. **Execução**  
Criei [critique-gate-ci.sh](/Users/x86/git-projects/engrama/critique-gate-ci.sh:1), que recebe `--branch` e `--files-from`, monta um repo sintético e executa o `critique-gate.sh` local contra esse diff. Isso reaproveita a mesma `classify()` e a mesma checagem do ledger por campo sem duplicar parser.

Adicionei [tests/gate/ci.test.sh](/Users/x86/git-projects/engrama/tests/gate/ci.test.sh:1) com 4 casos: bloqueio sem ledger, liberação com `confirmo` da branch exata, bloqueio de outra branch que cita o nome no texto, e liberação para arquivo não sensível.

Atualizei [.github/workflows/ci.yml](/Users/x86/git-projects/engrama/.github/workflows/ci.yml:21):
- `Checkout` agora usa `fetch-depth: 0`.
- `Run shellcheck` passa a incluir `critique-gate-ci.sh`.
- `Run test suite` permanece igual.
- Em `pull_request`, `Fetch pull request base` busca `origin/<base_ref>`.
- Em `pull_request`, `Re-run critique gate against pull request diff` gera `git diff --name-only -z "origin/${{ github.base_ref }}...HEAD"` e chama o wrapper com `${{ github.head_ref }}`.

Não rodei `sync-template.sh` porque **o gate local não foi alterado**.

5. **Evidências**  
`bash tests/run.sh`
```text
==================== ci.test.sh ====================
Resumo: 4 asserts batidos, 0 divergentes | 0 casos marcados FURO (a corrigir)

==================== critique-gate.test.sh ====================
Resumo: 12 asserts batidos, 0 divergentes | 1 casos marcados FURO (a corrigir)

==================== bootstrap.test.sh ====================
Resumo: 9 asserts batidos, 0 divergentes | 0 casos marcados FURO (a corrigir)

==================== sync.test.sh ====================
Resumo: 5 asserts batidos, 0 divergentes | 0 casos marcados FURO (a corrigir)

TODAS AS SUITES VERDES
```

Prova manual do modo CI:
```text
CASE1
exit=2
🚫 GATE DE CRÍTICA ... — commit BLOQUEADO
Branch: remediacao/p2b-ci-gate
Categorias sensíveis tocadas: governance
Sem crítica CONCLUÍDA (ou com objeção aberta) para: governance

CASE2
exit=0
```

`shellcheck critique-gate-ci.sh tests/gate/ci.test.sh`
```text
# sem saída; exit 0
```

Validação do YAML:
```text
$ ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci.yml"); puts "YAML OK"'
YAML OK
```

6. **Pendências e bloqueios**  
Não há bloqueio técnico para esta fatia. O que depende da Autoridade:
- marcar o check/job da CI como **required** nas regras de branch protection, para o enforcement ficar vinculante no merge;
- decidir se quer uma fatia separada para alinhar README/ADR 0006 ao estado novo, já que a prosa ficou propositalmente intocada por escopo.
