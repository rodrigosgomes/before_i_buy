# Task 1 — voto de convidado e agregados pós-voto

**Status:** implementação backend e integração browser local validadas; beta
externo permanece sujeito ao gate operacional
**Tipo:** vertical slice de produto, segurança e banco  
**Entrega relacionada:** [Entrega 1](../../01-product/first-delivery-mini-prd.md)  
**Depende de:** [Task 0 — sessão de convidado e fundação RLS](T0-guest-session-and-rls-foundation.md)

## 1. Resultado e contexto de produto

Como convidado sem conta, quero registrar ou alterar minha previsão no dilema que
recebi e, somente depois de votar, ver o resultado agregado sem identidades.

Esta task implementa a próxima vertical slice do handoff
`convite validado → voto do convidado`. Ela usa a sessão opaca e limitada a um
dilema criada na Task 0, mantém o voto como fato bruto para o Reveal futuro e
não antecipa decisão, reflexão, pontuação ou IA.

## 2. Escopo e não-escopo

### Escopo

- adaptar aditivamente `participations` para convidado sem nome persistente e
  vincular `guest_session_id` à sessão emitida pelo servidor;
- criar uma RPC privada e atômica para inserir ou substituir uma previsão
  `buy`, `wait` ou `skip` enquanto o dilema aceita votos;
- garantir uma única participação e um único voto ativo por sessão e dilema,
  inclusive sob concorrência;
- expor a submissão em `POST /functions/v1/guest-invite/vote`, autenticada pelo
  cookie `HttpOnly` da Task 0;
- devolver, após uma gravação bem-sucedida, somente a previsão confirmada, se
  ela substituiu uma previsão anterior e as contagens agregadas de `buy`,
  `wait`, `skip` e total;
- ampliar testes pgTAP, contrato HTTP, concorrência e smoke de runtime para o
  fluxo real `convite → cookie → voto` e para revogação.
- gerar tokens de convite no servidor com 256 bits e desabilitar a RPC legada
  que aceitava token fornecido pelo cliente;
- limitar abertura por convite e submissão por sessão com chaves HMAC efêmeras,
  sem IP ou fingerprint, conforme a DEC-010.

### Não-escopo

- página Next.js, componentes visuais, acessibilidade de interface ou
  instrumentação de métricas; serão tasks próprias quando `apps/guest-web`
  existir;
- rascunho/publicação Flutter e consulta de agregados pelo criador;
- decisão, reflexão, Reveal, score, ranking, auto-previsão ou qualquer IA;
- nome, e-mail, push, razão textual, comentário ou identificador persistente de
  convidado;
- imagens, URLs de produto, OpenGraph específico, feed, busca ou listagem;
- configuração e validação de `GUEST_WEB_ORIGIN`, cookie e limites no ambiente
  alvo; continuam bloqueadores operacionais de beta externo no
  [gate de beta](../guest-invite-external-beta-gate.md);
- deploy, `supabase link`, banco remoto ou reescrita de migration histórica.

## 3. Contratos de estado, dados e autorização

### 3.1 Estado do voto

| Condição | Resultado exigido |
|---|---|
| sessão válida, convite ativo, `collecting_votes` e prazo futuro | cria a participação sem identidade e grava a previsão; retorna agregados pós-voto. |
| nova previsão na mesma sessão e dilema | substitui atomicamente a anterior; permanece exatamente um voto ativo. |
| mesma previsão repetida | operação idempotente; não cria outra participação ou voto. |
| sessão ausente, forjada, vencida, revogada ou de outro dilema | resposta genérica; nenhuma escrita nem agregado. |
| convite revogado, dilema apagado/moderado, estado diferente de `collecting_votes` ou prazo alcançado | resposta genérica; nenhuma escrita nem agregado. |
| previsão fora de `buy`, `wait`, `skip` | rejeição sem escrita e sem ecoar entrada inválida. |
| limite por convite ou sessão excedido | `429` com corpo genérico, sem cookie, dado privado ou nova escrita de produto. |

O prazo e a revogação são validados no mesmo caminho transacional da escrita.
Uma revogação concorrente deve se serializar com a submissão: depois de a
revogação vencer o lock, nenhum voto novo é aceito.

### 3.2 Projeção pós-voto

A resposta bem-sucedida contém somente:

- `prediction`: `buy`, `wait` ou `skip`;
- `changed`: `true` apenas quando uma previsão anterior diferente foi
  substituída;
