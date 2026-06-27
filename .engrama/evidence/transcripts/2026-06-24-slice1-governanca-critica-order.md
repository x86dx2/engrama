# ORDEM (CRÍTICA DE GOVERNANÇA — ADR 0006) — ADR 0013 + lição do bridge-hardening

**Sandbox READ-ONLY. NÃO execute, NÃO edite, NÃO mova nada.** Esta é a crítica independente exigida pelo ADR 0006 (governança não se autoaprova) ANTES do commit da fatia 1. Dê veredito (`confirmo`/`ressalvas`/`discordo`) sobre se a governança autorada está sólida para commit.

## Contexto
O Orquestrador autorou, como parte da fatia 1 (bridge-hardening, já executada por você), os documentos de governança que faltavam. Você já fez o review retroativo do break-glass de CÓDIGO (`ajuste-menor`, sem objeção). Esta crítica é só dos DOCUMENTOS de governança recém-autorados.

## Arquivos a criticar (leia no repo)
1. `.engrama/memory/decisions/0013-bridge-resiliente-a-version-drift-do-codex.md` (NOVO ADR).
2. Adição em `.engrama/memory/specs/licao-aprendida.md` (bullet do version-drift, na seção "Exemplos reais").
3. Linha nova em `.engrama/index.md` (catálogo do 0013).

## Pontos pra criticar com força
1. **Coerência com ADRs existentes** — o 0013 contradiz ou se sobrepõe mal a 0003 (executor-bridge), 0005 (QA re-execução) ou 0011 (diff-binding)? O `reconcilia: ADD` é correto, ou deveria ser `UPDATE 0003`?
2. **Honestidade (princípio 12)** — algum overclaim? Em especial: a decisão de "dual-parse + teste de contrato" promete enforcement que o teste de fato entrega? O resíduo do `extract_response_from_session` (fallback no schema antigo) está descrito com honestidade e na proporção certa (baixa prioridade)?
3. **Completude da decisão** — alternativas (pinar versão / só-stub-antigo / fail-loud) estão justas? Falta alguma consequência durável (ex.: a obrigação de recapturar a fixture quando o codex mudar)?
4. **A lição** — caracterizar como "3ª ocorrência da mesma classe" (PR-A/PR-B/agora) é factualmente correto e útil, ou é forçar narrativa?
5. Qualquer coisa que você, como crítico independente, veja como impróprio para entrar na memória institucional versionada.

## Saída esperada
Leitura + crítica técnica + **veredito** (`confirmo` | `ressalvas <quais>` | `discordo <por quê + gatilho de materialidade>`). Se `discordo` material, eu (Orquestrador) levo à Autoridade (sem overrule). NÃO execute nada.
