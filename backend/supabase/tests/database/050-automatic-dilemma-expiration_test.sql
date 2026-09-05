begin;

select plan(24);

insert into auth.users (id)
values ('00000000-0000-4000-8000-000000000501');

insert into public.profiles (
  id, display_name, is_adult_confirmed,
  terms_accepted_version, privacy_accepted_version
) values (
  '00000000-0000-4000-8000-000000000501',
  'Expiration owner', true, 'internal-demo-v1', 'internal-demo-v1'
);

select ok(
  to_regprocedure('private.expire_due_dilemmas()') is not null,
  'the internal expiration function exists'
);

select is(
  (select prosecdef from pg_proc
    where oid = 'private.expire_due_dilemmas()'::regprocedure),
  false,
  'expiration uses the privileges of its administrative caller'
);

select is(
  (select pg_get_userbyid(proowner) from pg_proc
    where oid = 'private.expire_due_dilemmas()'::regprocedure),
  'postgres',
  'postgres owns the expiration function'
);

select is(
  has_function_privilege('anon', 'private.expire_due_dilemmas()', 'execute'),
  false,
  'anon cannot execute expiration'
);

select is(
  has_function_privilege(
    'authenticated', 'private.expire_due_dilemmas()', 'execute'
  ),
  false,
  'authenticated cannot execute expiration'
);

select is(
  has_function_privilege(
    'service_role', 'private.expire_due_dilemmas()', 'execute'
  ),
  false,
  'service_role cannot execute expiration'
);

select is(
  has_schema_privilege('anon', 'cron', 'usage'),
  false,
  'anon cannot administer cron objects'
);

select is(
  has_schema_privilege('authenticated', 'cron', 'usage'),
  false,
  'authenticated cannot administer cron objects'
);

select is(
  has_schema_privilege('service_role', 'cron', 'usage'),
  false,
  'service_role cannot administer cron objects'
);

select results_eq(
  $$
    select count(*)::bigint
      from cron.job
     where jobname = 'expire-due-dilemmas'
  $$,
  array[1::bigint],
  'exactly one named expiration job exists'
);

select results_eq(
  $$
    select schedule
      from cron.job
     where jobname = 'expire-due-dilemmas'
  $$,
  array['* * * * *'::text],
  'the expiration job runs every minute'
);

select results_eq(
  $$
    select command
      from cron.job
     where jobname = 'expire-due-dilemmas'
  $$,
  array['select private.expire_due_dilemmas();'::text],
  'the job invokes only the internal expiration function'
);

insert into public.dilemmas (
  id, owner_id, item_name, price_cents, currency, category, purpose,
  reason, pause_duration_hours, pause_due_at, state, invite_token_hash,
  is_invite_revoked
) values
  (
    '10000000-0000-4000-8000-000000000501',
    '00000000-0000-4000-8000-000000000501',
    'Due item', 10000, 'BRL', 'other', 'for_self',
    'Motivo valido para dilema vencido.', 24,
    clock_timestamp() - interval '1 minute', 'collecting_votes',
    encode(extensions.digest('due-item', 'sha256'), 'hex'), false
  ),
  (
    '10000000-0000-4000-8000-000000000502',
    '00000000-0000-4000-8000-000000000501',
    'Future item', 11000, 'BRL', 'other', 'for_self',
    'Motivo valido para dilema futuro.', 24,
    clock_timestamp() + interval '1 hour', 'collecting_votes',
    encode(extensions.digest('future-item', 'sha256'), 'hex'), false
  ),
  (
    '10000000-0000-4000-8000-000000000503',
    '00000000-0000-4000-8000-000000000501',
    'Already due item', 12000, 'BRL', 'other', 'for_self',
    'Motivo valido para outro estado.', 24,
    clock_timestamp() - interval '1 hour', 'decision_due',
    encode(extensions.digest('already-due-item', 'sha256'), 'hex'), false
  ),
  (
    '10000000-0000-4000-8000-000000000504',
    '00000000-0000-4000-8000-000000000501',
    'Revoked due item', 13000, 'BRL', 'other', 'for_self',
    'Motivo valido para convite revogado.', 24,
    clock_timestamp() - interval '1 minute', 'collecting_votes',
    encode(extensions.digest('revoked-due-item', 'sha256'), 'hex'), true
  ),
  (
    '10000000-0000-4000-8000-000000000505',
    '00000000-0000-4000-8000-000000000501',
    'Cutoff item', 14000, 'BRL', 'other', 'for_self',
    'Motivo valido para limite inclusivo.', 24,
    statement_timestamp(), 'collecting_votes',
    encode(extensions.digest('cutoff-item', 'sha256'), 'hex'), false
  );

