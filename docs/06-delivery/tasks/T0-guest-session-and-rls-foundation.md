# Task 0 — sessão de convidado e fundação RLS

**Status:** concluída localmente; pronta para revisão de PR  
**Tipo:** segurança, privacidade e banco  
**Entrega relacionada:** [Entrega 1](../../01-product/first-delivery-mini-prd.md)  
**Bloqueia:** qualquer tela, API ou E2E que leia convite ou grave voto de convidado.

## 1. Resultado e contexto de produto

Como convidado sem conta, quero abrir somente o dilema que me foi compartilhado e votar nele sem que essa permissão revele outros dilemas, votos ou dados privados.

Esta task corrige o bloqueio já observado no baseline: o banco tem RLS habilitado, mas políticas para `public`/`anon` permitem leitura direta de dilemas, participações e votos. Além de violar o contrato de convite privado, a RPC atual devolve `total_votes` antes do voto. A correção preserva a Entrega 1: rascunho local → publicação explícita → convite privado → voto, sem adicionar IA, feed, contato de convidado, mídia, razões de voto, decisão ou Reveal.

## 2. Escopo e não-escopo

### Escopo

- criar uma nova migration aditiva para uma sessão opaca, temporária e limitada a um dilema;
- remover acesso direto de `anon` e `public` às tabelas expostas na Entrega 1;
- reduzir leitura direta de perfis autenticados ao necessário para a Entrega 1;
- substituir a troca de convite por um contrato seguro que não exponha agregados antes do voto;
- definir uma Edge Function de convite como única borda web para criar/renovar a sessão e definir cookie seguro;
- revogar privilégios implícitos de execução e conceder somente as RPCs necessárias aos papéis corretos;
- tornar os testes pgTAP de autorização comportamentais e deixá-los verdes no banco local e no CI.

### Não-escopo

- aplicativo Flutter, página web de voto, autenticação visual ou compartilhamento;
- gravação ou substituição de voto; esses contratos pertencem à primeira vertical slice após esta fundação;
- e-mail, push, Reveal, razões de voto, comentários, imagens, URLs de produto, analytics de produto, rate limiter de produção ou integração de provedor externo;
- alterar migrations históricas, vincular o projeto Supabase a remoto ou executar `supabase db push --linked`;
- expor `service_role` a qualquer cliente.

O endpoint deve deixar uma borda clara para rate limiting por convite/sessão antes de beta externo, mas esta task não usará IP como identidade nem introduzirá coleta de dados pessoais.

## 3. Contratos de estado e autorização

### Sessão de convidado

Uma `guest_access_session` existe para **um** `dilemma_id` e tem `active`, `revoked` ou `expired` como estado derivado de `revoked_at` e `expires_at`.

| Evento | Resultado exigido |
|---|---|
| convite válido em `collecting_votes` | Edge Function gera segredo aleatório de 256 bits, persiste somente SHA-256 e cria sessão `active` limitada ao dilema e ao prazo de pausa; devolve apenas a projeção permitida. |
| convite inválido, revogado, apagado, moderado ou fora do estado permitido | resposta genérica sem dados do dilema e sem criação de sessão. |
| sessão vencida, revogada ou de outro dilema | resposta genérica; não lê nem grava nenhuma linha de outro dilema. |
| revogação ou deleção do dilema | consultas de sessão falham imediatamente; o `ON DELETE CASCADE` remove a sessão quando a linha do dilema for removida. |

### Matriz de acesso após a task

