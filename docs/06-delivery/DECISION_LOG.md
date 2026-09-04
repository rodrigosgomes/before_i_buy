# Architectural & Product Decision Log (ADR)
**Projeto:** Before I Buy  
**Status:** Ativo  
**Finalidade:** Memória durável de decisões para Agentes de IA e Engenheiros.  

---

## Estrutura de uma Decisão

Cada entrada segue o padrão:
- **ID:** `DEC-XXX`
- **Data:** `AAAA-MM-DD`
- **Status:** `Proposto` | `Aceito` | `Substituído por DEC-YYY`
- **Contexto:** Por que a decisão foi necessária?
- **Decisão:** Qual foi a escolha técnica ou de produto?
- **Consequências:** O que ganhamos e quais os trade-offs?
- **Gatilho de Revisão:** Sob qual condição esta decisão deve ser reavaliada?

---

## Registro Histórico de Decisões

### DEC-001: Loop Fechado Privado por Link de Convite (Sem Feed Público)
- **Data:** 2026-08-26
- **Status:** `Aceito`
- **Contexto:** Redes sociais públicas expõem desejos de consumo e geram problemas de moderação, assédio e ruído. O valor central está em pedir conselhos a quem nos conhece.
- **Decisão:** MVP focado estritamente em dilemas privados compartilhados por link de convite (WhatsApp, Telegram, iMessage). Sem feed público, sem busca global de usuários e sem seguidores.
- **Consequências:** Redução drástica de complexidade de moderação e foco em retenção por ciclo social fechado.
- **Gatilho de Revisão:** O loop privado atingir retenção sustentável e os usuários pedirem explicitamente descoberta de novos círculos.

---

### DEC-002: Separação de Clientes (Flutter Mobile + Next.js Web Convidado)
- **Data:** 2026-08-26
- **Status:** `Aceito`
- **Contexto:** Criadores precisam de rascunhos offline robustos e notificações nativas. Convidados precisam abrir o link no WhatsApp e votar em menos de 15 segundos sem instalar app.
- **Decisão:** Flutter para o App Mobile (iOS/Android) e Next.js (SSR ultraleve $<150$KB) para a página web de votação de convidados. Supabase/PostgreSQL como backend unificado.
- **Consequências:** Dois projetos de apresentação (duplicação controlada de contratos/tokens), compensada pela velocidade de carregamento para convidados. Flutter Web descartado para convidados devido ao peso do bundle inicial.
- **Gatilho de Revisão:** Piora inaceitável de produtividade na sincronização de contratos entre Flutter e Web.

---

### DEC-003: Security & Privacy by Design (RLS Deny-by-Default + Hash SHA-256)
- **Data:** 2026-08-26
- **Status:** `Aceito`
- **Contexto:** Dilemas contêm vulnerabilidade emocional, preços e notas íntimas. Vazamento de dados destruiria a confiança no produto.
- **Decisão:**
  1. RLS ativado com política *Deny-by-Default* em 100% das tabelas.
  2. Tokens de convite com $\ge 128$ bits de entropia; banco persiste apenas o hash SHA-256.
  3. Previews OpenGraph 100% neutras para mensageiros.
  4. Exclusão física de dados e mídias (*hard delete*) em $\le 48$ horas conforme LGPD.
- **Consequências:** Segurança criptográfica robusta e conformidade legal desde o DDL inicial.
- **Gatilho de Revisão:** Necessidade de links com expiração dinâmica ou múltiplos papéis de visualização.

---

### DEC-004: Início Direto em Código (Salto da Fase 0 Concierge)
- **Data:** 2026-08-26
- **Status:** `Aceito`
- **Contexto:** A dor de compras por impulso emocional em adultos brasileiros foi considerada validada pelo Product Owner.
- **Decisão:** Pular a fase de protótipo manual/concierge e iniciar diretamente a Sprint 1 de Engenharia com banco de dados, RLS e clientes funcionais.
- **Consequências:** Maior velocidade de entrega de software real; o teste de aderência da reflexão tardia (7d/30d) será medido diretamente com métricas em produção.
- **Gatilho de Revisão:** Queda da taxa de conclusão de reflexão abaixo de 30% nas primeiras semanas de beta fechado.

---

