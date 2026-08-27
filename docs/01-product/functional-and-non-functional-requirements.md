# Especificação de Requisitos Funcionais e Não Funcionais

**Produto:** Before I Buy  
**Versão:** 1.0 (MVP)  
**Status:** Aprovado para Definição de Arquitetura e Stack  

---

## 1. Visão Geral e Contexto

O **Before I Buy** é um jogo social privado de tomada de decisão voltado a compras discricionárias. Seu objetivo é ajudar adultos a interromperem impulsos de compra imediatos, coletarem previsões de amigos de confiança e fecharem o ciclo de aprendizagem através de uma reflexão tardia (*Reveal*).

Este documento formaliza todos os **Requisitos Funcionais (RF)** e **Requisitos Não Funcionais (RNF)** para orientar as decisões de arquitetura de software, modelagem de dados, infraestrutura e escolha de stack tecnológica.

---

## 2. Requisitos Funcionais (RF)

### Módulo A: Autenticação, Usuários e Elegibilidade
* **RF-01 (Elegibilidade e Cadastro):** O sistema deve permitir cadastro e login de criadores (*Owners*) via *Magic Link* (e-mail) ou autenticação social (Apple/Google), exigindo confirmação explícita de maioridade (+18) e aceite dos Termos de Uso e Política de Privacidade (LGPD).
* **RF-02 (Participação de Convidados sem Conta):** O sistema deve permitir que convidados votem em dilemas via web sem a necessidade de criar conta prévia ou fornecer dados cadastrais completos.
* **RF-03 (Reivindicação de Histórico):** O sistema deve permitir que um convidado, ao criar uma conta posteriormente, reivindique o histórico de previsões realizadas em sessões anônimas anteriores mediante token de claim.
* **RF-04 (Gestão e Exclusão de Perfil):** O usuário autenticado deve poder editar seu perfil básico (nome de exibição/avatar) e solicitar a exclusão total e irrevogável de sua conta e dados pessoais.

---

### Módulo B: Criação e Gestão de Dilemas (Tentações)
* **RF-05 (Criação de Dilema):** O sistema deve permitir a criação de um dilema com os seguintes campos:
  * *Obrigatórios:* Nome do item (2–80 chars), Preço estimado (> 0), Moeda (ISO 4217, default BRL), Categoria, Motivo do desejo (10–500 chars), Janela de pausa (24 horas, 3 dias ou 7 dias).
  * *Opcionais:* 1 imagem do item, URL do produto, tempo que já deseja o item, Propósito da compra (`for_self` [próprio] ou `gift` [presente]).
* **RF-06 (Auto-Previsão Privada do Criador):** O sistema deve permitir, opcionalmente e de forma privada, que o criador responda à pergunta: *"Você acha que o 'Você do Futuro' faria a mesma escolha?"* (Sim / Em dúvida / Não). Essa resposta nunca é exibida aos votantes.
* **RF-07 (Rascunho Offline Seguro):** O app mobile deve salvar rascunhos localmente no dispositivo em caso de perda de conexão. Rascunhos offline devem ser identificados como *"Rascunho — não compartilhado"* e **nunca** devem ser publicados silenciosamente após reconexão; exigem revisão e clique explícito de publicação pelo criador.
* **RF-08 (Publicação e Geração de Convite):** A publicação de um dilema deve gerar um link de convite único, com token criptográfico de alta entropia, não indexável por motores de busca.
* **RF-09 (Revogação de Link):** O criador deve poder revogar um link de convite a qualquer momento, invalidando acessos futuros ou gerando um novo link de acesso.

---

### Módulo C: Votação e Interação Social (Convidado)
* **RF-10 (Visualização do Dilema pelo Convidado):** O link de convite deve exibir uma página web responsiva com as informações do item (imagem, nome, categoria, motivo e tempo restante de votação), ocultando o resultado parcial dos votos até que o convidado vote.
* **RF-11 (Mecânica de Votação Futura):** O convidado deve poder submeter 1 voto entre 3 opções:
  * **Comprar:** Acredita que a compra trará satisfação real e duradoura.
  * **Esperar:** Acredita que o momento é inadequado ou exige pesquisa adicional.
  * **Deixar pra lá:** Acredita que o desejo passará e a compra gerará arrependimento/desperdício.
