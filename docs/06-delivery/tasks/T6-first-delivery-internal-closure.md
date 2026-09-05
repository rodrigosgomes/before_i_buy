# Task 6 — fechamento interno da Entrega 1

**Status:** em implementação
**Tipo:** analytics, staging, validação integral e fechamento de entrega
**Entrega relacionada:** [Entrega 1](../../01-product/first-delivery-mini-prd.md)
**Depende de:** Tasks 0–5 implementadas

## Resultado

Concluir internamente o fluxo `rascunho offline → revisão → publicação privada
→ compartilhamento → voto sem conta → agregados → revogação/exclusão →
expiração`, com analytics interno limitado aos onze eventos permitidos pelo
mini-PRD, staging HTTPS controlado, CI verde e evidência de usabilidade interna.

O staging e o teste 3+3 usam somente equipe ou testadores internos autorizados,
dados fictícios e distribuição controlada dos links. Não validam a hipótese de
mercado, conversão ou liquidez e não autorizam beta externo.

## Critérios de aceite

1. Os onze eventos permitidos são versionados, tipados, pseudonimizados e não
   contêm item, motivo, preço exato, token, URL, nome ou e-mail.
2. Eventos ligados a publicação, convite, voto, revogação e exclusão são
   atômicos com a mutação; retries idempotentes não duplicam métricas.
3. Eventos locais toleram offline, reinício e falha do backend sem bloquear o
   fluxo de produto.
4. Tabela, funções, views e cron de analytics não são acessíveis aos papéis de
   aplicação, salvo a RPC estreita de escrita do próprio criador.
5. Views administrativas calculam funil, conversão, liquidez e medianas sem
   expor dados pessoais ou conteúdo do dilema.
6. O staging serve a página sob
   `https://myelolabs.com.br/eloease/guest-invite`, mantém o proxy same-origin
   nas rotas raiz e não apresenta desafio anti-bot no fluxo controlado.
7. Smoke remoto cobre origem, cookie, rate limit, resposta genérica, revogação
   e expiração.
8. Três criadores e três convidados internos completam o teste com dados
   fictícios; medianas ficam abaixo de dois minutos e vinte segundos.
9. Revisões de Produto, Segurança/Privacidade e QA não possuem P0/P1/P2 aberto;
   todos os gates locais e remotos ficam verdes.

## Plano técnico e testes

- Migration aditiva cria a store privada, HMAC no Vault, triggers transacionais,
  RPC autenticada, views administrativas e retenção de treze meses.
- Mobile usa fila local por usuário com payload fechado e envio best-effort.
- Web usa `basePath=/eloease/guest-invite`; Cloudflare roteia página/assets e
  os endpoints raiz sem alterar o `Path` do cookie.
- pgTAP cobre allowlist exata, grants, redaction estrutural, HMAC, idempotência,
  atomicidade, views e retenção.
- Testes mobile cobrem fila offline, retry, isolamento de conta e falha sem
  impacto no produto. Edge/Web e E2E cobrem emissão e ausência de vazamento.
- O relatório final liga cada critério do mini-PRD à evidência automatizada,
  manual ou à pendência explícita de beta.

## Operação e rollback

Publicar na ordem: migration → Edge → Cloudflare → build mobile interno → smoke
→ teste 3+3. Em rollback, retirar as rotas de staging, restaurar a Edge anterior
e interromper emissores; migrations e eventos já persistidos não são revertidos.

Eventos ficam retidos por treze meses. Operação acompanha último purge, volume,
idade do evento mais antigo e falhas consecutivas. Acesso ao dashboard permanece
administrativo.

## Revisão de Produto pré-implementação

- Corrigida a inconsistência do plano: o mini-PRD permite exatamente onze
  eventos, não dez.
- Staging e teste 3+3 foram limitados a participantes internos autorizados e
  dados fictícios para respeitar a DEC-015.
- A amostra mede aceite técnico e usabilidade interna; não comprova a hipótese
  E1 nem libera beta.
