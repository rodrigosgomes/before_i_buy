# Task 3B — perfil remoto, publicação explícita e compartilhamento privado

**Status:** planejada e autorizada para implementação interna
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