### DEC-005: Tropa de Especialistas de IA em `.agents/skills/`
- **Data:** 2026-08-26
- **Status:** `Aceito`
- **Contexto:** Projetos complexos assistidos por IA sofrem quando um único prompt genérico tenta resolver banco, frontend, segurança e testes ao mesmo tempo.
- **Decisão:** Estruturar 7 skills especializadas sob demanda no padrão Antigravity:
  1. `dba-postgres-architect`
  2. `security-guardian`
  3. `privacy-lgpd`
  4. `qa-test-engineer`
  5. `product-owner`
  6. `uiux-playful-calm`
  7. `devops-deploy`
- **Consequências:** Ativação modular de contexto (*progressive disclosure*), mantendo tokens enxutos e respostas cirúrgicas.
- **Gatilho de Revisão:** Criação de novos subsistemas (ex: billing/monetização futura exigindo nova skill).

---

### DEC-006: Quality Gate Inegociável ($\ge 80\%$ de Cobertura de Testes)
- **Data:** 2026-08-26
- **Status:** `Aceito`
- **Contexto:** Código gerado por IA precisa de barreiras de contenção automatizadas para evitar regressões e alucinações.
- **Decisão:** Cobertura de testes unitários e de integração obrigatória $\ge 80\%$ em todas as camadas (Flutter, Web e RLS), com verificação automatizada bloqueando o pipeline de CI/CD.
- **Consequências:** Disciplina obrigatória de TDD. Nenhum PR é mesclado sem suíte de testes verdes.
- **Gatilho de Revisão:** Cobertura se tornar gargalo em testes puramente visuais (exceção específica para mocks de UI).

---

### DEC-007: Vertical Slice Architecture & Schema-First
- **Data:** 2026-08-26
- **Status:** `Aceito`
- **Contexto:** Arquiteturas em muitas camadas horizontais (Clean Architecture tradicional com 5+ arquivos por CRUD) sobrecarregam o contexto de tokens da IA.
- **Decisão:** Código organizado por funcionalidade (*Vertical Slices*), com Schema SQL como verdade única e tipagem estrita (Dart/TypeScript). Princípio *Ponytail* (simplicidade, sem abstrações especulativas).
- **Consequências:** Facilidade de manutenção por IA e menor raio de explosão em refatorações.
- **Gatilho de Revisão:** Código de features compartilhadas começar a sofrer duplicação excessiva (regra da 3ª repetição).

---

### DEC-008: Arquitetura de Memória Controlada em 3 Camadas
- **Data:** 2026-08-26
- **Status:** `Aceito`
- **Contexto:** Agentes de IA perdem contexto entre sessões de chat se o conhecimento não for persistido de forma estruturada.
- **Decisão:**
  1. *Memória Durável:* Arquivos versionados no Git (`AGENTS.md`, `AI_PLAYBOOK.md`, `DECISION_LOG.md`).
  2. *Memória de Tarefa:* `implementation_plan.md` e checklists de sprint.
  3. *Memória de Sessão:* `ctx_memory` (Context-Mode) e Knowledge Items locais.
- **Consequências:** Continuidade perfeita do trabalho entre diferentes agentes ou reinicializações de sessão.
- **Gatilho de Revisão:** Mudança de ferramentas de contexto da IDE.

---

### DEC-009: Primeira Entrega Técnica Focada em Criação Privada, Convite e Voto
- **Data:** 2026-08-30
- **Status:** `Aceito`
- **Contexto:** O MVP completo depende do loop fechado, mas iniciar simultaneamente por decisão, reflexão, Reveal, mídia, notificações e moderação aumentaria o risco e retardaria a primeira evidência de criação e participação.
- **Decisão:** A primeira entrega técnica cobre rascunho local explícito, publicação privada, convite revogável e voto anônimo de convidado. Ela preserva os contratos de estado para `decision_due`, mas não implementa decisão, reflexão, Reveal, pontuação, IA, imagens, URLs, razões de voto ou coleta de contato do convidado.
- **Consequências:** A equipe consegue testar as duas primeiras transições com privacidade e autorização completas. As entregas seguintes devem adicionar o restante do loop sem reinterpretar votos já persistidos.
- **Gatilho de Revisão:** A entrega só é ampliada antes da conclusão se os testes mostrarem que ausência de mídia, URL ou razão de voto impede materialmente a compreensão ou conversão.