| Recurso | `anon` direto | `authenticated` não-dono | Dono autenticado | Edge/RPC privada validada |
|---|---|---|---|---|
| `dilemmas` | nenhum | nenhum | CRUD somente próprio | projeção de um dilema com sessão válida |
| `profiles` | nenhum | somente o próprio perfil | CRUD somente próprio | nome de exibição do criador, somente dentro da projeção de convite válida |
| `participations` e `votes` | nenhum | nenhum nesta entrega | leitura futura de agregados do próprio dilema | sem acesso nesta Task 0 |
| `owner_expectations` | nenhum | nenhum | CRUD somente próprio | nenhum |
| `guest_access_sessions` | nenhum | nenhum | nenhum | criação/consulta somente pelas funções definidas |
| `outbox_jobs` | nenhum | nenhum | nenhum | somente worker com credencial de serviço |

Uma sessão não é uma conta, não contém nome, e-mail, push ou identificador estável de dispositivo. O segredo nunca aparece em SQL persistido, logs, analytics, erros, URL de retorno ou payload de observabilidade.

## 4. Critérios de aceite

1. Não existe política `SELECT`, `ALL`, `INSERT`, `UPDATE` ou `DELETE` em `dilemmas`, `participations`, `votes` ou `guest_access_sessions` concedida a `public` ou `anon`.
2. Um anônimo não lê um dilema, participação, voto, auto-previsão ou perfil de outra pessoa por consulta direta, mesmo conhecendo UUIDs válidos ou inventando um `guest_session_id`.
3. Um usuário autenticado só lê ou altera os próprios dilemas e o próprio perfil; não enumera perfis de terceiros.
4. Um convite inválido, revogado, apagado, moderado, fora do estado permitido ou vencido retorna a mesma resposta genérica e não cria sessão.
5. Um convite válido cria sessão de convidado com segredo de alta entropia, armazenado apenas como hash SHA-256, expira no máximo no prazo de pausa e fica vinculada a um único dilema.
6. Uma sessão emitida para o dilema A não obtém a projeção do dilema B, mesmo quando combinada com o ID, token ou segredo de B.
7. A projeção de convite válida contém apenas dados autorizados da Entrega 1: nome de exibição do criador, item, preço, moeda, categoria, finalidade, motivo, prazo e estado necessário. Ela não contém `total_votes`, razões, identidades de participantes, auto-previsão, imagem, URL, token/hash ou qualquer dado de decisão/Reveal.
8. A Edge Function define o segredo em cookie `HttpOnly`, `Secure`, `SameSite=Strict`, com expiração compatível e sem refletir o token de convite. Nenhum código de cliente recebe `service_role`.
9. As funções de publicação, decisão e reflexão não têm `EXECUTE` para `PUBLIC`; publicação fica restrita a `authenticated` e mutações adiadas permanecem inacessíveis a convidados.
10. `cd backend && npm run db:start`, `npm run db:migrate` e `npm run db:test` passam localmente. O job `Database policy tests` do CI deixa de falhar.

## 5. Plano técnico antes do código

### 5.1 Migration e contratos SQL

Adicionar uma migration com timestamp novo, por exemplo `backend/supabase/migrations/YYYYMMDDHHMMSS_guest_session_rls_foundation.sql`. Não editar `20260827000001`–`003`.

1. Criar `public.guest_access_sessions` com:
   - `id UUID` interno;
   - `dilemma_id UUID NOT NULL REFERENCES public.dilemmas(id) ON DELETE CASCADE`;
   - `session_secret_hash VARCHAR(64) NOT NULL UNIQUE`, com `CHECK` de digest SHA-256 hexadecimal de 64 caracteres;
   - `created_at`, `expires_at`, `revoked_at` e `last_seen_at` em UTC;
   - check de expiração posterior à criação e índice em `(dilemma_id, expires_at)` para validação/revogação.
