begin;

select plan(40);

insert into auth.users (id) values
  ('00000000-0000-4000-8000-000000000601'),
  ('00000000-0000-4000-8000-000000000602');

insert into public.profiles (
  id, display_name, is_adult_confirmed,
  terms_accepted_version, privacy_accepted_version
) values
  ('00000000-0000-4000-8000-000000000601', 'Analytics owner', true,
   'internal-demo-v1', 'internal-demo-v1'),
  ('00000000-0000-4000-8000-000000000602', 'Other owner', true,
   'internal-demo-v1', 'internal-demo-v1');

select has_table('private', 'e1_analytics_events', 'private event store exists');
select is(
  (select relrowsecurity from pg_class
    where oid = 'private.e1_analytics_events'::regclass),
  true,
  'event store has RLS enabled'
);
select is(has_schema_privilege('anon', 'private', 'usage'), false,
  'anon cannot use private schema');
select is(has_schema_privilege('authenticated', 'private', 'usage'), false,
  'authenticated cannot use private schema');
select is(has_schema_privilege('service_role', 'private', 'usage'), false,
  'service role cannot use private schema');
select is(has_table_privilege('anon', 'private.e1_analytics_events', 'select'), false,
  'anon cannot read analytics');
select is(has_table_privilege('authenticated', 'private.e1_analytics_events', 'select'), false,
  'authenticated cannot read analytics');
select is(has_table_privilege('service_role', 'private.e1_analytics_events', 'select'), false,
  'service role cannot read analytics');
select is(
  (select count(*) from information_schema.role_table_grants
    where table_schema = 'private' and table_name = 'e1_analytics_events'
      and grantee = 'PUBLIC'), 0::bigint,
  'PUBLIC has no event-store privilege'
);
select is(has_table_privilege('anon', 'private.e1_analytics_events', 'insert,update,delete'), false,
  'anon cannot mutate analytics');
select is(has_table_privilege('authenticated', 'private.e1_analytics_events', 'insert,update,delete'), false,
  'authenticated cannot mutate analytics');
select is(has_table_privilege('service_role', 'private.e1_analytics_events', 'insert,update,delete'), false,
  'service role cannot mutate analytics');
select is(
  has_function_privilege('authenticated',
    'private.record_e1_analytics_event(text,text,timestamptz,text,text,text,text,item_category,purchase_purpose,character varying,bigint,integer,vote_prediction)',
    'execute'), false,
  'authenticated cannot execute the internal recorder'
);
select is(
  has_function_privilege('authenticated',
    'public.record_creator_analytics_event(text,uuid,uuid,uuid,timestamptz)',
    'execute'),
  true,
  'authenticated creator can call the narrow event RPC'
);
select is(
  has_function_privilege('anon',
    'public.record_creator_analytics_event(text,uuid,uuid,uuid,timestamptz)',
    'execute'),
  false,
  'anon cannot call creator analytics RPC'
);
select is(
  has_function_privilege('service_role',
    'public.record_creator_analytics_event(text,uuid,uuid,uuid,timestamptz)',
    'execute'),
  false,
  'service role cannot call creator analytics RPC'
);
select is(
  (select count(*) from information_schema.columns
    where table_schema = 'private' and table_name = 'e1_analytics_events'
      and data_type = 'jsonb'),
  0::bigint,
  'event store has no arbitrary JSON payload'
);
select is(
  (select count(*) from information_schema.columns
    where table_schema = 'private' and table_name = 'e1_analytics_events'
      and column_name in (
        'item_name', 'reason', 'price_cents', 'invite_token', 'url',
        'display_name', 'email'
      )),
  0::bigint,
  'sensitive product and identity columns do not exist'
);
select matches(
  (select pg_get_constraintdef(oid) from pg_constraint
    where conname = 'e1_analytics_event_name_check'),
  '.*dilemma_deleted.*',
  'event allowlist constraint includes the final approved event'
);
select throws_ok(
  $$ select private.record_e1_analytics_event(
    'not_allowed', 'bad', clock_timestamp()
  ) $$,
  'P0001', 'Analytics event is not allowlisted.',
  'internal recorder rejects events outside the exact allowlist'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub', '00000000-0000-4000-8000-000000000601', true
);

select lives_ok(
  $$ select public.record_creator_analytics_event(
    'dilemma_create_started',
    '61000000-0000-4000-8000-000000000601',
    '62000000-0000-4000-8000-000000000601', null, clock_timestamp()
  ) $$,
  'creator records an allowlisted local event'
);
select lives_ok(
  $$ select public.record_creator_analytics_event(
    'dilemma_create_started',
    '61000000-0000-4000-8000-000000000601',
    '62000000-0000-4000-8000-000000000601', null, clock_timestamp()
  ) $$,
  'retrying the same local event is idempotent'
);
reset role;

select is(
  (select count(*) from private.e1_analytics_events
    where event_name = 'dilemma_create_started'),
  1::bigint,
  'duplicate client event produces one row'
);
select matches(
  (select subject_key from private.e1_analytics_events
    where event_name = 'dilemma_create_started'),
  '^[0-9a-f]{64}$',
  'creator identity is pseudonymized'
);
select isnt(
  (select subject_key from private.e1_analytics_events
    where event_name = 'dilemma_create_started'),
  '00000000-0000-4000-8000-000000000601',
  'raw creator ID is not persisted'
);

