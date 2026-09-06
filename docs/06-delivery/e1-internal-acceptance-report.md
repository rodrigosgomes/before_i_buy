# Relatório de aceite — Entrega 1 interna

**Versão avaliada:** branch `task/e1-internal-closure`  
**Estado:** aceite em andamento; deploy, CI da branch e sessão humana 3+3 pendentes  
**Ambiente:** desenvolvimento local e staging HTTPS controlado

Este relatório comprova a entrega técnica interna. Ele não autoriza beta
externo, recrutamento público, lojas ou uso de documentos jurídicos internos
como documentos definitivos.

## Matriz do mini-PRD

| Critério | Implementação | Teste ou evidência | Estado |
|---|---|---|---|
| Rascunho local, recuperação e revisão explícita | Tasks 3A/3B; repositório local e fluxo mobile | `app_flow_test.dart`, `local_repositories_test.dart`, `publication_resilience_test.dart` | automatizado verde |
| Publicação privada idempotente | RPC `publish_dilemma` e gateway mobile | pgTAP `030`; integração `creator_supabase_test.dart` | automatizado verde |
| Convite privado e não listado | Hash SHA-256, sessão opaca e página sem indexação | pgTAP `010/020`; Edge contract/runtime; Web E2E | automatizado verde |
| Voto sem conta e troca do voto | Edge, sessão restrita e RPC atômica | pgTAP `020`; concorrência; Edge runtime; Web E2E | automatizado verde |
| Agregados somente depois do voto | Contratos separados de abertura e submissão | pgTAP `020`; Web unitário/E2E; integração mobile–Supabase | automatizado verde |
| Gestão privada, revogação e exclusão | RPCs do criador e dashboard mobile | pgTAP `040`; testes mobile; integração mobile–Supabase | automatizado verde |
| Expiração para `decision_due` | `private.expire_due_dilemmas()` e cron por minuto | pgTAP `050`; concorrência; execução real do cron | automatizado verde |
| Mobile em `decision_due` | Dashboard encerra voto e oculta compartilhar/revogar | `dilemma_dashboard_test.dart`; `app_flow_test.dart` | automatizado verde |
| Analytics com onze eventos e sem conteúdo sensível | Store privada, HMAC, triggers, RPC estreita e fila local | pgTAP `060`; testes `creator_analytics_test.dart` | automatizado verde |
| Retenção e dashboard administrativo | Purge diário de 13 meses e views privadas | pgTAP `060`; consultas operacionais abaixo | automatizado verde |
| Web acessível no fluxo crítico | Componentes semânticos e layout responsivo | testes Web e verificações mobile a 320 px/200%; checklist manual abaixo | manual no staging pendente |
| Mediana de criação menor que 2 minutos | Instrumentação + protocolo controlado | sessão com 3 criadores | pendente |
| Mediana de voto menor que 20 segundos | Instrumentação + protocolo controlado | sessão com 3 convidados | pendente |
| Staging HTTPS sem desafio no fluxo | Dois Workers: site com `basePath` e proxy raiz | build OpenNext e dry-run Wrangler | deploy e smoke pendentes |
| CI e proteção da `main` | workflow `Quality gates` e regras do GitHub | execução da PR e consulta da proteção | pendente |

## Evidências locais da versão

- banco reconstruído desde zero; 12 migrations aplicadas;
- pgTAP: 221 testes aprovados;
- concorrência: 8 cenários aprovados;
- cron real: expiração e preservação do voto aprovadas em 38 segundos;
- Edge: contrato com 95,53% de linhas e runtime smoke aprovados;
- mobile: 98 testes aprovados, 1 integração separada aprovada e 95,30% de
  cobertura de linhas;
- web: 11 testes aprovados, 94,30% de linhas, E2E crítico com 2 cenários
  aprovado, build OpenNext e bundles Wrangler aprovados em dry-run.

Os resultados finais devem registrar URL da execução de CI, SHA do merge,
versões remotas e tempos anonimizados da sessão 3+3.

## Operação de analytics

As consultas são executadas somente pelo papel administrativo no SQL Editor ou
por conexão administrativa. Não devem ser expostas por API.

```sql
select * from private.e1_delivery_dashboard;
select * from private.e1_event_funnel_daily order by event_date desc, event_name;
select * from private.e1_usability_daily order by event_date desc;

select count(*) as retained_events,
       min(recorded_at) as oldest_retained_event,
       max(recorded_at) as newest_retained_event
  from private.e1_analytics_events;

select status, count(*) as runs, max(end_time) as latest_end
  from cron.job_run_details
 where jobid = (select jobid from cron.job
                 where jobname = 'purge-e1-analytics-events')
 group by status;
```

Investigar falhas consecutivas do purge ou execução atrasada por mais de 24
horas. Para a expiração dos dilemas, investigar falhas consecutivas ou atraso
superior a cinco minutos conforme a Task 5.

## Bloqueios externos preservados

Continuam pendentes documentos jurídicos aprovados, bases legais, retenção de
backups, exclusão de conta, processo de incidentes, promoção do OAuth, Apple
Sign-In quando aplicável e autorização formal de beta.