insert into public.participations (
  id, dilemma_id, user_id, display_name
) values (
  '20000000-0000-4000-8000-000000000501',
  '10000000-0000-4000-8000-000000000501',
  '00000000-0000-4000-8000-000000000501',
  'Convidado'
);

insert into public.votes (id, participation_id, prediction)
values (
  '40000000-0000-4000-8000-000000000501',
  '20000000-0000-4000-8000-000000000501',
  'buy'
);

create temporary table expected_expiration_values as
select pause_due_at
  from public.dilemmas
 where id = '10000000-0000-4000-8000-000000000501';

select is(
  private.expire_due_dilemmas(),
  3,
  'due, cutoff, and revoked due dilemmas expire'
);

select results_eq(
  $$
    select id
      from public.dilemmas
     where state = 'decision_due'
       and id in (
         '10000000-0000-4000-8000-000000000501',
         '10000000-0000-4000-8000-000000000504',
         '10000000-0000-4000-8000-000000000505'
       )
     order by id
  $$,
  $$ values
    ('10000000-0000-4000-8000-000000000501'::uuid),
    ('10000000-0000-4000-8000-000000000504'::uuid),
    ('10000000-0000-4000-8000-000000000505'::uuid)
  $$,
  'all eligible state transitions are persisted'
);

select is(
  (select state::text from public.dilemmas
    where id = '10000000-0000-4000-8000-000000000502'),
  'collecting_votes',
  'future dilemma remains collecting votes'
);

select is(
  (select state::text from public.dilemmas
    where id = '10000000-0000-4000-8000-000000000503'),
  'decision_due',
  'a dilemma in another state remains unchanged'
);

select is(
  (select pause_due_at from public.dilemmas
    where id = '10000000-0000-4000-8000-000000000501'),
  (select pause_due_at from expected_expiration_values),
  'expiration preserves the original deadline'
);

select is(
  (select is_invite_revoked from public.dilemmas
    where id = '10000000-0000-4000-8000-000000000504'),
  true,
  'expiration preserves invite revocation'
);

select is(
  (select count(*)::integer from public.participations
    where dilemma_id = '10000000-0000-4000-8000-000000000501'),
  1,
  'expiration preserves participations'
);

select is(
  (select count(*)::integer
     from public.votes v
     join public.participations p on p.id = v.participation_id
    where p.dilemma_id = '10000000-0000-4000-8000-000000000501'
      and v.prediction = 'buy'),
  1,
  'expiration preserves raw votes'
);

insert into public.dilemmas (
  owner_id, item_name, price_cents, currency, category, purpose,
  reason, pause_duration_hours, pause_due_at, state, invite_token_hash
)
select
  '00000000-0000-4000-8000-000000000501',
  'Batch item ' || series, 15000, 'BRL', 'other', 'for_self',
  'Motivo valido para testar o limite do lote.', 24,
  clock_timestamp() - interval '2 hours', 'collecting_votes',
  encode(extensions.digest('batch-item-' || series, 'sha256'), 'hex')
from generate_series(1, 1001) series;

select is(
  private.expire_due_dilemmas(),
  1000,
  'one execution expires at most one thousand dilemmas'
);

select is(
  (select count(*)::integer
     from public.dilemmas
    where item_name like 'Batch item %'
      and state = 'collecting_votes'),
  1,
  'one eligible dilemma remains for the next batch'
);

select is(
  private.expire_due_dilemmas(),
  1,
  'the next execution resumes the remaining batch'
);

select is(
  private.expire_due_dilemmas(),
  0,
  'a repeated execution is idempotent'
);

select * from finish();
rollback;