2. Ativar RLS na nova tabela e não criar políticas de cliente para ela.
3. Remover políticas permissivas de convidado/público das tabelas base, inclusive políticas de recursos adiados que ainda permitam `anon` sem escopo. Substituir `profiles_select_authenticated USING (true)` por leitura do próprio perfil; a identidade do criador virá somente da projeção de convite validada.
4. Manter políticas do dono somente para `authenticated`, com `USING` e `WITH CHECK` explícitos. Separar políticas por operação se isso tornar a validação mais clara.
5. Revogar `EXECUTE` de `PUBLIC` nas funções atuais e conceder somente por função e papel. Toda função `SECURITY DEFINER` nova ou alterada fixa `search_path` e valida estado, autorização e escopo antes de acessar dados.
6. Descontinuar `exchange_invite_token(TEXT)`: sua forma atual inclui imagens, URL e `total_votes`. Criar o contrato substituto `open_guest_invite_session(p_invite_token_plain TEXT, p_session_secret_plain TEXT)` para uso exclusivo da Edge Function, retornando a projeção mínima definida nesta task. Atualizar os testes para o novo contrato; não manter uma RPC pública paralela com resposta mais ampla.

Não há backfill de dados: ainda não existe cliente publicado nem dado de produção. A migration é aditiva exceto pelas políticas e pelo contrato de função inseguro, que devem ser substituídos antes de qualquer integração cliente.

### 5.2 Borda HTTP de convidado

Criar `backend/supabase/functions/guest-invite/index.ts` como única entrada web para troca de convite.

1. Receber o token somente no corpo da requisição HTTPS; nunca o registrar nem incluí-lo em redirecionamento, resposta de erro, analytics ou logs.
2. Gerar o segredo criptograficamente seguro no servidor e chamar a RPC privada com token e segredo. A Edge Function não faz `SELECT`/`INSERT` direto nas tabelas com `service_role`.
3. Definir cookie de sessão opaco com `HttpOnly`, `Secure`, `SameSite=Strict`, `Path` limitado ao fluxo de convite e `Max-Age` igual ou inferior à expiração calculada.
4. Retornar a projeção autorizada ou uma resposta genérica idêntica para todos os erros de convite. Definir `Referrer-Policy: no-referrer`, `Cache-Control: no-store` e `X-Robots-Tag: noindex, nofollow`.

### 5.3 Sequência de implementação

1. Escrever primeiro os testes pgTAP comportamentais que reproduzem os quatro vazamentos atuais e os novos limites de sessão.
2. Criar a migration, aplicar localmente e fazer o schema contract continuar verde.
3. Implementar/substituir as RPCs e os grants mínimos; repetir pgTAP até todos os casos passarem.
4. Implementar a Edge Function e seus testes de contrato HTTP/cookie, sem criar interface web.
5. Executar a revisão adversarial de Segurança/LGPD e QA; somente então liberar a Task 1 de voto.

## 6. Estratégia de testes

| Camada | Cenários obrigatórios |
|---|---|
| pgTAP/RLS | anônimo sem token; UUID inventado; `guest_session_id` inventado; dono A contra dilema B; perfil de terceiro; auto-previsão privada; sessão A contra dilema B; convite inválido/revogado/vencido; ausência de `EXECUTE` indevido; outbox inacessível. |
| Integração SQL/RPC | sessão válida retorna somente a projeção allowlisted; não cria sessão para convite inválido; segredo persiste somente como hash; revogação invalida sessão; expiração bloqueia leitura. |
| Edge Function | cookie com atributos obrigatórios; ausência de token em logs/respostas; cabeçalhos de privacidade; mesma resposta genérica para falhas; função não expõe credencial de serviço. |
| E2E | não aplicável nesta task de fundação, pois não há cliente web/mobile. A Task 1 deve adicionar E2E convite → voto e link revogado antes de liberar a entrega. |

O teste de catálogo de políticas atual é insuficiente para a autorização de dono e deve ser substituído ou complementado por execução com papéis/claims simulados. Toda ramificação de função de autorização deve ser coberta por cenário de sucesso ou negação explícita; a regra de 80% da superfície alterada não pode ser satisfeita com asserts de texto em `pg_policies`.

## 7. Privacidade, analytics e observabilidade