* **RF-12 (Justificativa de Voto):** O votante pode incluir um motivo textual opcional de até 280 caracteres junto ao seu voto.
* **RF-13 (Opt-in Isolado para Revelação - Reveal):** Após votar, o convidado pode optar por receber a notificação do desfecho (*Reveal*) fornecendo e-mail ou push web, com consentimento restrito exclusivamente àquele dilema (sem autorização de marketing).

---

### Módulo D: Tomada de Decisão e Fechamento do Ciclo (Closed Loop)
* **RF-14 (Painel de Resultados do Criador):** O criador deve ter acesso aos votos consolidados e justificativas dos amigos imediatamente após votar ou após o encerramento da janela de pausa.
* **RF-15 (Atualização de Decisão pelo Criador):** O criador deve registrar a decisão tomada entre os seguintes estados:
  * `bought_original`: Comprou o item original.
  * `bought_alternative`: Comprou uma alternativa diferente.
  * `skipped`: Desistiu da compra.
  * `unavailable`: Item esgotado/indisponível.
  * `still_deciding`: Ainda avaliando (extensão temporária).
* **RF-16 (Agendamento de Reflexão Tardia por Categoria):** O sistema deve disparar automaticamente o lembrete de reflexão com base no tipo de decisão e categoria:
  * Itens comprados perecíveis / experiências rápidas / delivery: **7 dias**.
  * Itens comprados duráveis (eletrônicos, moda, móveis, ferramentas): **30 dias**.
  * Itens com desistência (`skipped`): **7 dias**.
* **RF-17 (Registro da Reflexão Tardia):** O criador responde à pergunta central de satisfação: *"Você faria a mesma escolha de novo?"* com 3 opções: **Sim**, **Não tenho certeza**, **Não**. Pode registrar um comentário opcional e indicar se o item foi devolvido/reembolsado ou doado.
* **RF-18 (Revelação Pública do Desfecho - Reveal):** O sistema deve liberar a tela de *Reveal* para os votantes que deram opt-in, exibindo:
  * A decisão real do criador e sua reflexão tardia.
  * Quem acertou a previsão de satisfação futura (previsões `Comprar` com reflexão `Sim`, ou previsões `Deixar pra lá` com decisão `skipped` e reflexão `Sim`).
  * Previsões do tipo `Esperar` não são pontuadas como erro ou acerto para manter neutralidade.

---

### Módulo E: Histórico, Insights e Moderação
* **RF-19 (Histórico Pessoal de Autoconhecimento):** O criador deve visualizar seu histórico privado de decisões, taxa de impulsos evitados com sucesso e nível de satisfação pós-compra por categoria.
* **RF-20 (Histórico de Previsões do Votante):** O participante autenticado deve ter um placar pessoal de acertos de intuição sobre as escolhas dos amigos.
* **RF-21 (Denúncia e Bloqueio):** Usuários e convidados devem poder denunciar dilemas impróprios (conteúdo explícito, dados confidenciais, assédio). O criador pode bloquear participantes específicos.
* **RF-22 (Painel de Operações / Moderação):** O operador do sistema deve poder visualizar denúncias, ocultar conteúdo abusivo e desativar tokens violadores.

---

## 3. Requisitos Não Funcionais (RNF)

