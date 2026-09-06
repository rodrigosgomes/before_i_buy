# Task 5 — expiração automática dos dilemas

**Status:** concluída no commit `6b0efc2`; CI verde e deploy remoto registrado
**Tipo:** máquina de estados, rotina agendada e segurança temporal
**Entrega relacionada:** [Entrega 1](../../01-product/first-delivery-mini-prd.md)
**Depende de:** [Task 4 — gestão privada de dilemas](T4-creator-dilemma-management.md)

## Resultado e contexto

Quando `pause_due_at` é alcançado, um dilema em `collecting_votes` passa para
`decision_due`. A transição encerra a coleta sem escolher uma decisão pelo
criador e preserva votos e agregados para a próxima entrega do loop fechado.

O servidor já rejeita abertura e voto após o prazo. Esta tarefa persiste o novo
estado por uma rotina de banco executada a cada minuto.

## Escopo e não-escopo

### Escopo

- transicionar até 1.000 dilemas vencidos por execução;
- processar em ordem de prazo e ID com bloqueio concorrente não bloqueante;
- avançar também dilemas cujo convite foi revogado;
- agendar um único job `expire-due-dilemmas` a cada minuto;
- provar que atraso ou indisponibilidade do job não reabre votação;
- manter a apresentação mobile existente para votação encerrada.

### Não-escopo

- decisão do criador, reflexão, Reveal, notificações ou jobs de 7/30 dias;
- analytics, feed, busca, IA ou gamificação;
- deploy remoto, beta externo, documentos jurídicos ou lojas.

## Critérios de aceite

1. Somente dilemas `collecting_votes` com `pause_due_at` menor ou igual ao
   horário de corte passam para `decision_due`.
2. Cada execução altera no máximo 1.000 linhas, em ordem de prazo e ID, e
   informa apenas a quantidade alterada.
3. Execuções repetidas ou concorrentes são idempotentes e linhas bloqueadas
   ficam disponíveis para uma execução posterior.
4. Prazo, votos, participações, agregados e revogação permanecem inalterados.
5. Papéis de aplicação não executam a função nem administram o cron.
6. Existe exatamente um job `expire-due-dilemmas`, com agenda `* * * * *`.
7. Mesmo antes de o job executar, abertura e voto após o prazo continuam
   recusados genericamente pelo servidor.
8. O mobile exibe `decision_due` como votação encerrada e oculta compartilhar
   e revogar, inclusive após atualização do painel.

## Plano técnico

1. Criar `private.expire_due_dilemmas()` como função sem parâmetros, executada
   apenas pelo proprietário administrativo. Capturar `clock_timestamp()` uma
   vez por chamada.
2. Selecionar o lote pelo índice parcial existente em `pause_due_at`, usando
   `ORDER BY pause_due_at, id`, `LIMIT 1000` e `FOR UPDATE SKIP LOCKED`.
3. Atualizar somente linhas ainda elegíveis e retornar `ROW_COUNT`. O trigger
   existente atualiza `updated_at`.
4. Instalar `pg_cron` ou falhar explicitamente quando indisponível. Usar o
   agendamento nomeado para criar ou atualizar o job sem duplicação.
5. Não alterar RPCs, payloads ou APIs do cliente.

## Estratégia de testes

- **pgTAP:** vencido, limite inclusivo, futuro, outro estado, revogado,
  preservação, lote de 1.000, segunda execução e privilégios.
- **Concorrência:** execuções simultâneas, linha bloqueada, voto, revogação e
  exclusão concorrentes sem deadlock ou reabertura.
- **Runtime local:** aguardar no máximo 120 segundos por uma execução real do
  cron e confirmar estado, dados preservados e recusas pós-prazo.
- **Mobile:** cartão e painel `decision_due`, atualização e ações ocultas.
- **Gates:** migration, pgTAP, concorrência, Edge, integração mobile/Supabase,
  análise, testes e cobertura mobile, além de `git diff --check`.

## Segurança, operação e rollback

A função fica fora do schema exposto e sem execução para `PUBLIC`, `anon`,
`authenticated` ou `service_role`. O job usa apenas SQL interno; não recebe
token, conteúdo do dilema ou dados pessoais.

Operação: consultar `cron.job_run_details`, contar dilemas vencidos ainda em
`collecting_votes` e medir a idade do atraso mais antigo. Falhas consecutivas
ou atraso acima de cinco minutos exigem investigação.

Consultas administrativas:

```sql
select status, start_time, end_time, return_message
  from cron.job_run_details
 where jobid = (
   select jobid from cron.job where jobname = 'expire-due-dilemmas'
 )
 order by start_time desc
 limit 20;

select
  count(*) as pending_count,
  clock_timestamp() - min(pause_due_at) as oldest_delay
from public.dilemmas
where state = 'collecting_votes'
  and pause_due_at <= clock_timestamp();
```

Rollback: desativar somente o job. Estados já avançados não são revertidos; as
validações de prazo nas RPCs continuam bloqueando abertura e voto.

## Foco da revisão adversarial

Produto tenta detectar decisão automática ou expansão para a Entrega 2.
Segurança tenta executar a função ou administrar o cron por papéis de aplicação.
QA força lotes, locks, repetição, atraso e concorrência com voto, revogação e
exclusão.

## Evidências de fechamento

- Migration aplicada no Supabase local; segunda execução não encontrou migration
  pendente.
- pgTAP: 6 arquivos e 188 testes aprovados.
- Concorrência: 8 cenários aprovados, incluindo duas execuções simultâneas,
  lote, linha bloqueada, voto, revogação e exclusão.
- Cron real: integração aprovada em menos de 120 segundos, com `decision_due`,
  voto preservado, agregados confirmados pela RPC autenticada e acesso pós-prazo
  recusado.
- Edge: contrato aprovado com 95,53% de linhas, 90% de branches e 94,44% de
  funções; smoke de runtime aprovado.
- Mobile: análise sem apontamentos; 93 testes aprovados e 1 teste de sistema
  separado; cobertura de linhas em 95,85%; integração Flutter/Supabase aprovada.
- Revisões adversariais de produto, segurança/privacidade e QA concluídas sem
  achados pendentes P0, P1 ou P2.
- `git diff --check` aprovado.
- CI remota: [Quality gates 33984090714](https://github.com/rodrigosgomes/before_i_buy/actions/runs/33984090714)
  aprovada no commit `6b0efc2`, incluindo contrato do repositório, banco e cron,
  mobile, guest web e E2E crítico.
- Deploy remoto no projeto de desenvolvimento `rfdutjlsskaptiukpshi` registrado
  pelo commit documental `2d87c9d`: função instalada, exatamente um job ativo
  `expire-due-dilemmas` em `* * * * *`, última execução bem-sucedida e nenhum
  dilema vencido ainda em coleta na verificação pós-deploy.
