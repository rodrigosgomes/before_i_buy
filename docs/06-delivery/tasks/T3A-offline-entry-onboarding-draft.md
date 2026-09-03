# Task 3A — entrada, onboarding e rascunho local

**Status:** em implementação interna
**Entrega relacionada:** [Entrega 1](../../01-product/first-delivery-mini-prd.md)
**Decisão:** [DEC-013](../DECISION_LOG.md#dec-013-autenticação-do-criador-por-magic-link-de-e-mail)

## Resultado e limites

Entregar, sem ambiente remoto, o fluxo
`configuração ausente → magic link → aguardando link → onboarding → home → rascunho → revisão`.
O rascunho e o onboarding permanecem locais. SMTP, configuração externa do
callback, perfil remoto, prévia E1-S04, publicação, convite, compartilhamento,
analytics e IA não pertencem a esta task.

## Subtasks e critérios

### 3A.1 — fundação visual, Auth e rotas

- Tokens Playful Calm e componentes `Bib*` são a única API visual das telas.
- Auth passa por gateway injetável; produção usa somente URL e chave pública.
- Sem configuração, nenhuma instância Supabase ou tentativa de rede é criada.
- Envio usa `beforeibuy://auth-callback` e possui estados de erro, loading,
  aguardando link, reenvio e troca de e-mail.

### 3A.2 — estado local e E1-S01 a E1-S03

- Onboarding interno persiste nome, +18 e aceites separados apenas no aparelho.
- Um rascunho versionado persiste campos e UUID de idempotência após reinício.
- Campos inválidos mantêm o conteúdo; revisar nunca publica.
- Recuperação é identificada como local e não compartilhada.

### 3A.3 — qualidade e revisão

- Unidade, widget, integração offline e goldens cobrem estados críticos.
- Mobile mantém cobertura de linhas mínima de 80%.
- Produto, Privacidade/Segurança e QA tentam introduzir publicação implícita,
  consentimento remoto, vazamento de e-mail ou perda do rascunho.
- Formatação, análise, testes, cobertura, `git diff --check` e CI ficam verdes.

## Interfaces e dados

- `AuthGateway`: sessão atual, eventos e `signInWithOtp`.
- `OnboardingRepository`: leitura e gravação do fixture interno local.
- `DraftRepository`: leitura e gravação de um único `DraftDilemma`.
- `DraftDilemma`: schema local v1, item, centavos BRL, categoria, motivo,
  finalidade, pausa e UUID de idempotência.

## Risco, rollback e revisão adversarial

Não há migration, alteração de RLS ou contrato remoto. O rollback é remover a
vertical slice mobile sem tocar no backend ou Web. Os testes devem provar que
login, callback, reabertura, reconexão e revisão não possuem caminho para a RPC
`publish_dilemma`.
