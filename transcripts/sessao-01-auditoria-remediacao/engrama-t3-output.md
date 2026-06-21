1. **Leitura da ordem**

Implementar diff-binding backward-compatible para o ledger, com fonte única de fingerprint, modo estrito por `ENGRAMA_REQUIRE_DIFF_BIND=1`, suíte nova cobrindo os 5 casos, propagação ao template, ADR 0011 honesta sobre o teto da garantia, sem tocar install/bootstrap e sem commit.

2. **Crítica técnica antes de executar**

O ponto delicado não era o hash em si, era o **lugar onde ele é verificado**. Como o fingerprint pedido usa `git diff --cached --raw -z`, o wrapper de CI antigo, que só reconstituía paths com placeholders, deixaria de ser fiel ao diff real do PR. Ajuste que assumi: reescrevi [critique-gate-ci.sh](/Users/x86/git-projects/engrama/critique-gate-ci.sh) para reconstruir base real + conteúdo atual do PR via `--base-ref`, senão o modo estrito em CI seria um overclaim.

Outro ajuste menor: mantive o legado por padrão, mas quando já existe entrada com `sha256` para uma branch+categoria, o gate passa a governar por esse caminho forte; isso evita um hash obsoleto ser contornado por um `confirmo` legado antigo.

3. **Veredito**

`ajuste-menor`

4. **Execução**

Implementei o helper [engrama-diff-hash.sh](/Users/x86/git-projects/engrama/engrama-diff-hash.sh), estendi o gate em [.engrama/scripts/critique-gate.sh](/Users/x86/git-projects/engrama/.engrama/scripts/critique-gate.sh), endureci a CI em [.github/workflows/ci.yml](/Users/x86/git-projects/engrama/.github/workflows/ci.yml) + [critique-gate-ci.sh](/Users/x86/git-projects/engrama/critique-gate-ci.sh), adicionei [tests/gate/diffbind.test.sh](/Users/x86/git-projects/engrama/tests/gate/diffbind.test.sh), ajustei as suítes que instanciam o gate, sincronizei o template via [sync-template.sh](/Users/x86/git-projects/engrama/sync-template.sh) e criei o ADR [0011](/Users/x86/git-projects/engrama/.engrama/decisions/0011-diff-binding-atestacao-verificavel.md) + versão template.

5. **Evidências**

Saída manual dos 5 casos de (C):

```text
match
hash=sha256:f910d085277f17725a9c876d34e29c45cd6629d863ab470c4cc480582760b7cc exit=0
mismatch-after-edit
hash_antigo=sha256:59d9aba22175d2c97b6ad00534b3f44325b0bf42976a05b2b1e832db34aec747 exit=2
legacy
exit=0
strict-no-hash
exit=2
stable-hash
h1=sha256:f910d085277f17725a9c876d34e29c45cd6629d863ab470c4cc480582760b7cc
h2=sha256:f910d085277f17725a9c876d34e29c45cd6629d863ab470c4cc480582760b7cc
h3=sha256:19dcf24c700d168f22c8d8e626317e3027fdba0e479f5980a91d7ce9026e9997
```

Validações:

```text
shellcheck engrama-diff-hash.sh critique-gate-ci.sh sync-template.sh .engrama/scripts/critique-gate.sh tests/gate/diffbind.test.sh tests/gate/ci.test.sh tests/gate/critique-gate.test.sh tests/gate/fuzz.test.sh tests/contract/sync.test.sh
# sem saída, exit 0
```

```text
bash tests/contract/sync.test.sh
# 9 asserts batidos, 0 divergentes
```

```text
bash lint.sh
# sem saída, exit 0
```

```text
bash tests/run.sh
TODAS AS SUITES VERDES
```

O ADR 0011 ficou honesto: ele afirma cobertura verificável **deste diff**, e explicitamente nega que isso prove independência de identidade do crítico.

6. **Pendências**

Nada bloqueando localmente. Não comitei.

O que ainda depende de ação externa da Autoridade/admin do repo:
- marcar o check de CI como **required** no branch protection, para o modo estrito server-side virar enforcement vinculante de merge;
- qualquer evolução além disso para provar **identidade independente do crítico** exigirá mecanismo fora do repo (assinatura/chave/atestado do executor-bridge), o que o ADR 0011 já registra como teto atual.