### RNF-01: Performance, Latência e Tempo de Resposta
* **RNF-01.1 (Tempo de Carregamento Web de Voto):** A página de votação para convidados deve atingir *Largest Contentful Paint* (LCP) $\le 1.5$ segundos e *First Input Delay* (FID) / *Interaction to Next Paint* (INP) $\le 100$ ms em conexões móveis 3G/4G.
* **RNF-01.2 (Tamanho do Bundle Web):** O payload inicial da aplicação web de votação não deve exceder $150$ KB (gzipped), garantindo abertura instantânea via WhatsApp/Instagram sem requerer instalação.
* **RNF-01.3 (Latência de API):** Todas as mutações críticas (votar, criar dilema, atualizar decisão) devem responder em $\le 200$ ms no percentil 95 ($p95$).
* **RNF-01.4 (Tempo de Publicação):** O fluxo de criação e publicação completa de um dilema deve levar menos de 2 minutos para um usuário comum.

---

### RNF-02: Segurança, Privacidade e LGPD (Privacy by Design)
* **RNF-02.1 (Row Level Security - RLS Deny-by-Default):** Todas as tabelas do banco de dados relacional devem ter políticas de RLS ativas, bloqueando qualquer leitura ou escrita não autorizada no nível da linha.
* **RNF-02.2 (Criptografia e Proteção de Tokens de Convite):** Os links de convite devem conter tokens aleatórios com entropia $\ge 128$ bits. O banco de dados deve persistir apenas o hash seguro (ex: SHA-256) do token, nunca o token em texto puro.
* **RNF-02.3 (Prevenção de Vazamento em OpenGraph / Metatags):** Links compartilhados em aplicativos de mensagens (WhatsApp, Telegram, iMessage) devem gerar prévias neutras e genéricas (*"Você foi convidado para opinar sobre uma decisão de compra"*), sem expor nome do item, valor, foto ou autor na metatag pública.
* **RNF-02.4 (Exclusão e Retenção LGPD):** Ao solicitar exclusão de conta, todos os dilemas, imagens do storage, rascunhos e vínculos de votos devem ser eliminados fisicamente (*hard delete* ou anonimização criptográfica irreversível) em até 48 horas.
* **RNF-02.5 (Isolamento de Dados de Convidado):** Endereços de e-mail ou push tokens coletados de convidados para o *Reveal* devem ser armazenados com escopo restrito ao ID do dilema e apagados automaticamente 30 dias após o envio do *Reveal*.

---

### RNF-03: Confiabilidade, Agendamento e Tolerância a Falhas
* **RNF-03.1 (Motor de Agendamento Confiável - Outbox Pattern):** Os lembretes de reflexão agendados para 7 ou 30 dias no futuro devem utilizar uma fila persistente e tolerante a reinicializações. Nenhum job pode ser perdido devido a reinício de servidor.
* **RNF-03.2 (Idempotência de Disparos):** O sistema de envio de notificações (Push/E-mail) deve ser estritamente idempotente, garantindo que um usuário nunca receba notificações duplicadas sobre a mesma reflexão.
* **RNF-03.3 (Resiliência Offline no Mobile):** O aplicativo mobile deve operar com tolerância a falhas de rede, armazenando rascunhos em banco de dados local criptografado (SQLite / Hive / SecureStorage).

---

### RNF-04: Usabilidade, Acessibilidade e Design Emocional
* **RNF-04.1 (Diretriz Visual Playful Calm):** A interface deve seguir a direção de design *Playful Calm* (Material Design 3 Expressive, cantos entre 18–28px, tipografia acolhedora, microinterações fluidas). É expressamente proibido o uso de estética bancária fria, contadores regressivos de urgência ou elementos de culpa financeira.
* **RNF-04.2 (Acessibilidade WCAG 2.1 AA):** Todo o produto (Web e Mobile) deve atingir conformidade mínima WCAG 2.1 nível AA (contraste de cor $\ge 4.5:1$ para textos normais, suporte a leitores de tela e áreas de toque mínimas de $48 \times 48$ dp).
* **RNF-04.3 (Responsividade Mobile-First):** A interface web de convidados deve ser perfeitamente utilizável em telas a partir de 320px de largura até desktops, priorizando o layout de 393 × 852 px (viewport de smartphone moderno).