- `aggregates`: `buy`, `wait`, `skip` e `total`, todos como contagens inteiras.

Ela não contém nome, razão, IDs de participantes, ID interno da sessão, segredo
ou hash, token do convite, item, preço, expectativa do criador ou dados de
decisão/Reveal. Antes de uma gravação bem-sucedida, nenhuma rota ou RPC pública
devolve agregados.

### 3.3 Matriz de acesso

| Operação | `anon` direto | `authenticated` não-dono | Dono | Edge/RPC privada |
|---|---|---|---|---|
| inserir/alterar participação ou voto de convidado | nenhum | nenhum | nenhum direto nesta task | somente com segredo válido e escopo do dilema |
| ler voto individual/identidade | nenhum | nenhum | nenhum direto nesta task | não exposto |
| ler agregados pós-voto | nenhum | nenhum | fora desta task | somente como resultado da própria gravação válida |

## 4. Critérios de aceite

1. Convidado com sessão válida grava `buy`, `wait` ou `skip` sem conta, nome,
   contato ou razão textual.
2. A segunda previsão da mesma sessão substitui a primeira e mantém exatamente
   uma participação e um voto para o dilema.
3. Duas submissões concorrentes da mesma sessão não produzem duplicidade nem
   violação de integridade; o resultado persistido é uma das escolhas válidas.
4. Agregados aparecem somente na resposta posterior a um voto persistido e
   incluem apenas contagens anônimas cuja soma é `total`.
5. Sessão A não grava nem lê agregados do dilema B, mesmo combinando IDs,
   cookies ou tokens conhecidos.
6. Sessão ausente, inválida, expirada ou revogada, convite revogado, prazo
   vencido e estado inválido retornam o mesmo contrato genérico e não alteram
   `participations` ou `votes`.
7. Revogação concorrente com submissão é serializada; uma revogação confirmada
   impede votos subsequentes imediatamente.
8. `participations.guest_session_id` referencia uma sessão real e convidado não
   persiste `display_name`; acesso direto de `anon` às tabelas continua negado.
9. A RPC é `SECURITY DEFINER`, fixa `search_path`, não é executável por
   `PUBLIC`, `anon` ou `authenticated` e é concedida apenas a `service_role`.
10. O handler mantém `Cache-Control: no-store`, `Referrer-Policy: no-referrer`
    e `X-Robots-Tag: noindex, nofollow`, não retorna o cookie/segredo no corpo e
    nunca registra token, cookie, item, preço ou razão.
11. O smoke de runtime comprova `convite → cookie → voto → agregados` e que o
    mesmo cookie falha depois da revogação do convite.
12. Migração limpa, pgTAP, concorrência, testes do handler, smoke Deno,
    cobertura da superfície alterada >= 80% e `git diff --check` ficam verdes.
13. Publicação gera no servidor um token Base64URL de 43 caracteres, persiste
    apenas SHA-256, e os limites da DEC-010 usam somente chaves HMAC com TTL.
14. O contrato exige proxy same-origin preservando o path; POST com `Origin`
    diferente de `GUEST_WEB_ORIGIN` falha antes da RPC, e a Edge não oferece
    CORS com credenciais para acesso direto do navegador.

## 5. Plano técnico antes do código

### 5.1 Migration e RPC

Adicionar uma migration nova sem editar o histórico:

1. Remover o `NOT NULL` de `participations.display_name` e substituir o check
   legado por uma regra que exija exatamente uma identidade: usuário
   autenticado com nome ou sessão de convidado sem nome.
2. Adicionar FK de `participations.guest_session_id` para
   `guest_access_sessions(id) ON DELETE CASCADE`; validar dados existentes antes
   de ativar a constraint. Os índices únicos atuais continuam sendo a garantia
   de uma participação por identidade e dilema.
3. Criar `submit_guest_vote(p_dilemma_id UUID,
   p_session_secret_plain TEXT, p_prediction vote_prediction,
   p_rate_limit_key_hash TEXT)` como RPC privada:
   - validar tamanho do segredo e parâmetros;
   - bloquear a linha do dilema e confirmar convite ativo,
     `collecting_votes` e `pause_due_at > clock_timestamp()`;
   - localizar e bloquear a sessão pelo hash SHA-256, pelo mesmo dilema e por
     validade/revogação;
   - inserir/reusar participação sem nome e fazer upsert do voto;
   - calcular `changed` a partir do valor persistido anterior;
   - somente após o upsert, agregar votos por escolha e retornar a allowlist.
