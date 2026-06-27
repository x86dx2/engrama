# ORDEM (FASE 2 / FATIA 1) — bridge-hardening: teste de contrato vs schema real do codex + review retroativo do break-glass

Você é o Executor Crítico. **Critique a ordem ANTES de executar** (riscos/lacunas/pré-condições); se concorda ou é ajuste-menor que você assume, **execute**. Sandbox = workspace-write. Devolva os 6 itens da resposta mínima.

## 1. Objetivo da fatia
Endurecer o `exec-bridge.sh` contra **version-drift do codex**: adicionar um **teste de contrato** que replica a saída **REAL** do `codex exec --json` do `codex-cli 0.142.0` e prova que `extract_response_text` captura a resposta; revisar **retroativamente** o fix break-glass que o Orquestrador já aplicou; manter paridade com o template. NÃO mexer em release (fatias 2-3).

## 2. Estado factual conhecido
- `codex-cli 0.142.0`. Schema NOVO do `--json` (amostra real capturada nesta sessão, uma linha JSON por evento):
  - `{"type":"thread.started","thread_id":"019ef9f3-e493-7a71-a5b2-688716a1281a"}`
  - `{"type":"item.completed","item":{"id":"item_0","type":"error","message":"failed to parse plugin hooks config ... unknown field `description`"}}`  ← RUÍDO (warning de plugin), NÃO é a resposta
  - `{"type":"turn.started"}`
  - `{"type":"item.completed","item":{"id":"item_1","type":"agent_message","text":"PONG"}}`  ← a RESPOSTA
  - `{"type":"turn.completed","usage":{...}}`
  - Não há `model` em nenhum evento do stream (nem em turn.started/turn.completed).
- Schema ANTIGO (que o bridge parseava): `response_item` com `payload.type=="message"`, `payload.role=="assistant"`, `payload.content[].type=="output_text"`/`.text`; session em `session_meta`/`payload.session_id`.
- **Break-glass já aplicado pelo Orquestrador** (sob ordem da Autoridade) em `extract_response_text` (runtime `.engrama/engine/scripts/exec-bridge.sh` + `template/...` via `sync-template.sh`, em paridade): agora suporta os DOIS schemas (if response_item ... elif item.completed/agent_message ... else empty), excluindo o `error`. `extract_session_id` já pegava `thread.started` pelo branch `.thread_id` existente. Provado por smoke: session real do stream + corpo capturado.
- Suíte: `tests/contract/exec-bridge.test.sh` (8 casos, incl. E8 re-exec). Runner `tests/run.sh`. **Suspeita a confirmar:** o stub de `codex` dos testes E1-E7 pode estar no formato ANTIGO → os testes podem estar passando de forma **vácua** contra um codex fake que não corresponde mais à realidade (foi exatamente assim que o bug do PR-B passou). Confirme e reporte.

## 3. Escopo da execução
1. **Teste de contrato novo** (estenda `tests/contract/exec-bridge.test.sh` ou crie arquivo focado, como preferir):
   - Stub de `codex` que emite no STDOUT **exatamente o formato REAL do 0.142.0** (jsonl acima: thread.started + item.completed/error + turn.started + item.completed/agent_message + turn.completed).
   - Rodar o bridge e assertar: (a) o transcript de RESPOSTA contém o texto do `agent_message`; (b) NÃO contém o `error`/ruído; (c) NÃO fica vazio; (d) `codex-session` vem do `thread_id` com `codex-session-source: stream` (não `derived`).
   - **Não-vácuo:** prove que SEM o fix (parser só-antigo) este teste FALHARIA (ex.: caso de regressão documentado, como o E7 fez).
   - **Compat retroativa:** um caso com stub no schema ANTIGO ainda captura a resposta.
2. **Review retroativo** do diff break-glass do Orquestrador em `extract_response_text` (runtime + template): confirme correção/segurança ou aponte ajuste material. Esse é o review que a alçada break-glass exige.
3. (Opcional, só se trivial e seguro) captura de `model` no schema novo SE houver fonte confiável no stream; senão deixe `unknown` e **não invente**.
4. Paridade template via `sync-template.sh` + `sync.test.sh` se tocar o bridge.

## 4. Restrições e fronteiras (NÃO tocar)
- **NÃO** tocar release: `VERSION`, `CHANGELOG.md`, qualquer `release-gate.sh` — é fatia 2/3.
- **NÃO** alterar a lógica de re-exec/cópia-estável (guard E8) além do estritamente necessário.
- **NÃO** mutar git do repo real; qualquer smoke só em `mktemp` com `git -C`. **Reverifique `git config user.email` antes de qualquer git op** (regra pós-incidente de isolamento).
- **NÃO** editar prosa/governança (ADR/lição os autora o Orquestrador; você critica depois).

## 5. Critérios de aceite
- Teste novo VERDE e **não-vácuo** (falha sem o fix). Suíte inteira verde (`bash tests/run.sh`). `shellcheck -S info` limpo nos scripts tocados. `lint.sh` exit 0. `sync.test` em paridade se tocar o bridge.

## 6. Validações esperadas
`bash tests/run.sh`; `shellcheck -S info`; `bash .engrama/engine/scripts/lint.sh`; sync (se aplicável); reprodução isolada do teste novo provando o não-vácuo.

## 7. Riscos conhecidos
- O stub PRECISA replicar o formato REAL (lição PR-B). Use a amostra do item 2.
- Drift entre o stub novo e os stubs antigos dos E1-E7 (se existirem em formato velho) pode confundir — reporte se achar testes vácuos.

## 8. O que depende da Autoridade
Nada novo nesta fatia (fold + direção já aprovados). Commit/PR fica para depois da auditoria + crítica-gate + autoria do ADR/lição.

## 9. Próximo passo seguro após a execução
Orquestrador audita (re-roda os gates), autora ADR (version-drift / teste de contrato do bridge) + lição em `licao-aprendida.md` com sua crítica, registra no ledger (superfície `gate`/`contract`), e só então commita.

## 10. Modelo/tier
workspace-write; modelo = default do codex (não passo `--model`: não confirmei o id real do 0.142.0). Tarefa de teste/contrato = peso médio.
