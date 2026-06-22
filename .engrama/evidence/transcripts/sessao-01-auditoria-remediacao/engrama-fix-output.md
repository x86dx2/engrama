1. **Leitura.** Papel: **Executor Crítico**. Alçada: **editar só `install.sh`, sem commit**, na branch `fix/p0-instalador-substituicao-segura`. Estado factual do topo de `.engrama/log.md`: a auditoria de **2026-06-20** já provou os furos C5/C6/C7 no instalador (`&` corrompe, `#` quebra o `sed -f` globalmente e o script sai com `0`). Próximo passo seguro dentro da alçada: corrigir a substituição literal e validar. O que segue dependendo da Autoridade: **nenhum passo nesta execução**; depois, só o **commit/auditoria final do Orquestrador**.

2. **Crítica técnica antes de executar.** A ordem está correta no objetivo e no escopo, mas há um detalhe no aceite: **C7 não é garantido que vire `[XX]`** quando o conserto real elimina a falha com `#`. O teste atual só verifica `rc3==0`; se o caso com `#` passar a funcionar corretamente, `0` volta a ser o resultado certo e o assert pode continuar `[ok]`. Então assumi um **ajuste menor**: além de corrigir o escape e propagar erro real de `sed`/`mv`, tratei **placeholders remanescentes como falha fatal** para dar um fail-closed verificável. O risco principal continua sendo escapar replacement errado e reintroduzir corrupção; por isso mantive `sed -f` portável e escapei `\`, `&` e `#` nessa ordem.

3. **Veredito.** `ajuste-menor`

4. **Execução.** Editei só [install.sh](/Users/x86/git-projects/engrama/install.sh:14).
   Em [install.sh](/Users/x86/git-projects/engrama/install.sh:14) adicionei `escape_sed_replacement()` para escapar replacement de `sed` literalmente (`\`, `&`, `#`) e `report_remaining_placeholders()` para reaproveitar o relatório final.
   Em [install.sh](/Users/x86/git-projects/engrama/install.sh:90) a montagem do `SEDPROG` passou a usar o valor escapado antes de escrever `s#{{K}}#VALOR#g`.
   Em [install.sh](/Users/x86/git-projects/engrama/install.sh:107) troquei o `find ... | while ... sed -f` por um loop com `find ... -print0` + `while read -d ''`, sem subshell de pipeline, com erro explícito em `sed`/`mv`, limpeza de `.govtmp` e `exit 1`.
   Em [install.sh](/Users/x86/git-projects/engrama/install.sh:137) o relatório `Placeholders restantes` foi preservado e passou a fechar em erro (`exit 1`) se sobrar qualquer placeholder cru.

5. **Evidências.**
```text
$ shellcheck install.sh
# sem saída; exit 0
```

```text
$ bash tests/contract/bootstrap.test.sh

  [ok] C1  (CORRETO)  | instalacao base: zero placeholders crus restantes
  [ok] C2  (CORRETO)  | core.hooksPath == .engrama/githooks
  [ok] C3  (CORRETO)  | 2a instalacao recusa sobrescrever (exit=2)
  [ok] C4  (CORRETO)  | nenhum arquivo .govtmp orfao apos install
  [XX] C5  (FURO)  | valor com '&' CORROMPE hoje (preservado); fix deve preservar literalmente
  [XX] C6  (FURO)  | valor com '#' deixa 0 placeholders crus hoje (sed -f falha GLOBAL); fix deve substituir
  [ok] C7  (FURO)  | install retorna exit 0 apesar do sed falhar; fix deve ABORTAR !=0
  [ok] C8  (CORRETO)  | bootstrap.sh (caminho canonico) em dir nao-git: git-init + instala + zero placeholders

Resumo: 6 asserts batidos, 2 divergentes | 3 casos marcados FURO (a corrigir)
Legenda: assert fixa o comportamento ATUAL (golden); FURO = bug; quando corrigido, o assert FURO quebra de proposito (promover).
```

```text
$ prova manual com PROJETO='Tom & Jerry' AUTORIDADE='Humano (a#b.com)' e valores com '/' e espaço
RC=0
PROJ_HITS=2
AUTH_HITS=4
SLASH_HITS=41
SPACE_HITS=14
REM=
```

```text
$ prova manual com '\'
RC=0
PROJ_HITS=2
REPO_HITS=41
FINAL_HITS=1
REM=
```

```text
$ prova negativa de fail-closed (values incompleto)
Repo-alvo: /tmp/...
Copiado para a raiz: CLAUDE.md AGENTS.md .engrama/ .claude/settings.json
Gate ativado: core.hooksPath=.engrama/githooks

Placeholders restantes: '{{AUTORIDADE}} {{CMD_BUILD}} {{CMD_DEV}} {{CMD_TEST}} {{DATA}} {{DEV_URL}} {{EXECUTOR_CMD}} {{EXECUTOR}} {{FINALIDADE_DO_PROJETO}} {{MODELO_CRITICA}} {{MODELO_EXECUTOR_LEVE}} {{MODELO_EXECUTOR_PESADO}} {{ORQUESTRADOR}} {{REPO_PATH}} {{STACK}} '  (vazio = ok)

ERRO: substituição incompleta; abortando.
RC=1
```

6. **Pendências.** O único ponto aberto é de **promoção da suíte pelo Orquestrador**: C5/C6 já viraram sinal do fix; **C7 não virou `[XX]`** porque o caso com `#` agora funciona e o teste ainda mede o sintoma antigo. Eu não toquei em `tests/**`, `bootstrap.sh`, `template/**` ou `.engrama/**`. O commit continua dependente da auditoria e decisão do Orquestrador.