---

### DEC-010: Tokens de Convite Gerados no Servidor e Limite Efêmero sem IP
- **Data:** 2026-08-31
- **Status:** `Aceito`
- **Contexto:** A borda pública de convite precisa impedir tokens previsíveis e abuso de abertura/voto sem transformar IP, device fingerprint ou contato em identidade de produto.
- **Decisão:**
  1. A RPC autenticada de publicação gera 32 bytes criptograficamente aleatórios no servidor, retorna o token Base64URL de 43 caracteres uma única vez ao criador e persiste somente SHA-256.
  2. A Edge Function deriva chaves HMAC-SHA-256 separadas por escopo, usando segredo de ambiente com ao menos 32 bytes; token e segredo de sessão nunca são usados como chave persistida.
  3. PostgreSQL mantém contadores com RLS deny-by-default e TTL máximo de 60 segundos, sempre limitado ao prazo do dilema/sessão: até 30 aberturas por convite/minuto e até 10 submissões por sessão/minuto.
  4. Contadores vencidos são removidos oportunisticamente; não coletamos IP, fingerprint, nome ou contato. Excesso devolve `429` com corpo genérico e headers de privacidade.
- **Consequências:** A primeira entrega fecha os dois vetores críticos sem provedor externo nem novo identificador pessoal. O limite por convite é compartilhado entre convidados e pode produzir bloqueio temporário em picos acima de 30 aberturas por minuto.
- **Gatilho de Revisão:** Tráfego real mostrar falsos positivos, abuso distribuído que contorne a chave por convite/sessão ou necessidade operacional de um contador externo multi-região.

---

### DEC-011: Publicação Idempotente com Token Derivado por Chave no Vault
- **Data:** 2026-08-31
- **Status:** `Aceito`
- **Contexto:** A publicação recebe uma chave de idempotência para tolerar timeout e retry, mas um token aleatório retornado apenas uma vez não pode ser repetido sem guardar seu valor bruto. Criar outro dilema viola o contrato; guardar o token em texto claro viola a DEC-003.
- **Decisão:** O servidor cria e mantém no Supabase Vault uma chave aleatória de 256 bits. A RPC deriva deterministicamente o token Base64URL com HMAC-SHA-256 sobre versão do contrato, `owner_id` e `client_idempotency_key`, serializa retries e impõe unicidade por dono/chave. O mesmo payload repete o mesmo `dilemma_id` e token; payload diferente falha fechado. Somente o SHA-256 do token é persistido na tabela de produto. Esta decisão substitui apenas a geração aleatória por chamada descrita no item 1 da DEC-010; os demais limites e regras permanecem.
- **Consequências:** Retry após resposta perdida é seguro sem duplicar dilema nem persistir o token recuperável. A chave do Vault passa a ser segredo operacional crítico e deve participar de backup, controle de acesso e rotação planejada; rotação sem estratégia invalidaria o replay de publicações anteriores.
- **Gatilho de Revisão:** Mudança de provedor de segredos, necessidade de rotação da chave ou adoção de um serviço dedicado de idempotência/publicação.

---

### DEC-012: Proxy Same-Origin para o Cookie do Convidado
- **Data:** 2026-09-01
- **Status:** `Aceito`
- **Contexto:** A página web e a Edge Function são clientes separados, mas o cookie de voto não deve depender de third-party cookies, `SameSite=None` ou CORS com credenciais. O runtime local do Supabase também intercepta preflight com origem ampla, inadequada para esse segredo.
- **Decisão:** O navegador acessa `/functions/v1/guest-invite` por reverse proxy no mesmo domínio da página web, preservando path e `Set-Cookie`. A Edge não oferece contrato CORS para chamada direta do navegador. Cada ambiente configura exatamente uma `GUEST_WEB_ORIGIN`, HTTPS fora de localhost, e POSTs com `Origin` diferente são negados antes da RPC. O cookie permanece `Secure; HttpOnly; SameSite=Strict` e restrito a `Path=/functions/v1/guest-invite`. Chamadas sem `Origin` existem somente para smoke e integrações servidor-servidor que já possuam o segredo.
- **Consequências:** O fluxo não depende de cookies cross-site e mantém defesa CSRF por `SameSite=Strict` mais validação de origem. O reverse proxy e a preservação de headers/caminho tornam-se pré-requisitos do cliente web e do beta externo.
- **Gatilho de Revisão:** Mudança do host web, múltiplos domínios legítimos ou plataforma de proxy incapaz de preservar `Set-Cookie` e path.

