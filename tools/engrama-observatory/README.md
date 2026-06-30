# Engrama Observabilidade Cognitiva

Console local para inspecionar o usage ledger e a configuracao runtime do Engrama.

## O que esta versao faz

- le `usage-YYYY-MM.jsonl`;
- agrega uso por role, tier e modelo;
- mostra dashboard, modulos dedicados de Roles, Tiers, Models, Billing, timeline e tabela de runs;
- le `models.conf`, `subscriptions.conf` e `prices.conf`;
- permite validar e salvar alteracoes em `models.conf` com diff, backup e event log;
- lista `config-events` quando existirem.

## O que esta versao nao faz

- nao le `.env`;
- nao abre transcripts automaticamente;
- nao executa agentes;
- nao distribui a ferramenta no template do Engrama.

## Como rodar

```bash
cd tools/engrama-observatory
npm install
npm run dev
```

Por padrao, o servidor assume que o repo raiz e dois niveis acima da pasta da ferramenta. Para apontar para outro checkout do Engrama:

```bash
ENGRAMA_REPO_ROOT=/Users/x86/git-projects/engrama npm run dev
```

## Endpoints locais

- `GET /api/usage?month=current`
- `GET /api/usage/summary?month=current`
- `GET /api/models`
- `POST /api/models/validate`
- `POST /api/models/save`
- `GET /api/config-events?month=current`

## Arquivos lidos

- `.engrama/evidence/usage/*.jsonl`
- `.engrama/evidence/config-events/*.jsonl`
- `.engrama/engine/config/models.conf`
- `.engrama/engine/config/subscriptions.conf`
- `.engrama/engine/config/prices.conf`

## Arquivos escritos

- `.engrama/engine/config/models.conf`
- `.engrama/evidence/config-backups/*.conf`
- `.engrama/evidence/config-events/*.jsonl`

## Cuidados de seguranca

- o servidor so resolve caminhos permitidos dentro do repo;
- qualquer tentativa de ler `.env` e rejeitada;
- paths de transcript sao mostrados como texto, sem abrir conteudo;
- linhas invalidas do ledger sao ignoradas e reportadas como alerta;
- o save de `models.conf` bloqueia tiers invalidos, campos vazios e fallback silencioso para critica/authority.

## Limitacoes

- a matriz de modelos exibida e tier-first, porque esse e o contrato real do `model-router.sh`;
- `config-events` pode estar vazio em repos que ainda nao habilitaram escrita segura;
- custos de API aparecem como `unknown` quando tokens ou precos nao estiverem configurados.
- mensalidades sem valor configurado aparecem como `not configured`.

## Como alterar tiers/modelos

1. Edite os campos do card de cada tier.
2. Rode `Validar` para gerar erros, warnings e diff textual.
3. Confirme `Salvar models.conf` para criar backup, gravar o arquivo e registrar o config event.
4. Rode os comandos sugeridos pela UI para conferir `execute/T2`, `critique/T4` e `authority/T4+`.
