Você é o EXECUTOR, no papel de CRÍTICA (read-only, sem produzir patch). O Orquestrador autorou uma mudança de GOVERNANÇA e a submete à sua crítica ANTES do commit (ADR 0006: governança não se autoaprova). cwd = raiz do repo "engrama".

ORDEM (crítica, não execução):
1. Objetivo: validar criticamente o plano de remediação e as duas suítes de teste recém-criadas antes de comitar.
2. Estado factual: auditoria de 3 fontes apontou furos no gate (grep/substring, sem vínculo ao diff, fail-open) e no instalador (sed quebra com '#'/'&'). Foram escritos testes que comprovam os furos empiricamente.
3. Escopo da crítica (leia estes arquivos):
   - .engrama/gaps/auditoria-e-plano-de-remediacao.md  (o plano)
   - tests/gate/critique-gate.test.sh  (suíte do gate)
   - tests/contract/bootstrap.test.sh  (contract do instalador)
   - .engrama/scripts/critique-gate.sh e install.sh  (os alvos)
4. Fronteiras: NÃO edite nada; não produza patch aplicável; só avalie/refute.
5. Critérios de aceite da crítica: aponte (a) erros factuais nos achados; (b) testes que NÃO provam o que afirmam (falso-positivo de teste) ou que estão frágeis; (c) ações de remediação tecnicamente incorretas ou arriscadas (ex.: o sha256-do-diff-staged é sólido? `-z`+`read -d ''` resolve mesmo o non-ASCII? `awk -F'|'` para enum tem armadilha? a CI server-side é a primitiva certa?); (d) qualquer furo que faltou; (e) prioridade errada.
6. Validações esperadas: se possível, rode `bash tests/run.sh` e confira se passa; rode `shellcheck` nos testes.
7. Riscos conhecidos: o gate é a peça central; um fix errado piora a segurança.
8. Depende da Autoridade: aprovação do commit.
9. Próximo passo após a crítica: registrar no ledger e comitar (se consenso) ou escalar (se discordância material).

RESPONDA nos 6 itens do Executor: (1) Leitura da ordem; (2) Crítica técnica (o mais importante — seja cético e específico, cite arquivo:linha); (3) Veredito: `concordo` | `ajuste-menor` (liste os ajustes) | `discordo` (justifique); (4) Execução: N/A (crítica read-only); (5) Evidências (comandos que rodou e saídas); (6) Pendências/próximo passo. Responda em português, objetivo.