insert into public.dilemmas (
  id, owner_id, item_name, price_cents, currency, category, purpose, reason,
  pause_duration_hours, pause_due_at, state, invite_token_hash,
  client_idempotency_key
) values (
  '63000000-0000-4000-8000-000000000601',
  '00000000-0000-4000-8000-000000000601',
  'Sensitive item', 987654, 'BRL', 'other', 'for_self',
  'Sensitive reason that must never enter analytics.', 24,
  clock_timestamp() + interval '1 day', 'collecting_votes',
  encode(extensions.digest('analytics-invite', 'sha256'), 'hex'),
  '62000000-0000-4000-8000-000000000601'
);

select is(
  (select count(*) from private.e1_analytics_events
    where event_name = 'dilemma_published'),
  1::bigint,
  'dilemma insert atomically emits publication event'
);
select is(
  (select price_band from private.e1_analytics_events
    where event_name = 'dilemma_published'),
  '2000_plus',
  'exact price is reduced to a coarse server-side band'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub', '00000000-0000-4000-8000-000000000602', true
);
select throws_ok(
  $$ select public.record_creator_analytics_event(
    'dilemma_share_invoked',
    '61000000-0000-4000-8000-000000000604', null,
    '63000000-0000-4000-8000-000000000601', clock_timestamp()
  ) $$,
  'P0002', 'Dilemma not found or unauthorized.',
  'another creator cannot record share for an alien dilemma'
);
reset role;

set local role authenticated;
select set_config(
  'request.jwt.claim.sub', '00000000-0000-4000-8000-000000000601', true
);
select lives_ok(
  $$ select public.record_creator_analytics_event(
    'dilemma_share_invoked',
    '61000000-0000-4000-8000-000000000602', null,
    '63000000-0000-4000-8000-000000000601', clock_timestamp()
  ) $$,
  'owner records share invocation for own dilemma'
);
select throws_ok(
  $$ select public.record_creator_analytics_event(
    'vote_submitted',
    '61000000-0000-4000-8000-000000000603', null,
    '63000000-0000-4000-8000-000000000601', clock_timestamp()
  ) $$,
  'P0001', 'Event is not accepted from the creator client.',
  'creator cannot forge a server-owned vote event'
);
reset role;

insert into public.guest_access_sessions (
  id, dilemma_id, session_secret_hash, expires_at
) values (
  '64000000-0000-4000-8000-000000000601',
  '63000000-0000-4000-8000-000000000601',
  encode(extensions.digest('analytics-session', 'sha256'), 'hex'),
  clock_timestamp() + interval '1 day'
);
select is(
  (select count(*) from private.e1_analytics_events
    where event_name = 'invite_opened'),
  1::bigint,
  'new guest session emits one invite-opened event'
);

insert into public.participations (
  id, dilemma_id, guest_session_id, display_name
) values (
  '65000000-0000-4000-8000-000000000601',
  '63000000-0000-4000-8000-000000000601',
  '64000000-0000-4000-8000-000000000601', null
);
insert into public.votes (id, participation_id, prediction)
values (
  '66000000-0000-4000-8000-000000000601',
  '65000000-0000-4000-8000-000000000601', 'buy'
);
update public.votes set prediction = 'buy'
where id = '66000000-0000-4000-8000-000000000601';
update public.votes set prediction = 'wait'
where id = '66000000-0000-4000-8000-000000000601';

select is(
  (select count(*) from private.e1_analytics_events
    where event_name = 'vote_submitted'),
  1::bigint,
  'first vote emits one submission event'
);
select is(
  (select count(*) from private.e1_analytics_events
    where event_name = 'vote_changed'),
  1::bigint,
  'only an actual prediction change emits vote-changed'
);
select is(
  (select prediction::text from private.e1_analytics_events
    where event_name = 'vote_changed'),
  'wait',
  'vote event stores only the allowlisted enum'
);

update public.dilemmas set is_invite_revoked = true
where id = '63000000-0000-4000-8000-000000000601';
select is(
  (select count(*) from private.e1_analytics_events
    where event_name = 'invite_link_revoked'),
  1::bigint,
  'revocation emits one event'
);

delete from public.dilemmas
where id = '63000000-0000-4000-8000-000000000601';
select is(
  (select count(*) from private.e1_analytics_events
    where event_name = 'dilemma_deleted'),
  1::bigint,
  'hard deletion preserves a pseudonymous deletion event'
);

select is(
  (select count(*) from cron.job
    where jobname = 'purge-e1-analytics-events'
      and schedule = '17 3 * * *' and active),
  1::bigint,
  'one active daily retention job exists'
);

insert into private.e1_analytics_events (
  event_name, deduplication_key, occurred_at, recorded_at
) values (
  'dilemma_draft_saved', repeat('a', 64),
  clock_timestamp() - interval '14 months',
  clock_timestamp() - interval '14 months'
);
select is(
  private.purge_expired_e1_analytics_events(),
  1,
  'retention removes only events older than thirteen months'
);
select is(
  (select count(*) from private.e1_delivery_dashboard),
  1::bigint,
  'administrative delivery dashboard is queryable'
);
select ok(
  (select vote_conversion_percent is not null
      and liquidity_percent is not null
      and creator_activation_7d_percent is not null
      and revoked_or_deleted_within_10m = 1
    from private.e1_delivery_dashboard),
  'dashboard exposes conversion, liquidity, activation and early removal guardrail'
);

select * from finish();
rollback;