4. Revogar `EXECUTE` de todos os papéis de cliente e conceder somente a
   `service_role`. RLS e grants diretos permanecem fechados.
5. Trocar a publicação que recebia token do cliente por uma RPC autenticada que
   deriva no servidor um token HMAC-SHA-256 imprevisível usando chave de 256
   bits protegida pelo Vault; a mesma chave de idempotência repete o mesmo
   dilema e token sem persistir o token bruto.
6. Criar contador HMAC deny-by-default, atômico e efêmero: 30 aberturas por
   convite/minuto e 10 submissões por sessão/minuto, com TTL limitado ao prazo.

### 5.2 Edge Function

Evoluir a função `guest-invite` sem criar uma segunda borda privilegiada:

1. Manter `POST /functions/v1/guest-invite` para troca do token por cookie.
2. Adicionar `POST /functions/v1/guest-invite/vote`, ler o segredo somente do
   cookie `before_i_buy_guest_session` e receber no JSON apenas `dilemmaId` e
   `prediction`.
3. Validar formato do UUID e allowlist de previsão antes da RPC; usar uma
   resposta genérica para qualquer falha de sessão, estado ou autorização.
4. Montar a resposta por allowlist; não encaminhar colunas adicionais que uma
   RPC ou mock venha a devolver.
5. Exigir `GUEST_RATE_LIMIT_SECRET`, derivar HMAC com separação de escopo e
   devolver `429` genérico quando a RPC indicar excesso.
6. Exigir uma única `GUEST_WEB_ORIGIN` e rejeitar outra origem antes da RPC. O
   cliente web futuro deve usar reverse proxy same-origin, preservando o path e
   `Set-Cookie`; o cookie permanece `SameSite=Strict`, `Secure`, `HttpOnly` e
   com `Path` restrito, conforme a DEC-012.

### 5.3 Compatibilidade, risco e rollback

- Não há backfill esperado: não existe cliente de voto nem dado de produção.
  A migration deve falhar explicitamente se encontrar participação de
  convidado sem sessão correspondente, em vez de apagar ou inventar vínculos.
- O lock de dilema serializa submissão com revogação e limita a seção crítica a
  uma única vertical; testes de concorrência verificam duplicidade e bloqueio.
- Rollback operacional não restaura escrita direta. Em incidente, desabilitar a
  rota de voto e revogar `EXECUTE` da RPC; corrigir schema por migration forward.
- A mudança não cria analytics. `changed` habilita futuramente os eventos
  allowlisted `vote_submitted` e `vote_changed`, sem payload sensível.

## 6. Estratégia de testes

| Camada | Cenários obrigatórios |
|---|---|
| pgTAP/schema | FK para sessão real; exatamente uma identidade; cascata de exclusão de conta; token gerado no servidor; contador HMAC/TTL; grants mínimos; `anon` sem DML/leitura direta. A matriz enumera os ramos protegidos e deve exercitar ao menos 80% deles, sem omitir qualquer negação P0/P1. |
| Integração RPC | primeira escolha; repetição idempotente; troca de escolha; agregados consistentes; segredo errado; sessão cross-dilema, expirada e revogada; convite revogado; prazo/estado inválidos; previsão inválida; nenhuma escrita em falhas. A evidência registra ramos exercitados/planejados e exige cobertura de cenários >= 80%. |
| Concorrência | duas escolhas simultâneas na mesma sessão deixam uma participação e um voto; revogação serializa com submissão. |
| Contrato HTTP | cookie obrigatório e parseado sem exposição; `Path`, `Secure`, `HttpOnly` e `SameSite`; origem configurada e origem hostil; ausência de CORS com credenciais; UUID/enum inválidos; allowlist de resposta; headers de privacidade; mesma falha genérica; cobertura >= 80%. |
| E2E de sistema | Edge Function real e banco local: abrir convite, capturar cookie, votar, conferir agregados, revogar e confirmar bloqueio. |
| Web visual | não aplicável porque `apps/guest-web` ainda não existe; a futura task web deve adicionar Playwright, acessibilidade e tempo de voto. |
| Offline mobile | não aplicável: esta task não altera rascunho nem persistência mobile. |

Os testes de comportamento são escritos antes da implementação. Não vale
inspecionar apenas texto de policies ou aumentar cobertura com cenários que não
exercitem autorização e persistência reais.

### 6.1 Evidência mensurável de SQL/RPC/RLS

