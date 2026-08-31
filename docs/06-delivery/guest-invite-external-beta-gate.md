# Gate de beta externo — limite de taxa de convite

**Status:** bloqueador de liberação; não implementado na Task 0.

A Edge Function `guest-invite` não pode ser exposta para beta externo antes de
um limitador efêmero ser configurado e testado. A fundação atual não coleta IP,
device fingerprint, contato ou identificador persistente de convidado.

## Integração exigida antes do beta

1. Na Edge Function, derivar uma chave de limite com HMAC e um segredo do
   ambiente a partir do token de convite. Nunca persistir nem registrar o token
   em texto claro.
2. Consultar um contador com TTL no provedor de limite escolhido antes de abrir
   a sessão. O TTL nunca pode ultrapassar `pause_due_at`.
3. Aplicar também um limite curto para tentativas que já tenham uma sessão
   válida, usando uma chave derivada do segredo opaco da sessão.
4. Em bloqueio, devolver a mesma resposta genérica, os mesmos headers de
   privacidade e nenhum cookie; não transformar IP em identidade de produto.
5. Liberar o domínio web somente depois de configurar uma origem explícita para
   requisições com credenciais. Não aceitar `Access-Control-Allow-Origin: *`
   junto de cookies em produção.

## Evidência necessária para liberar

- decisão registrada sobre provedor, janelas e limiares;
- teste de limiar, expiração do contador, convite revogado e resposta `429`
  sem token, segredo ou dado do dilema;
- revisão de Segurança/LGPD confirmando que a chave é efêmera e não cria perfil
  de convidado; e
- E2E de convite → voto e link revogado da Task 1 aprovado.

Até esses itens existirem, a função permanece apenas em desenvolvimento local
e não recebe URL pública de beta.