---

### RNF-05: Escalabilidade e Eficiência Operacional
* **RNF-05.1 (Elasticidade de Votação Viral):** A camada de recebimento de votos deve suportar picos repentinos de acesso (ex: um link compartilhado em um grupo de 100 pessoas) sem degradação de performance.
* **RNF-05.2 (Custos Operacionais Enxutos):** A arquitetura deve priorizar serviços gerenciados *serverless* / *PaaS* com custo inicial zero ou muito baixo, escalando sob demanda sem necessidade de gestão dedicada de servidores Linux no estágio de MVP.

---

## 4. Framework de Security and Privacy by Design (SPbD)

O **Before I Buy** lida com desejos de consumo, vulnerabilidade emocional e valores financeiros. A confiança do usuário é o ativo central. A arquitetura e o código devem seguir formalmente os 7 princípios de *Privacy by Design* e a LGPD (Lei 13.709/2018).

### 4.1. Os 7 Princípios de Privacy by Design Aplicados

1. **Proativo, não Reativo (Preventivo):**
   - Políticas de banco *Deny-by-default* via Row Level Security (RLS).
   - Sanitização de URLs de produtos para remover tokens de rastreamento/sessão antes da persistência.
   - Detecção proativa e bloqueio de uploads que contenham metadados EXIF com geolocalização.

2. **Privacidade como Configuração Padrão (Privacy as Default):**
   - Todos os dilemas nascem como `unlisted/private`. Não existe feed público, listagem global ou busca de usuários.
   - Links de convite usam prévia social neutra (OpenGraph genérico), sem expor nome do item, valor, foto ou autor.
   - Resultados de votos ficam ocultos até que o convidado registre seu voto (elimina viés de conformidade e exposição indevida).

3. **Privacidade Incorporada ao Design (Embedded into Design):**
   - **Isolamento de Tokens de Convite:** O banco armazena exclusivamente o hash SHA-256 do token (128 bits de entropia), impedindo vazamento por SQL injection ou inspeção de logs.
   - **Sessão Efêmera de Convidado:** O convidado recebe um escopo restrito a apenas 1 dilema, sem acesso a dados de outros dilemas do criador.
   - **Auto-previsão Privada:** A resposta do criador sobre sua própria expectativa nunca é enviada aos clientes dos votantes (filtrada na camada de API/RLS).

4. **Funcionalidade Total (Soma-Positiva, não Soma-Zero):**
   - Convidados podem votar sem criar conta ou fornecer dados pessoais.
   - A coleta de e-mail/push para o *Reveal* é um opt-in separado de 1 clique, sem consentimento embutido para marketing ou envio de spam.

5. **Segurança de Ponta a Ponta (Ciclo de Vida Completo):**
   - **Em trânsito:** TLS 1.3 obrigatório para todas as conexões web, mobile e webhooks.
   - **Em repouso:** Criptografia AES-256 no banco e storage de imagens.
   - **Rascunho Offline Local:** Dados no dispositivo armazenados em storage seguro criptografado do sistema operacional (Keychain / Keystore).
   - **Exclusão em Cascata:** Exclusão de conta ou dilema remove registros e mídias físicas no storage em até 48 horas.

6. **Visibilidade e Transparência (Aberto e Auditável):**
   - Termos e Política de Privacidade em linguagem direta e humana (sem jargões jurídicos opacos).
   - O criador visualiza exatamente o que os convidados verão antes de clicar em compartilhar.

7. **Respeito pela Privacidade do Usuário (Centrado no Titular):**
   - Portabilidade e exportação de histórico de decisões em formato legível (JSON/PDF).
   - Revogação imediata de link de convite em 1 toque.
   - Filtro de idade estrito (+18) com auto-declaração no onboarding, em conformidade com as diretrizes da ANPD para proteção de menores.

---

### 4.2. Matriz de Retenção e Ciclo de Vida dos Dados (LGPD)

