# Before I Buy — instruções para agentes

## Fonte de verdade e prioridades

1. Leia [o mini-PRD da primeira entrega](docs/01-product/first-delivery-mini-prd.md) antes de propor ou alterar comportamento do MVP.
2. Em caso de conflito, siga o [Decision Log](docs/06-delivery/DECISION_LOG.md) e registre uma decisão nova em vez de inventar uma regra.
3. Preserve o loop fechado e a privacidade: dilemas privados e não listados, publicação explícita, nenhum agregado antes do voto e nenhuma IA como funcionalidade do MVP.
4. Para diretrizes especializadas, use as skills em `.agents/skills/`. O mapa de responsabilidades está em `.agents/AGENTS.md`.

## Fluxo obrigatório

Para qualquer mudança de produto ou código, siga:

`task → plano técnico → testes planejados → implementação → revisão adversarial → CI verde → merge`

Use os templates, a [Definition of Done](docs/06-delivery/definition-of-done.md) e o [processo de qualidade](docs/06-delivery/quality-process.md). Não enfraqueça cobertura, RLS ou E2E para tornar um check verde.

## Coordenação de subagentes

Os agentes em `.codex/agents/` são revisores de evidência, não implementadores. Use-os apenas quando o trabalho for independente e o risco justificar o custo:

- `product_reviewer`: antes da implementação quando escopo, estados do dilema, métricas ou experiência do loop forem alterados;
- `security_privacy_reviewer`: antes do merge quando houver schema, RLS, autenticação, tokens de convite, dados pessoais, links ou analytics;
- `qa_reviewer`: antes do merge quando houver comportamento de usuário, persistência, sincronização ou fluxo crítico.

Para uma revisão com mais de um papel aplicável, delegue em paralelo, aguarde todos os resultados e consolide apenas achados verificáveis com referência a arquivo, requisito ou cenário. Não delegue escrita de código em paralelo e não acione revisores para alterações triviais de documentação.

Subagentes não recebem autorização para operações externas, deploy, publicação, login, `supabase link`, `supabase db push --linked` ou mudanças destrutivas. Essas ações continuam exigindo pedido explícito do usuário.
