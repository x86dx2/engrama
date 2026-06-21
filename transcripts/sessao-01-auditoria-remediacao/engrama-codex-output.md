**Achados**

- **CRÍTICO** — O “gate mecânico” não é um gate por commit; ele é um cache por `branch + categoria`. Em [critique-gate.sh](/Users/x86/git-projects/engrama/.engrama/scripts/critique-gate.sh:83) o script só procura qualquer linha no ledger com a branch e `[cat]`, como documentado em [criticas-do-executor.md](/Users/x86/git-projects/engrama/.engrama/qa/criticas-do-executor.md:14). Resultado: uma única linha `confirmo` em `main` pode destravar mudanças futuras ilimitadas na mesma branch/categoria. Correção: vincular a crítica ao diff staged (`git diff --cached` hash, `tree` SHA ou lista exata de arquivos) e invalidá-la após um único commit.

- **CRÍTICO** — A “prova” da crítica é autoatestada em Markdown, não verificada. O gate aceita texto livre no ledger como verdade em [critique-gate.sh](/Users/x86/git-projects/engrama/.engrama/scripts/critique-gate.sh:79); não existe `response_id`, hash, assinatura nem artefato imutável do Executor. Isso não é enforcement forte; é convenção social com verniz mecânico. Correção: gravar artefato estruturado da crítica e validar em CI/servidor, não só em hook local.

- **ALTO** — O mecanismo de `waiver` é trivialmente gameável, e a própria doc admite isso. O parser trata `waiver` por substring em [critique-gate.sh](/Users/x86/git-projects/engrama/.engrama/scripts/critique-gate.sh:76) e o ledger manda “evitar” frases como “sem waiver” em [criticas-do-executor.md](/Users/x86/git-projects/engrama/.engrama/qa/criticas-do-executor.md:26). Se o sistema depende de o humano não escrever a palavra errada, ele já falhou. Correção: trocar por campos estruturados obrigatórios (`verdict`, `waiver_by`, `waiver_at`) e parsing estrito.

- **ALTO** — O gate é fail-open fora do caminho feliz. O hook do git delega e sai silenciosamente em erro em [pre-commit](/Users/x86/git-projects/engrama/.engrama/githooks/pre-commit:4); o wrapper do harness cai para `exit 0` se `python3` faltar ou se o JSON vier inesperado em [critique-gate-hook.sh](/Users/x86/git-projects/engrama/.engrama/scripts/critique-gate-hook.sh:13). Sem CI, `git -c core.hooksPath=/dev/null commit` continua bypass óbvio. Correção: CI obrigatória reproduzindo o gate e falha fechada quando dependências mínimas não existirem.

- **ALTO** — O projeto prega TDD e testes de contrato, mas hoje não testa o que mais importa. Não há `tests/`, `.github/` ou qualquer suíte automatizada, enquanto [test-writing.md](/Users/x86/git-projects/engrama/.engrama/specs/test-writing.md:16) e [bootstrap-do-projeto.md](/Users/x86/git-projects/engrama/.engrama/project/bootstrap-do-projeto.md:39) vendem disciplina forte. O ponto crítico aqui é Bash e parsing de Markdown; isso está sem cobertura. Correção: adicionar Bats/ShellSpec para `bootstrap.sh`, `install.sh`, `critique-gate.sh` e `critique-gate-hook.sh`, e rodar tudo em CI.

- **ALTO** — A duplicação `raiz ↔ template/` é cara e já mostra cheiro de drift. Há duas árvores enormes quase iguais e até referência a [sync-template.sh](/Users/x86/git-projects/engrama/.engrama/scripts/critique-gate.sh:51), arquivo que não existe. Isso é manutenção manual de texto normativo em massa. Correção: gerar `template/` a partir de uma única fonte canônica, ou inverter e manter só a versão templated + instanciação.

- **ALTO** — A promessa de portabilidade conflita com `source_refs` absolutos. O schema manda usar caminhos absolutos em [CLAUDE.md](/Users/x86/git-projects/engrama/.engrama/CLAUDE.md:17), mas a governança diz que o artefato sobrevive a clone novo em [governance/index.md](/Users/x86/git-projects/engrama/.engrama/governance/index.md:24). Não sobrevive: mover o repo quebra todos os `source_refs`. Correção: usar caminhos relativos à raiz do repo ou um URI lógico do tipo `repo://`.

- **ALTO** — “Papéis por função, não por vendor” é verdade só na prosa; a implementação é fortemente vendor-coupled. O mapeamento vivo hardcodeia Claude/Codex em [papeis-e-alcadas.md](/Users/x86/git-projects/engrama/.engrama/governance/papeis-e-alcadas.md:24), o bootstrap instala `.claude/settings.json` em [INSTALL.md](/Users/x86/git-projects/engrama/INSTALL.md:71), e o canal operacional gira em torno de `codex exec` em [papeis-e-alcadas.md](/Users/x86/git-projects/engrama/.engrama/governance/papeis-e-alcadas.md:34). Correção: separar núcleo de governança de adaptadores de harness/provedor.