| Dado / Recurso | Retenção Ativa | Ação pós-Exclusão de Conta / Dilema | Justificativa |
|---|---|---|---|
| **Dilema, Razão e Mídias** | Enquanto o criador mantiver ativo | *Hard delete* imediato da tabela e exclusão física da mídia no Storage em $\le 48$h (backups expiram em $\le 35$ dias) | Finalidade do produto encerrada. |
| **Votos e Justificativas de Amigos** | Enquanto o dilema existir | Anonimização irreversível ou deleção em cascata | Mantém integridade estatística sem identificar indivíduos. |
| **Hash de Tokens de Convite** | Enquanto o link estiver ativo | Deleção imediata na revogação ou exclusão | Impede reutilização ou exploração de tokens obsoletos. |
| **E-mail/Push de Convidado (Reveal)** | Até o disparo do *Reveal* | Deleção automática após entrega + 30 dias de tolerância | Consentimento restrito ao evento específico. |
| **Rascunhos Offline** | Localmente no dispositivo | Excluídos ao desinstalar o app ou limpar rascunho | Controle total nas mãos do titular. |
| **Logs de Aplicação / Métricas** | 30 dias (logs) / 13 meses (analytics) | Métricas agregadas e pseudonimizadas sem IDs pessoais | Diagnóstico de engenharia e melhoria contínua. |

---

### 4.3. Modelo de Ameaças e Vetores de Abuso (Threat Modeling)

| Vetor de Ameaça | Impacto | Controles Preventivos e Reativos |
|---|---|---|
| **Vazamento de link por reencaminhamento** | Terceiros não autorizados acessam o dilema | Alerta claro ao criador no momento do envio; botão de revogação de link em 1 toque que invalida o token para todos imediatamente. |
| **Scraping / Enumeração de Dilemas** | Indexação em massa de desejos e preços | Tokens criptográficos com 128 bits de entropia; Rate limiting rigoroso por IP na rota de convite; bloqueio de bots (robots.txt noindex). |
| **Manipulação de Votos por Bots** | Distorção maliciosa do resultado | Validação de sessão de convidado, fingerprinting leve não invasivo, rate limit de 1 voto por sessão/IP por dilema. |
| **Texto Abusivo / Assédio em Justificativas** | Danos psicológicos ao criador | Botão de denúncia acessível; capacidade do criador de ocultar comentários específicos e bloquear votantes. |
| **Exposição Acidental de Dados em Screenshots** | Fotos de produtos contendo dados bancários/endereço | Alerta visual no componente de upload de mídia orientando a não incluir dados confidenciais ou rostos. |

---

## 5. Matriz de Rastreabilidade e Decisões de Arquitetura

| Requisito Chave | Desafio Técnico | Impacto Arquitetural Direto |
|---|---|---|
| **RF-02 / RNF-01.2** (Voto rápido sem app) | Votação instantânea com bundle levíssimo | Exige frontend Web dedicado em SSR/Static (ex: Next.js / Astro / Remix), descartando Flutter Web para a rota de convidados. |
| **RF-07 / RNF-03.3** (Rascunho offline confiável) | App móvel nativo com persistência local | Exige stack mobile multiplataforma madura (Flutter) com banco SQLite/Hive local. |
| **RF-08 / RNF-02.2 / SPbD** (Convites seguros com hash) | Proteção contra enumeração e vazamentos | Exige geração de tokens criptográficos + Edge Functions / Stored Procedures com SHA-256. |
| **RF-16 / RNF-03.1** (Reflexão em 7d / 30d) | Execução temporal distante e garantida | Exige arquitetura orientada a eventos ou cron engine confiável (pg_cron / Supabase Edge Jobs / QStash). |
| **RNF-02.1 / RNF-02.4 / SPbD** (RLS e LGPD) | Segurança rigorosa de dados relacionais | Exige banco de dados PostgreSQL com Row Level Security e triggers de deleção em cascata. |

---
