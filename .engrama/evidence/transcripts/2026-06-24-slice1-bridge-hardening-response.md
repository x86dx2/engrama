---
codex-session: 019efa06-f95c-7b20-a3ce-99166ff7aff0
codex-session-source: stream
model: unknown
sandbox: workspace-write
label: slice1-bridge-hardening
---

Papel assumido: Executor Crítico. Vou reabrir o gate obrigatório do Engrama na ordem prescrita, confirmar o estado factual no topo do `.engrama/log.md`, e só então criticar a ordem e executar a fatia.
Gate relido até a cadeia de comando. Agora vou confirmar os princípios operacionais, continuidade de sessão, bootstrap do projeto e o estado factual no topo do log antes de mexer na fatia.
Papel: Executor Crítico. Alçada: escrever a fatia, criticar a ordem antes da execução, sem tocar release/governança nem mutar git fora do escopo; estado factual no topo do log: há um break-glass já aplicado no `exec-bridge` por drift de schema do `codex-cli 0.142.0`, com review retroativo pendente e próxima fatia definida como teste de contrato contra o stream real.

Próximo passo seguro: inspecionar `exec-bridge.sh`, `sync-template.sh` e a suíte de contrato para confirmar se os stubs atuais ainda refletem o schema antigo e então implementar um teste não-vácuo. O que depende da Autoridade: nada novo nesta fatia, salvo eventual objeção material se eu encontrar correção insegura no break-glass.
A suíte atual já mostra o problema estrutural: E1-E7 usam `response_item`/`session_meta`/`turn_context`, ou seja, o schema antigo. Vou confirmar o diff do break-glass, o estado de paridade runtime↔template e então fechar um teste que exerça o JSONL real do 0.142.0.
Vou reproduzir a suíte atual do bridge antes de editar para registrar o ponto de partida. A expectativa é ela estar verde apesar de o caminho principal ainda exercitar majoritariamente o schema legado, o que confirma a vacuidade suspeita.
Crítica técnica antes da execução: a ordem está coerente e o risco principal é real e já confirmado, porque a suíte passa verde com happy path ainda preso ao schema antigo. Há três cuidados operacionais: o worktree já está sujo pelo break-glass do Orquestrador, então vou preservar exatamente esse diff; o novo contrato precisa provar o caso real sem deixar o fallback do session file “salvar” um parser errado; e não há fonte confiável de `model` no stream novo, então qualquer captura além de `unknown`/args seria invenção.

Veredito: `ajuste-menor`. Assumo os ajustes implícitos de implementação: vou modernizar o caminho principal do teste para o JSONL real do `0.142.0`, manter um caso explícito de compat retroativa com o schema antigo, e documentar no próprio teste a prova de não-vacuidade comparando com o parser legado.
Vou editar só a suíte de contrato do bridge. A mudança é concentrada: trocar o stub feliz principal para o JSONL real do `codex-cli 0.142.0`, adicionar a prova de regressão contra o parser legado e manter um caso explícito de compatibilidade com o schema antigo.
O teste principal já ficou alinhado ao stream real. Falta só modernizar o caso E8 para o mesmo schema novo; depois disso eu rodo a suíte do bridge e os gates completos.
O caso novo passou isoladamente. Agora vou rodar os gates pedidos: suíte inteira, `shellcheck` nos scripts relevantes, `lint.sh`, e uma reprodução isolada do não-vácuo para sair com evidência direta do parser novo vs legado.
`shellcheck` só reclamou de dois literais com backticks no teste novo; é ajuste mecânico, sem mudança de comportamento. Vou corrigir isso enquanto a suíte completa termina.
A suíte inteira fechou verde. Falta só fechar duas evidências finais: `shellcheck` pós-ajuste e a reprodução isolada do caso não-vácuo, com `git config user.email` rechecado antes do smoke em `mktemp`.
As validações fecharam. Vou só coletar o diff final e os pontos de referência em linha para a devolutiva do review retroativo e da nova cobertura de contrato.
1. **Leitura da ordem**  
Fatia entendida: endurecer o `exec-bridge` contra drift do `codex-cli 0.142.0` via teste de contrato no schema real do `--json`, provar não-vacuidade contra o parser legado, manter compat com o schema antigo e fazer o review retroativo do break-glass sem tocar release.

2. **Crítica técnica**  
A suspeita estava correta: o caminho feliz da suíte estava ancorado no schema antigo, então o verde não provava o JSONL real do `0.142.0`. O único cuidado material era não deixar o fallback do session file mascarar o bug; tratei isso no teste novo usando o stream real com `agent_message` no stdout e uma prova separada de que o parser antigo fica vazio no mesmo fixture. Não encontrei objeção material no break-glass já aplicado.

3. **Veredito**  
`ajuste-menor`

4. **Execução**  
Atualizei [tests/contract/exec-bridge.test.sh](/Users/x86/git-projects/engrama/tests/contract/exec-bridge.test.sh:35) para:
- usar um stub/fixture com o schema real `thread.started -> item.completed/error -> turn.started -> item.completed/agent_message -> turn.completed`;
- validar resposta `PONG`, exclusão do ruído `error`, corpo não-vazio, `codex-session` vindo de `thread_id` e `codex-session-source: stream` ([linhas 109-160](/Users/x86/git-projects/engrama/tests/contract/exec-bridge.test.sh:109));
- adicionar a prova de não-vacuidade `E3A`, mostrando que o parser legado (`response_item` only) retorna vazio no mesmo stream real ([linhas 151-160](/Users/x86/git-projects/engrama/tests/contract/exec-bridge.test.sh:151));
- manter compat retroativa explícita com o schema antigo em `E3B` ([linhas 162-179](/Users/x86/git-projects/engrama/tests/contract/exec-bridge.test.sh:162));
- alinhar `E7` e `E8` ao schema novo onde fazia sentido ([linhas 229-300](/Users/x86/git-projects/engrama/tests/contract/exec-bridge.test.sh:229)).

Review retroativo do break-glass: em [exec-bridge.sh](/Users/x86/git-projects/engrama/.engrama/engine/scripts/exec-bridge.sh:144), `extract_session_id` já cobre `thread.started`; em [extract_response_text](/Users/x86/git-projects/engrama/.engrama/engine/scripts/exec-bridge.sh:211), o branch dual-schema é mínimo e seguro, e exclui corretamente `item.completed` do tipo `error`. Não vi ajuste material a exigir escalonamento. Runtime e template seguem em paridade; eu não precisei editar o bridge.

5. **Evidências**  
Confirmação da vacuidade anterior: o sucesso principal da suíte usava `session_meta`/`turn_context`/`response_item`, não o stream real `0.142.0`.  
Validações:
- `bash tests/contract/exec-bridge.test.sh` → 10 asserts verdes.
- `bash tests/run.sh` → todas as suítes verdes, incluindo `sync.test.sh`.
- `shellcheck -S info .engrama/engine/scripts/exec-bridge.sh template/.engrama/engine/scripts/exec-bridge.sh tests/contract/exec-bridge.test.sh` → limpo.
- `bash .engrama/engine/scripts/lint.sh` → exit 0.
- Reprodução isolada do não-vácuo → `session_source=stream`, `bridge_body=PONG`, `legacy_parser=<empty>`, `error_present=no`.

6. **Pendências e bloqueios**  
Sem bloqueio novo e sem dependência nova da Autoridade. Próximo passo seguro: o Orquestrador reauditar, registrar ADR/lição/ledger da fatia e então decidir commit. Preservei o worktree já sujo do break-glass do Orquestrador; minha alteração efetiva foi só no teste de contrato.
