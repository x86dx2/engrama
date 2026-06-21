Você é o EXECUTOR (Executor Crítico). Tier T3 (sensível: instalador do pack). Critique a ordem antes de executar; se concordar, execute. cwd = raiz do repo "engrama".

ORDEM (10 itens):
1. OBJETIVO: corrigir o `install.sh` para que a substituição de placeholders `{{CHAVE}}` seja segura a valores contendo `#`, `&`, `\`, `/`, espaço — substituindo LITERALMENTE — e seja FAIL-CLOSED (abortar com exit!=0 se qualquer substituição falhar, em vez de retornar exit 0 com placeholders crus).
2. ESTADO FACTUAL: bug comprovado por `tests/contract/bootstrap.test.sh` (casos C5/C6/C7). Hoje o install monta um programa `sed -f` com linhas `s#{{K}}#VALOR#g`: um `#` no VALOR faz o `sed -f` falhar GLOBAL (todos os 16 placeholders ficam crus) e o install ainda retorna exit 0; um `&` no VALOR corrompe (`Tom & Jerry` vira `Tom {{PROJETO}} Jerry`). A construção problemática está na montagem do SEDPROG e no loop `find ... | while ... sed -f`.
3. ESCOPO: editar APENAS `install.sh`. Não comitar. Não criar arquivos novos.
4. FRONTEIRAS (não tocar): não edite `tests/**` (a quebra dos asserts C5/C6/C7 é o SINAL de sucesso — quem promove os testes é o Orquestrador); não toque em `bootstrap.sh`, `.engrama/**`, `template/**`. Preserve a interface de uso, as mensagens, e o relatório final "Placeholders restantes". Mantenha PORTABILIDADE macOS(BSD)/Linux(GNU): nada de `sed -i` GNU-only; PREFIRA escapar o valor para `sed` (escapar `\`, `&` e o delimitador `#`, nessa ordem) ou usar `awk` com replacement literal; NÃO adicione dependência nova pesada (evite exigir `perl` se sed/awk resolvem).
5. CRITÉRIOS DE ACEITE:
   - `bash tests/contract/bootstrap.test.sh`: C1–C4 e C8 seguem verdes; C5, C6, C7 agora DIVERGEM ([XX]) porque o bug sumiu (eles afirmam o comportamento quebrado).
   - prova manual: instalar com `PROJETO=Tom & Jerry` e `AUTORIDADE=Humano (a#b.com)` deve gravar os valores LITERAIS e deixar ZERO placeholders crus.
   - valor com `/` e com espaço preservados.
   - se alguma substituição falhar, `install.sh` retorna exit != 0 (não 0).
6. VALIDAÇÕES ESPERADAS: rode `shellcheck install.sh` (deve ficar limpo) e `bash tests/contract/bootstrap.test.sh`; cole as saídas.
7. RISCOS CONHECIDOS: escaping incorreto pode reintroduzir corrupção; o fail-closed não pode quebrar o caminho-feliz (C1–C4/C8 têm que continuar verdes).
8. DEPENDE DA AUTORIDADE: o commit (não é seu; é do Orquestrador após auditoria).
9. PRÓXIMO PASSO: o Orquestrador re-roda os testes, promove C5/C6/C7 ao comportamento correto e leva ao commit.
10. TIER/MODELO: T3 (modelo default do executor; effort alto — superfície sensível).

RESPONDA nos 6 itens do Executor: (1) leitura; (2) crítica técnica ANTES de executar; (3) veredito `concordo|ajuste-menor|discordo`; (4) execução (o que editou); (5) evidências (saídas de shellcheck + testes); (6) pendências. Em português.
