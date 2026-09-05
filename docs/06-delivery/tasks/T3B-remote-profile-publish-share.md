# Task 3B — perfil remoto, publicação explícita e compartilhamento privado

**Status:** validação local concluída e revisões sem achados; pendentes validação manual de desenvolvimento e CI/merge
**Entrega relacionada:** [Entrega 1](../../01-product/first-delivery-mini-prd.md)
**Decisão:** [DEC-015](../DECISION_LOG.md#dec-015-consentimento-interno-versionado-para-publicação-no-desenvolvimento)
**Depende de:** Task 3A concluída; contrato de publicação e voto já versionado
no Supabase.

## Resultado

Fechar o handoff do criador no ambiente de desenvolvimento:

`onboarding local confirmado → perfil remoto interno → rascunho → revisão → prévia inerte → publicar explicitamente → compartilhar convite privado`

O resultado remoto é um dilema `collecting_votes` e um convite não listado.
Reabertura, reconexão, login, prévia, falha de rede e cancelamento do share
nunca publicam por conta própria.

## Escopo

- Registrar o perfil do criador somente por `upsert_creator_profile`, usando
  nome escolhido pela pessoa, confirmação +18 e versões servidoras
  `internal-demo-v1` exclusivamente no ambiente de desenvolvimento.
- Restringir escrita direta em `profiles`; o cliente autenticado mantém apenas
  acesso ao próprio perfil e à RPC estreita.
- Validar no banco e no app nome entre 2 e 50 caracteres, limite já adotado
  pela projeção segura do convite; manter item, preço,
  categoria, finalidade, motivo, pausa e UUID de idempotência do rascunho.
- Implementar E1-S04 (prévia fiel, inerte e claramente marcada), E1-S05
  (publicado) e o estado de erro/retry de publicação.
- Chamar somente `publish_dilemma` após toque explícito na prévia, com a UUID
  persistida; em timeout, o retry usa o mesmo payload e chave.
- Montar o link somente em memória a partir de `GUEST_INVITE_BASE_URL` HTTPS e
  encaminhá-lo diretamente à folha nativa por um gateway injetável. Token e
  URL completos não aparecem na UI, semântica, erros ou logs.

## Não-escopo

- beta externo, domínio público, deploy do Web convidado, OpenGraph, analytics,
  Apple Sign In, textos jurídicos reais, produção ou lojas;
- revogação, exclusão, painel do criador, agregados, decisão, reflexão, Reveal,
  imagens, URLs de produto, comentários, conta de convidado ou IA.

## Autorização, privacidade e rollback

- `anon` não obtém qualquer permissão nova. `authenticated` não altera perfis
  de terceiros nem escolhe versões de consentimento arbitrárias.
- A RPC de publicação continua sendo a única criadora de dilemas e mantém a
  geração/hash do convite no servidor e a idempotência da DEC-011.
- A versão interna não tem validade jurídica e é bloqueadora de beta externo;
  uma futura migração desativa-a antes de cadastrar documentos aprovados.
- O rollback do cliente remove a slice de publicação; o rollback operacional
  mantém o banco aditivo, desativa a versão interna e revoga o acesso de app.

## Plano técnico

1. Migration aditiva: catálogo interno de versões permitidas, RPC
   `upsert_creator_profile`, validação de perfil na publicação e revogação de
   `INSERT`/`UPDATE` diretos em `profiles` para `authenticated`.
2. Testes pgTAP primeiro: acesso direto negado, perfil de outro usuário
   inacessível, RPC só escreve `auth.uid()`, versões inválidas recusadas e
   publicação exige maioridade/versões ativas.
3. Mobile: gateways injetáveis para perfil, publicação e share; configuração
   opcional e validada da origem HTTPS do convidado; persistência local continua
   sendo a autoridade do rascunho até publicação confirmada.
4. Composição: onboarding salva localmente após o toque e oferece sincronização
   remota explícita; revisão abre E1-S04; só E1-S04 pode iniciar publicação;
   E1-S05 oferece share sem revelar o link na tela.
5. Após sucesso, limpar o rascunho somente quando a resposta idempotente estiver
   validada; falhas preservam integralmente rascunho e UUID.

## Testes planejados

- **Banco/RLS:** pgTAP de RPC, versões, dono alheio, anônimo e publicação
  idempotente; nenhuma política mais permissiva.
- **Unitários mobile:** URL HTTPS, payload da RPC, resultado malformado, retry,
  redaction e gateways fake.
- **Widgets:** sincronização explícita, erro preservando onboarding/rascunho,
  prévia inerte, loading, CTA explícito, estado publicado, 320 px, 200% de
  texto e semântica.
- **Integração fake:** onboarding → perfil → rascunho → revisão → prévia →
  publicação → share; reconexão/login não chama publicação.
- **Manual dev remoto:** uma publicação e retry controlado com usuário Google
  permitido, sem expor segredo; o compartilhamento real aguarda uma origem
  HTTPS do Web convidado configurada.

## Revisão adversarial

Produto tenta publicar antes da prévia ou criar urgência. Segurança tenta
forjar versão, mudar perfil de terceiro, usar token/URL fora do share e publicar
sem perfil. Privacidade tenta transformar a fixture em base jurídica. QA corta
a rede, reinicia o app, repete a ação e cancela a folha nativa.

## Plano de fechamento — 2026-09-04

A revisão independente encontrou bloqueadores de isolamento de contas, respostas
assíncronas após logout, recuperação offline e retry após resposta perdida.
Correções vinculadas a esta task:

1. Particionar onboarding e rascunho pelo ID autenticado; dados legados sem dono
   não são atribuídos automaticamente a uma conta.
2. Invalidar operações da sessão anterior e preservar a tela em refresh da mesma
   conta. Respostas tardias não exibem convites nem apagam dados de outra sessão.
3. Recuperar rascunhos sem consulta remota obrigatória; verificar perfil na
   publicação e manter sincronização explícita quando necessária.
4. Persistir o snapshot da tentativa antes da RPC; após tentativa ambígua,
   mostrar “Publicação não confirmada”, impedir edição do payload e permitir
   retry explícito com a mesma chave, inclusive após reinício.
5. Adicionar regressões para cada cenário, contratos reais dos gateways e
   enforcement de consentimentos na RPC; repetir gates e revisões.

Produto revisou o plano sem impedimentos, exigindo a indicação honesta do estado
ambíguo. Nenhuma publicação automática, deploy ou liberação externa é incluída.

A validação de sistema usará exclusivamente a stack local: cliente Dart real →
Auth local de teste → RPC de perfil → publicação/retry → sessão/voto no banco.
A conta sintética será removida ao final; o script recusa origem remota. O job de
banco no CI executará esse teste além dos gates existentes. Login Google nativo
em dispositivo e folha de compartilhamento continuam validações manuais distintas.

Correção de gate detectada no fechamento: habilitar reporter LCOV no Vitest;
o workflow já exigia `coverage/lcov.info`, mas a configuração não o gerava.
Os thresholds permanecem inalterados. O teste de sistema mobile fica em
`test/system`, separado da suíte offline e obrigatório no job de banco via
script com configuração local validada.

## Evidências de revisão e limites do fechamento — 2026-09-04

- Segurança/privacidade: revisão final sem achados após isolamento por conta e
  invalidação de respostas tardias.
- QA: revisão final sem achados após bloqueio de edição durante tentativa,
  snapshot persistido, recuperação offline e tratamento de gravação/remoção
  que retorna `false`.
- Produto: revisão final sem achados; prévia exibe o nome escolhido e o estado
  ambíguo não afirma que o dilema continua não compartilhado.
- Mobile: `flutter pub get`, `dart format --output=none --set-exit-if-changed .`,
  `flutter analyze` e `flutter test --coverage --reporter expanded` passaram:
  **53 testes, 94,62% de linhas**, gate LCOV >=80% aprovado. A suíte offline
  registra um teste de sistema separado; ele é executado sem skip pelo gate
  obrigatório `node scripts/ci/test-mobile-supabase.mjs` com Supabase local.
  Regressões incluem conta A/B, resposta após logout, refresh de sessão,
  gravação recusada, snapshot após timeout/reinício, share e 320px/200% texto.
- Banco: `npm run db:migrate` local sem migrations pendentes;
  `npm run db:test`: **144 testes passaram**.
- Backend: `npm run test:db-concurrency`: **4 passaram**;
  `npm run test:edge-contract`: passou, **95,53% linhas / 90% branches**;
  `npm run test:edge-runtime`: passou na stack local.
- Web: `npm run lint`, `npm run test:coverage` (**9 passaram; 94,31% linhas**)
  e gate LCOV >=80% passaram; `npm run e2e:critical`: **2 passaram**.
  O E2E usa upstream sintético; o runtime real da Edge é validado separadamente.
- Sistema: cliente Dart real, Auth local sintético, perfil, snapshot restaurado,
  retry idempotente, abertura de convite e voto pelas RPCs passaram contra
  Supabase local. Não é evidência de Google Sign-In nativo ou share em aparelho.

Pendências que impedem declarar a task integralmente fechada:

1. `GUEST_INVITE_BASE_URL` está configurado localmente como
   `https://guest.example.com`, um host HTTPS de desenvolvimento/placeholder.
   Substituí-lo pelo domínio real do Web convidado antes do teste manual; isso
   não antecipa deploy público.
2. Teste manual com usuário Google permitido em dispositivo: perfil → prévia →
   publicação, retry controlado e folha nativa de share/cancelamento. Registrar
   o resultado sem token/URL de convite em evidências.
3. Commit/PR e jobs remotos de CI verdes antes de merge. Nesta validação não
   houve push, merge, deploy nem aplicação de migration em projeto remoto.

A autorização desta rodada cobriu correções e validações locais. O AGENTS.md
exige pedido explícito para operações externas. A aprovação de beta externo,
textos jurídicos reais, Apple Sign-In e lojas permanece fora da Task 3B.