- **MÉDIO** — A instância viva não está realmente “instanciada”; ela continua carregando texto de template. Em [specs/README.md](/Users/x86/git-projects/engrama/.engrama/specs/README.md:25), [infra-runbook.md](/Users/x86/git-projects/engrama/.engrama/specs/infra-runbook.md:10) e [test-writing.md](/Users/x86/git-projects/engrama/.engrama/specs/test-writing.md:23) o repo central ainda fala em `Template:` e `N/A (sem servidor local)`. Isso enfraquece o dogfooding: o próprio repositório não prova o padrão que distribui. Correção: ou preencher de verdade para o repo central, ou mover esses esqueletos para `template/` apenas.

- **MÉDIO** — O instalador é semanticamente frágil para valores reais. Em [install.sh](/Users/x86/git-projects/engrama/install.sh:76) a substituição de placeholders usa `sed` sem escapar `#`, `&` e `\`; o exemplo admite “sem `#` no valor” em [engrama.values.example](/Users/x86/git-projects/engrama/engrama.values.example:2). Isso é um instalador distribuível que quebra em input comum. Correção: escapar replacement corretamente ou usar ferramenta de templating de verdade.

- **MÉDIO** — O caminho manual de instanciação também é frágil para nomes de arquivos com espaço. O exemplo em [INSTANTIATE.md](/Users/x86/git-projects/engrama/INSTANTIATE.md:54) usa `grep ... | xargs sed ...`, sem `-print0/-0`. Correção: trocar a documentação para fluxo seguro, ou parar de oferecer esse caminho manual.

- **MÉDIO** — Há drift entre doc e código nas heurísticas do bootstrap. [INSTALL.md](/Users/x86/git-projects/engrama/INSTALL.md:29) promete inferir `PROJETO` por diretório, `package.json` ou remote; [bootstrap.sh](/Users/x86/git-projects/engrama/bootstrap.sh:43) só usa `basename`. Correção: implementar o que a doc promete ou simplificar a doc.

- **MÉDIO** — A proteção contra secrets no harness é estreita demais para um template genérico. [.claude/settings.json](/Users/x86/git-projects/engrama/.claude/settings.json:2) bloqueia só `./.env` e `./.env.*` na raiz; em monorepo, `apps/web/.env` passa. Correção: usar padrões recursivos ou política de allowlist por diretório.

- **MÉDIO** — A categoria `contract` não é recursiva o bastante. [critique-gate.sh](/Users/x86/git-projects/engrama/.engrama/scripts/critique-gate.sh:56) cobre `tests/contract/*`, não árvores profundas típicas como `tests/contract/http/login/*.ts`. Correção: match recursivo real ou classificação por prefixo de caminho.

- **BAIXO** — Falta higiene básica de projeto distribuível: não há `LICENSE`, `CONTRIBUTING`, CI nem tags de release. Para um pack que quer ser portável, isso complica adoção, atualização e governança externa. Correção: adicionar o mínimo de scaffolding operacional.

- **BAIXO** — Os `[[wikilinks]]` funcionam para Obsidian/agente, mas degradam leitura normal do repositório, inclusive em [README.md](/Users/x86/git-projects/engrama/README.md:42). Correção: gerar versão GitHub-friendly ou usar links Markdown normais nas superfícies humanas.

**Top 5 do que mudar primeiro**

1. Trocar o ledger em Markdown por um artefato estruturado e vinculá-lo ao diff staged.
2. Colocar testes automatizados de Bash/gate em CI antes de ampliar mais a governança.
3. Eliminar a duplicação manual `raiz ↔ template/` com geração a partir de uma fonte única.
4. Remover caminhos absolutos de `source_refs` e adotar referências relativas ao repo.
5. Separar o núcleo da governança dos adaptadores `Claude/Codex`, para o discurso “por função, não por vendor” virar verdade operacional.

**Veredito**

O projeto não está “nascendo errado”, mas está nascendo com cerimônia demais e mecanismo de menos. O núcleo útil existe: handshake, bootstrap explícito, separação escritor/auditor e crítica antes de mudanças sensíveis. O problema é que o repositório vende isso como enforcement duro quando, hoje, ele é majoritariamente texto duplicado + hooks locais + `grep` em Markdown. Eu manteria o modelo conceitual mínimo e mataria três coisas imediatamente: a pretensão de segurança forte do gate atual, a duplicação manual entre instância viva e template, e o acoplamento de vendor dentro do núcleo. A menor mudança de maior impacto é transformar a crítica em evidência estruturada, vinculada ao diff e validada em CI; sem isso, o resto é ritual.

Não consegui rodar o smoke de bootstrap ponta a ponta porque a sandbox desta sessão não oferece diretório temporário gravável. O restante foi auditoria estática completa, `shellcheck` nos scripts e checagem local do `codex exec --help`. Nota factual externa: os IDs `gpt-5.5`, `gpt-5.4` e `gpt-5.4-mini` constam hoje na documentação oficial de modelos da OpenAI; o problema aqui não é inventar nomes de modelo, é hardcodá-los no núcleo do pack. Fonte: https://developers.openai.com/api/docs/models