---

### DEC-013: Autenticação do Criador por Magic Link de E-mail
- **Data:** 2026-09-01
- **Status:** `Substituído por DEC-014`
- **Contexto:** A publicação privada exige autoria recuperável e um perfil com confirmação de maioridade e consentimentos. Senha, SMS e provedores sociais acrescentariam recuperação, custo, dados ou integrações que não ajudam a validar a Entrega 1.
- **Decisão:** O criador entra por magic link de e-mail via Supabase Auth. O e-mail serve somente à autenticação; não entra em perfil público, analytics, convites, voto ou comunicação de convidado. Após a primeira sessão, o app exige nome de exibição, autoafirmação +18 e aceite separado de Termos/Aviso antes de permitir a publicação. O cliente recebe apenas URL e chave pública por configuração de ambiente; `service_role` permanece exclusiva do backend.
- **Consequências:** O fluxo evita senha e mantém a identidade do criador recuperável, mas requer configuração segura de redirecionamento e envio de e-mail em cada ambiente. A cópia, versão e base legal de Termos/Aviso continuam bloqueadores de beta externo; builds internos usam configuração explicitamente marcada como não-beta.
- **Gatilho de Revisão:** Baixa conversão de entrada, custo/entregabilidade de e-mail ou necessidade comprovada de login social.

---

### DEC-014: Autenticação Nativa do Criador por Google
- **Data:** 2026-09-03
- **Status:** `Aceito`
- **Contexto:** O callback do magic link retornava ao `localhost` sem um
  consumidor disponível, adicionando uma dependência de redirecionamento e
  fricção sem ajudar o loop da Entrega 1.
- **Decisão:** O criador entra por Google Sign-In nativo em Android e iOS. O
  app obtém ID/access tokens pelo SDK do Google e os entrega ao Supabase Auth;
  não há callback web, magic link ou senha. O identificador Android/iOS é
  `br.com.myelolabs.eloease`. Apple Sign In fica em task posterior, obrigatória
  antes de qualquer envio à App Store.
- **Consequências:** Google Cloud e Supabase Auth precisam de clientes Web,
  Android e iOS, todos de desenvolvimento inicialmente. Client Secret fica
  somente em Google Cloud/Supabase; o app recebe URL, chave publicável e Client
  IDs públicos por configuração local. Nome e e-mail do Google não aparecem em
  convites, analytics ou perfil público. Sem páginas jurídicas reais, o OAuth
  permanece em modo Testing e não habilita beta público.
- **Gatilho de Revisão:** Baixa conversão, erro de compatibilidade nativa ou a
  preparação da primeira submissão iOS, quando Apple Sign In e exclusão de
  conta passam a ser requisitos de liberação.

---

### DEC-015: Consentimento Interno Versionado para Publicação no Desenvolvimento
- **Data:** 2026-09-03
- **Status:** `Aceito`
- **Contexto:** A Task 3A coleta apenas uma fixture local marcada como interna.
  A publicação idempotente exige perfil remoto com maioridade e versões de
  Termos/Aviso, mas ainda não há textos jurídicos aprovados para beta externo.
- **Decisão:** Exclusivamente no projeto Supabase de desenvolvimento, o perfil
  do criador poderá registrar as versões `internal-demo-v1` de Termos e Aviso
  por uma RPC autenticada e estreita. As versões são validadas no servidor,
  sempre exibidas como conteúdo interno sem validade jurídica e não podem ser
  escolhidas livremente pelo cliente. O fluxo continua sem analytics e sem
  usar nome ou e-mail vindos do Google.
- **Consequências:** Permite validar perfil remoto, publicação privada e
  convite real no ambiente de desenvolvimento. Não autoriza beta externo,
  produção, promoção do OAuth, nem substitui revisão jurídica, bases legais,
  retenção, exclusão de conta ou documentos públicos reais. A promoção futura
  exige desativar a versão interna e cadastrar versões jurídicas aprovadas.
- **Gatilho de Revisão:** Antes de qualquer domínio público, deploy do Web
  convidado para terceiros, beta externo ou envio a lojas.
