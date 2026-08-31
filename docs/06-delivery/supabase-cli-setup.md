# Supabase CLI local

## Escopo seguro

Esta configuração opera somente a stack local Docker do repositório. Ela não faz login, não executa `supabase link`, não conhece um project ref e não envia migrations para nenhum banco remoto.

O projeto local é `backend/`; a configuração e migrations ficam em `backend/supabase/`. A versão da CLI está fixada em `backend/package.json` e deve acompanhar a versão usada no workflow de CI.

## Pré-requisitos

- Node.js 24 ou superior;
- Docker Desktop/Engine em execução;
- usuário com acesso ao socket Docker.

No Linux, confirme primeiro `docker info`. Se houver erro de permissão no socket, corrija o acesso ao Docker antes de iniciar a stack; não use `sudo` em comandos npm ou Supabase dentro do repositório.

## Uso diário

```bash
cd backend
npm install
npm run db:start
npm run db:status
npm run db:test
```

Pare a stack ao terminar:

```bash
cd backend
npm run db:stop
```

## Recriar o banco local

`npm run db:reset` destrói e recria **apenas** o banco local, reaplicando todas as migrations em `backend/supabase/migrations/`. Use-o para confirmar que a trilha é reproduzível do zero. Ele não é equivalente a `db push` e nunca deve ser usado com `--linked` sem uma solicitação explícita para um ambiente de desenvolvimento remoto.

```bash
cd backend
npm run db:reset
npm run db:test
```

## Limites e próximo passo remoto

O comando de publicação remota continua deliberadamente ausente dos scripts locais. Antes de qualquer `supabase link` ou `supabase db push --linked`, confirme project ref, ambiente, backup, migration exata e autorização para alterar dados externos.