A [matriz de ramos SQL/RPC/RLS](T1-sql-branch-matrix.md) registra 55 de 59
ramos protegidos exercitados no banco real (`93,2%`). O denominador inclui os
ramos defensivos ainda não automatizados e nenhuma negação P0/P1 foi omitida.

## 7. Privacidade, analytics e observabilidade

- Dados novos persistidos: somente relação entre sessão pseudônima e escolha
  bruta, mais contadores HMAC efêmeros e timestamps previstos no schema.
- Não coletar IP como identidade, fingerprint, nome, e-mail, push ou razão.
- Não criar logs ou eventos de produto nesta task. Falhas HTTP são genéricas e
  não distinguem convite inexistente de sessão inválida ou revogada.
- Contagens agregadas são liberadas apenas depois do voto e nunca incluem
  identidades ou texto livre.
- O voto é removido em cascata quando a participação, sessão ou dilema é
  apagado; exclusão de conta remove participações autenticadas; retenção e
  backups continuam bloqueadores de liberação externa.

## 8. Foco da revisão adversarial

Produto deve tentar encontrar antecipação de decisão, Reveal, pontuação, IA,
identidade de convidado ou agregados antes do voto. Segurança/LGPD deve combinar
cookie de A com dilema B, chamar a RPC diretamente como cliente, forjar
`guest_session_id`, explorar revogação concorrente e localizar segredo em
resposta/log. QA deve provocar retries, votos simultâneos, troca repetida,
expiração entre validação e escrita e soma inconsistente dos agregados.

## 9. Definition of Done da Task 1

- plano revisado por `product_reviewer` antes do código;
- migration aditiva reproduzível do zero e sem alteração das migrations
  `20260827000001`–`20260830000005`;
- testes planejados escritos e executados, com cobertura >= 80% em cada
  superfície mensurável alterada; para SQL/RPC/RLS, a evidência é a matriz de
  ramos protegidos exercitados, também >= 80% e sem negação crítica omitida;
- revisão paralela de `security_privacy_reviewer` e `qa_reviewer` sem P0/P1
  aberto;
- todos os gates locais aplicáveis verdes;
- nenhum deploy, link remoto, publicação, commit ou push sem pedido explícito.

## 10. Registro da revisão de produto

O `product_reviewer` encontrou um P1 no plano inicial: a Definition of Done
mencionava cobertura quantitativa apenas para o handler, em conflito com a
DEC-006. O plano foi corrigido antes do código para exigir cobertura >= 80% por
superfície e uma matriz explícita de ramos SQL/RPC/RLS. Não restou achado de
produto aberto para iniciar os testes.

## 11. Registro da implementação e revisão adversarial

### Evidência local verde

- migration reaplicada do zero com `supabase db reset`;
- pgTAP: 3 arquivos, 125 testes;
- contrato Edge: `95,53%` linhas, `90,00%` ramos e `94,44%` funções;
- concorrência: 4 de 4 cenários, incluindo expiração depois de aguardar lock;
- runtime real: convite, cookie, voto, agregados, limites 30/10, `429` sem
  mutação e revogação;
- matriz SQL/RPC/RLS: 55 de 59 ramos (`93,2%`).

### Achados fechados

- revisão de produto: gate SQL/RPC/RLS abaixo de 80% não estava mensurável;
- primeira revisão de segurança: cascata de conta incompatível, ausência de
  limite e token controlado pelo cliente;
- revisão de QA: publicação não idempotente, matriz SQL ausente, limites não
  atravessavam a Edge real e teste temporal não comprovava espera no lock;
- segunda revisão: DML direto contornava a publicação, maioridade/consentimento
  não eram validados e o contrato não verificava o `Path` do cookie.

Todos foram corrigidos e cobertos. A re-revisão final de QA não encontrou
P0/P1.

### Integração browser concluída localmente

A [Task 2 — web de convidado e proxy same-origin](T2-guest-web-same-origin-voting.md)
implementou a DEC-012 em `apps/guest-web`: o browser usa somente os caminhos
same-origin, o proxy preserva `Origin`, cookie, `Set-Cookie` e o `Path` restrito,
e o Playwright comprovou `convite → cookie → voto → agregados` e resposta genérica
para convite indisponível. Isso fecha o P1 de integração local desta task.

O [gate de beta externo](../guest-invite-external-beta-gate.md) continua
necessário: domínio HTTPS real, segredos/configuração no alvo e smoke no ambiente
publicado não foram autorizados nem executados.
