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
