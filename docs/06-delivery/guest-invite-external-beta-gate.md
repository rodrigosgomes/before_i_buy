# Gate de beta externo — limite de taxa de convite

**Status:** limite e validação de origem implementados localmente na Task 1;
proxy same-origin, configuração no alvo e revisão de liberação ainda pendentes.

A Edge Function `guest-invite` não coleta IP, device fingerprint, contato ou
identificador persistente de convidado. A Task 1 implementa localmente o limite
definido na DEC-010; isso ainda não autoriza deploy ou beta externo.

## Integração exigida antes do beta

1. Configurar `GUEST_RATE_LIMIT_SECRET` com ao menos 32 bytes em cada ambiente;
   não reutilizar token, JWT ou chave de serviço para essa finalidade.
2. Configurar uma única `GUEST_WEB_ORIGIN` HTTPS, sem path, query ou fragmento,
   e publicar a rota por reverse proxy no mesmo domínio do cliente web,
   preservando `Set-Cookie` e `/functions/v1/guest-invite`. O navegador não
   chama diretamente o domínio Supabase.
3. Confirmar que outra origem falha antes da RPC e que o proxy não injeta CORS
   com credenciais nem amplia o `Path` do cookie.
4. Aplicar as migrations e comprovar no ambiente alvo os limiares da DEC-010,
   TTL limitado ao prazo e resposta genérica `429` sem cookie.

## Evidência necessária para liberar

- DEC-010 e testes locais de limiar, TTL, convite revogado e resposta `429`
  sem token, segredo ou dado do dilema;
- configuração e smoke equivalentes no ambiente alvo;
- revisão de Segurança/LGPD confirmando que a chave é efêmera e não cria perfil
  de convidado; e
- E2E de convite → voto e link revogado da Task 1 aprovado.

Até os itens pendentes existirem, a função permanece apenas em desenvolvimento
local e não recebe URL pública de beta.
