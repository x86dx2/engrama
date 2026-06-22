Você é um auditor de engenharia SÊNIOR, externo e IMPARCIAL, revisando o repositório em que está rodando (cwd = raiz do projeto "engrama"). Seu trabalho é CRITICAR com rigor, não elogiar. O dono quer saber se este projeto "está nascendo da forma certa" ou se algo precisa mudar.

CONTEXTO: "engrama" é um pack de GOVERNANÇA-COMO-CÓDIGO (Markdown + Bash + git hooks) inspirado no "LLM Wiki" de Karpathy. Define uma tríade de papéis (Orquestrador/Claude, Executor Crítico/Codex, Autoridade/Humano), ADRs de processo, specs, e um "gate de crítica" mecânico (.engrama/scripts/critique-gate.sh) que bloqueia commits em superfície sensível sem crítica registrada. Há uma "instância viva" na raiz e um `template/` distribuível.

LEIA o repositório a fundo (README.md, INSTALL.md, INSTANTIATE.md, CLAUDE.md, AGENTS.md, install.sh, bootstrap.sh, .engrama/** incluindo scripts, governance, decisions, specs, qa; e template/**). Depois produza uma CRÍTICA PROFUNDA E PRIORIZADA.

Avalie especificamente, sem condescendência:
1. ARQUITETURA & DESIGN — o modelo conceitual (LLM-Wiki→governança) se sustenta? A tríade de papéis é sólida ou cerimonial demais? A recursão "governança se autoaprova / se aplica a si mesma" tem furos lógicos? A duplicação raiz↔template é sustentável? Há acoplamento a vendor (codex/claude) que contradiz o lema "papéis por função, não por vendor"?
2. TESTES / TDD — qual o estado real de testes automatizados? O gate (parsing de markdown via grep) é lógica crítica testável; está testado? O que DEVERIA existir (ex.: bats-core, testes de contrato do instalador, testes de comportamento do gate)? O projeto prega TDD mas pratica?
3. SCRIPTS BASH — corretude, robustez, portabilidade (macOS BSD sed vs GNU), idempotência, error-handling (set -e/-u/pipefail), caminhos fail-open vs fail-closed, dependências não-declaradas (rsync, jq, rg, python3), edge cases (paths com espaço, valores com `#` ou `&`, CRLF).
4. SEGURANÇA DO GATE — modele ameaças: como burlar o gate? O matching por substring ("waiver", tokens OK) é robusto ou trivialmente gameável? Os exit 0 fail-open. O hook depende de python3 e some silenciosamente se faltar?
5. DOCUMENTAÇÃO & CONSISTÊNCIA — drift doc↔código, redundância/DRY (o modelo é repetido em N arquivos), contradições, referências quebradas (ex.: `sync-template.sh` citado no classify() existe?), nomes de modelo (gpt-5.5/5.4/5.4-mini existem?), integridade de wikilinks, ausência de LICENSE/CONTRIBUTING/CI.
6. HIGIENE & PRÁTICA DE ENGENHARIA — .DS_Store versionado, cobertura do .gitignore, versionamento/release, ausência de CI, convenções de commit.
7. O VEREDITO HONESTO — este projeto está sobre-engenheirado para o que entrega? A relação cerimônia/valor é saudável? O que você MATARIA, o que MANTERIA, e qual seria a MENOR mudança de maior impacto?

Para cada achado: severidade (CRÍTICO/ALTO/MÉDIO/BAIXO), arquivo:linha quando aplicável, por que importa, e a correção recomendada. Seja específico e verificável — cite o código. Termine com um "TOP 5 do que mudar primeiro" e um veredito de 1 parágrafo: o projeto está nascendo certo? Responda em português.
