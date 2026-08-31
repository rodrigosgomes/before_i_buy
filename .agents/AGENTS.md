# Before I Buy — Diretrizes Globais do Time de Agentes e Skills

Este repositório contém o código-fonte do **Before I Buy**, um jogo social privado de tomada de decisão para compras discricionárias.

---

## 1. Princípios Gerais de Engenharia e Produto

1. **Simplicidade Cirúrgica (Ponytail):** O melhor código é o que não precisa ser escrito. Reutilize padrões nativos do Postgres, Flutter e Next.js antes de criar novas abstrações.
2. **Segurança e Privacidade por Padrão (SPbD):** Todas as tabelas devem ter RLS *deny-by-default*. Nunca armazene tokens em texto claro (apenas hash SHA-256). OpenGraph de convites sempre neutro (sem vazar preço/item).
3. **Loop Fechado Garantido:** O produto só tem valor se o ciclo completo funcionar: Tentação $\to$ Voto dos Amigos $\to$ Pausa $\to$ Decisão $\to$ Reflexão Tardia (7d/30d) $\to$ Revelação (Reveal).
4. **Design Emocional Playful Calm:** Interface acolhedora baseada em Material Design 3 Expressive. Proibida estética bancária fria, contadores de pânico ou elementos de culpa financeira.

---

## 2. Mapa da Tropa de Especialistas

| Skill | Especialidade | Foco Principal |
|---|---|---|
| `dba-postgres-architect` | DBA & Modelagem | Schemas, índices, triggers, migrações, performance, locks e pg_cron |
| `security-guardian` | Segurança & Criptografia | RLS deny-by-default, hash de tokens 128-bit, sanitização e isolamento de sessão |
| `privacy-lgpd` | Privacidade & LGPD | Conformidade Lei 13.709/2018, opt-in isolado, retenção e hard delete em $\le 48$h |
| `qa-test-engineer` | Qualidade & Testes | Testes automatizados negativos de RLS, E2E do loop fechado e resiliência offline |
| `product-owner` | Produto & Negócio | Requisitos funcionais, critérios de aceite e bloqueio de escopos predadores |
| `uiux-playful-calm` | Design System & UX | Material 3 Expressive, cantos 18–28px, microinterações e acessibilidade WCAG 2.1 AA |
| `devops-deploy` | CI/CD & Deploy | Pipelines GitHub Actions, automação de migrações e deploy Web/Mobile |

---

## 3. Processo de Qualidade Obrigatório

Antes de escrever código, todo agente deve vincular a mudança a uma task e registrar plano técnico, estratégia de testes e foco da revisão adversarial. O fluxo obrigatório é:

`task → plano técnico → testes planejados → implementação → revisão adversarial → CI verde → merge`

Use o [processo de qualidade](../docs/06-delivery/quality-process.md), a [Definition of Done](../docs/06-delivery/definition-of-done.md) e os templates de task/PR. Cobertura mínima é 80% por superfície alterada; RLS exige testes negativos por papel e E2E cobre o handoff crítico afetado. Nenhum agente deve enfraquecer ou ignorar um gate para obter CI verde.

---

## 4. Playbook de Engenharia para IAs

Todas as IAs que operam neste repositório devem ler e seguir as diretrizes consolidadas no [AI_PLAYBOOK.md](file:///home/rodrigo/before_i_buy/docs/AI_PLAYBOOK.md), incluindo:
- Quality Gate inegociável de $\ge 80\%$ de cobertura de testes automatizados.
- Padrão *Vertical Slice Architecture* e *Schema-First*.
- RLS *Deny-by-Default* com testes negativos de segurança.
- Ciclo de vida estrito da máquina de estados do *Closed Loop*.