- Dados novos: somente hash de segredo de sessão, IDs internos e timestamps. Não há contato, nome, IP, device fingerprint ou token em texto claro.
- Não criar eventos de produto nesta task. Se houver métrica operacional local, registrar apenas contagem de êxito/falha por motivo técnico allowlisted, sem token, URL, item, preço, texto livre ou ID pessoal.
- A prévia OpenGraph continua genérica e não consulta o banco. Tokens em rotas de convite exigem `Referrer-Policy: no-referrer` e páginas sem indexação/cache compartilhado.
- O plano concreto de limite por convite/sessão está em [Gate de beta externo — limite de taxa de convite](../guest-invite-external-beta-gate.md); ele é bloqueador de liberação, não justificativa para usar IP como identidade.

## 8. Riscos, compatibilidade e rollback

| Risco | Mitigação |
|---|---|
| Trocar policies quebra clientes existentes | Não há cliente integrado; aplicar a fundação antes da Task 1. Em ambientes futuros, lançar primeiro a Edge Function/RPC e depois remover rotas diretas. |
| Função com `SECURITY DEFINER` amplia privilégio | `search_path` fixo, grants mínimos, parâmetros validados, sem SQL dinâmico e testes de abuso. |
| Cookie ou token vaza em navegação | segredo fora do corpo de resposta, headers anti-referrer/no-store/noindex e logs com redação. |
| Rollback recria vulnerabilidade | Não restaurar políticas permissivas. Usar migration corretiva forward; em incidente, desabilitar a Edge Function e revogar sessões. |
| Rate limit ainda não provisionado | Bloquear beta externo até definir e testar o mecanismo, mantendo a API não exposta publicamente. |

## 9. Foco da revisão adversarial

Segurança/LGPD deve tentar acessar o dilema B com qualquer combinação de token, UUID, cookie ou `guest_session_id` obtidos do dilema A; chamar RPCs antigas diretamente; ler agregados antes do voto; chamar funções de dono como `anon`; e localizar segredo em cookie, resposta, log ou analytics.

QA deve tentar estados inválidos, revogação imediatamente após a abertura, expiração, deleção em cascata e migração limpa do zero. Produto deve confirmar que a projeção de convite não antecipa mídia, URL, razão, contato, agregados ou qualquer IA fora do escopo.

## 10. Definition of Done da Task 0

- migration nova, revisada e reproduzível por `npm run db:migrate` em uma stack local vazia;
- pgTAP, testes de contrato da Edge Function e todos os gates aplicáveis verdes;
- revisão independente de `security_privacy_reviewer` e `qa_reviewer` sem P0/P1 aberto;
- documentação de arquitetura e mini-PRD atualizadas somente se o contrato final divergir deste plano;
- nenhum ambiente remoto vinculado, alterado ou publicado.

## 11. Registro de implementação local

- As migrations `20260830000001`–`005` criam a sessão opaca, fecham grants e
  policies permissivas, validam o formato do hash, restringem a auto-previsão
  ao dilema do próprio dono e serializam abertura/revogação com `FOR UPDATE`.
  As migrations históricas `20260827000001`–`003` não foram alteradas.
- A Edge Function `guest-invite` é a única borda HTTP: usa `service_role`
  somente para a RPC privada, define cookie opaco e constrói uma resposta com
  allowlist explícita. Não há DML direto nem exposição de segredo ao cliente.
- Evidências locais: reset limpo, 54 testes pgTAP, teste de concorrência com
  duas conexões, contrato HTTP com cobertura acima de 80% e smoke Deno do
  entrypoint real. Os cenários incluem estados inválidos, deleção em cascata,
  revogação, sessão expirada e acesso cross-owner.
- A revisão de Segurança/LGPD não encontrou P0/P1 após as correções. O limite
  de taxa e a configuração de origem para cookie permanecem bloqueadores de
  beta externo no [gate de beta](../guest-invite-external-beta-gate.md).
