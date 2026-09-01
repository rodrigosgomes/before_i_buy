begin;

select plan(71);

create or replace function pg_temp.open_invite_as_service(
  p_token text,
  p_secret text
) returns jsonb
language plpgsql
as $$
declare
  v_result jsonb;
begin
  set local role service_role;
  select to_jsonb(s)
    into v_result
    from public.open_guest_invite_session(
      p_token,
      p_secret,
      encode(extensions.digest('open:' || p_token, 'sha256'), 'hex')
    ) s;
  reset role;
  return v_result;
exception
  when others then
    reset role;
    raise;
end;
$$;

create or replace function pg_temp.submit_vote_as_service(
  p_dilemma_id uuid,
  p_secret text,
  p_prediction public.vote_prediction
) returns jsonb
language plpgsql
as $$
declare
  v_result jsonb;
begin
  set local role service_role;
  select to_jsonb(s)
    into v_result
    from public.submit_guest_vote(
      p_dilemma_id,
      p_secret,
      p_prediction,
      encode(extensions.digest('vote:' || p_secret, 'sha256'), 'hex')
    ) s;
  reset role;
  return v_result;
exception
  when others then
    reset role;
    raise;
end;
$$;

create or replace function pg_temp.publish_as_authenticated(
  p_owner_id uuid,
  p_idempotency_key uuid,
  p_item_name varchar default 'Secure token item'
) returns jsonb
language plpgsql
as $$
declare
  v_result jsonb;
begin
  perform set_config('request.jwt.claim.sub', p_owner_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
  select to_jsonb(p)
    into v_result
    from public.publish_dilemma(
      p_item_name,
      25000,
      'BRL',
      'other',
      'for_self',
      'Motivo valido para publicar com token seguro.',
      null,
      24,
      p_idempotency_key
    ) p;
  reset role;
  return v_result;
exception
  when others then
    reset role;
    raise;
end;
$$;

insert into auth.users (id)
values ('00000000-0000-4000-8000-000000000101');

insert into public.profiles (
  id,
  display_name,
  is_adult_confirmed,
  terms_accepted_version,
  privacy_accepted_version
)
values (
  '00000000-0000-4000-8000-000000000101',
  'Vote owner',
  true,
  'v1',
  'v1'
);

insert into auth.users (id)
values ('00000000-0000-4000-8000-000000000109');

insert into public.profiles (
  id,
  display_name,
  is_adult_confirmed,
  terms_accepted_version,
  privacy_accepted_version
)
values (
  '00000000-0000-4000-8000-000000000109',
  'Unconfirmed owner',
  false,
  'v1',
  'v1'
);

insert into public.dilemmas (
  id,
  owner_id,
  item_name,
  price_cents,
  currency,
  category,
  purpose,
  reason,
  pause_duration_hours,
  pause_due_at,
  state,
  invite_token_hash,
  is_invite_revoked
)
values
  (
    '10000000-0000-4000-8000-000000000101',
    '00000000-0000-4000-8000-000000000101',
    'Active vote item',
    10000,
    'BRL',
    'other',
    'for_self',
    'Motivo valido para o voto ativo.',
    24,
    now() + interval '1 day',
    'collecting_votes',
    encode(extensions.digest(repeat('A', 43), 'sha256'), 'hex'),
    false
  ),
  (
    '10000000-0000-4000-8000-000000000102',
    '00000000-0000-4000-8000-000000000101',
    'Other vote item',
    11000,
    'BRL',
    'other',
    'for_self',
    'Motivo valido para outro dilema.',
    24,
    now() + interval '1 day',
    'collecting_votes',
    encode(extensions.digest(repeat('B', 43), 'sha256'), 'hex'),
    false
  ),
  (
    '10000000-0000-4000-8000-000000000103',
    '00000000-0000-4000-8000-000000000101',
    'Revoked vote item',
    12000,
    'BRL',
    'other',
    'for_self',
    'Motivo valido para convite revogado.',
    24,
    now() + interval '1 day',
    'collecting_votes',
    encode(extensions.digest(repeat('C', 43), 'sha256'), 'hex'),
    true
  ),
  (
    '10000000-0000-4000-8000-000000000104',
    '00000000-0000-4000-8000-000000000101',
    'Due vote item',
    13000,
    'BRL',
    'other',
    'for_self',
    'Motivo valido para estado encerrado.',
    24,
    now() + interval '1 day',
    'decision_due',
    encode(extensions.digest(repeat('D', 43), 'sha256'), 'hex'),
    false
  ),
  (
    '10000000-0000-4000-8000-000000000105',
    '00000000-0000-4000-8000-000000000101',
    'Expired vote item',
    14000,
    'BRL',
    'other',
    'for_self',
    'Motivo valido para prazo encerrado.',
    24,
    now() - interval '1 second',
    'collecting_votes',
    encode(extensions.digest(repeat('E', 43), 'sha256'), 'hex'),
    false
  );

select ok(
  to_regprocedure(
    'public.submit_guest_vote(uuid,text,public.vote_prediction,text)'
  ) is not null,
  'the private guest-vote RPC exists'
);

select is(
  has_function_privilege(
    'anon',
    'public.submit_guest_vote(uuid,text,public.vote_prediction,text)',
    'execute'
  ),
  false,
  'anon cannot execute the guest-vote RPC directly'
);

select is(
  has_function_privilege(
    'authenticated',
    'public.submit_guest_vote(uuid,text,public.vote_prediction,text)',
    'execute'
  ),
  false,
  'authenticated cannot execute the guest-vote RPC directly'
);

select ok(
  has_function_privilege(
    'service_role',
    'public.submit_guest_vote(uuid,text,public.vote_prediction,text)',
    'execute'
  ),
  'service role can execute the guest-vote RPC'
);

select is(
  (
    select is_nullable
      from information_schema.columns
     where table_schema = 'public'
       and table_name = 'participations'
       and column_name = 'display_name'
  ),
  'YES',
  'guest participation no longer requires a display name'
);

select ok(
  exists (
    select 1
      from pg_constraint
     where conrelid = 'public.participations'::regclass
       and conname = 'participations_guest_session_fk'
       and contype = 'f'
       and confrelid = 'public.guest_access_sessions'::regclass
  ),
  'guest participation references a server-issued guest session'
);

select ok(
  exists (
    select 1
      from pg_constraint
     where conrelid = 'public.participations'::regclass
       and conname = 'participations_identity_shape'
       and contype = 'c'
  ),
  'participation identity shape is enforced by a check constraint'
);

select is(
  (
    select confdeltype::text
      from pg_constraint
     where conrelid = 'public.participations'::regclass
       and conname = 'participations_user_id_fkey'
  ),
  'c',
  'account deletion cascades authenticated participations'
);

select ok(
  (select relrowsecurity from pg_class
    where oid = 'public.guest_rate_limits'::regclass),
  'rate-limit counters have RLS enabled'
);

select is(
  has_table_privilege('anon', 'public.guest_rate_limits', 'select'),
  false,
  'anon cannot read rate-limit counters'
);

select is(
  has_function_privilege(
    'anon',
    'public.consume_guest_rate_limit(text,text,timestamptz)',
    'execute'
  ),
  false,
  'anon cannot execute the rate limiter directly'
);

select is(
  has_function_privilege(
    'authenticated',
    'public.publish_dilemma(varchar,bigint,varchar,public.item_category,public.purchase_purpose,text,text,text,varchar,integer,text,uuid)',
    'execute'
  ),
  false,
  'the legacy client-supplied-token publisher is disabled'
);

select ok(
  has_function_privilege(
    'authenticated',
    'public.publish_dilemma(varchar,bigint,varchar,public.item_category,public.purchase_purpose,text,varchar,integer,uuid)',
    'execute'
  ),
  'authenticated creators can use the server-token publisher'
);

select is(
  has_table_privilege('authenticated', 'public.dilemmas', 'insert'),
  false,
  'authenticated creators cannot bypass publication with direct insert'
);

select is(
  has_table_privilege('authenticated', 'public.dilemmas', 'update'),
  false,
  'authenticated creators cannot replace invite credentials with direct update'
);

select ok(
  to_regclass('public.dilemmas_owner_idempotency_key_idx') is not null,
  'publication has a unique owner and idempotency-key guard'
);

select throws_ok(
  $$select pg_temp.publish_as_authenticated(
    '00000000-0000-4000-8000-000000000109',
    '90000000-0000-4000-8000-000000000109'
  )$$,
  'P0001',
  'Adult confirmation and current consents are required.',
  'an unconfirmed profile cannot publish'
);

select throws_ok(
  $$select pg_temp.publish_as_authenticated(
    '00000000-0000-4000-8000-000000000101',
    null
  )$$,
  'P0001',
  'Idempotency key is required.',
  'publication requires an idempotency key'
);

create temporary table published_dilemma_result as
select pg_temp.publish_as_authenticated(
  '00000000-0000-4000-8000-000000000101',
  '90000000-0000-4000-8000-000000000101'
) as result;

select ok(
  (select result ->> 'invite_token' ~ '^[A-Za-z0-9_-]{43}$'
     from published_dilemma_result),
  'publishing returns a server-generated 256-bit Base64URL token'
);

select ok(
  (
    select d.invite_token_hash = encode(
      extensions.digest(r.result ->> 'invite_token', 'sha256'),
      'hex'
    )
      from published_dilemma_result r
      join public.dilemmas d
        on d.id = (r.result ->> 'dilemma_id')::uuid
  ),
  'publishing persists only the SHA-256 hash of the generated token'
);

create temporary table replayed_dilemma_result as
select pg_temp.publish_as_authenticated(
  '00000000-0000-4000-8000-000000000101',
  '90000000-0000-4000-8000-000000000101'
) as result;

select is(
  (select result from replayed_dilemma_result),
  (select result from published_dilemma_result),
  'a publication retry replays the same dilemma and raw token'
);

select is(
  (
    select count(*)::integer
      from public.dilemmas
     where owner_id = '00000000-0000-4000-8000-000000000101'
       and client_idempotency_key =
         '90000000-0000-4000-8000-000000000101'
  ),
  1,
  'a publication retry creates exactly one server dilemma'
);

select throws_ok(
  $$select pg_temp.publish_as_authenticated(
    '00000000-0000-4000-8000-000000000101',
    '90000000-0000-4000-8000-000000000101',
    'Different payload'
  )$$,
  'P0001',
  'Idempotency key was already used with another payload.',
  'reusing a key with another payload fails closed'
);

select is(
  has_table_privilege(
    'authenticated',
    'vault.decrypted_secrets',
    'select'
  ),
  false,
  'authenticated clients cannot read the server invite-token key'
);

select ok(
  (
    select bool_and(public.consume_guest_rate_limit(
      'invite_open',
      repeat('b', 64),
      clock_timestamp() + interval '1 hour'
    ))
      from generate_series(1, 30)
  ),
  'the invite-open limiter permits the documented 30 requests per minute'
);

select is(
  public.consume_guest_rate_limit(
    'invite_open',
    repeat('b', 64),
    clock_timestamp() + interval '1 hour'
  ),
  false,
  'the invite-open limiter rejects request 31'
);

select ok(
  (
    select bool_and(public.consume_guest_rate_limit(
      'guest_vote',
      repeat('c', 64),
      clock_timestamp() + interval '1 hour'
    ))
      from generate_series(1, 10)
  ),
  'the vote limiter permits the documented 10 changes per minute'
);

select is(
  public.consume_guest_rate_limit(
    'guest_vote',
    repeat('c', 64),
    clock_timestamp() + interval '1 hour'
  ),
  false,
  'the vote limiter rejects request 11'
);

select ok(
  (
    select expires_at <= clock_timestamp() + interval '61 seconds'
      from public.guest_rate_limits
     where scope = 'invite_open'
       and subject_key_hash = repeat('b', 64)
  ),
  'rate-limit counter TTL stays inside its one-minute window'
);

select is(
  public.consume_guest_rate_limit(
    'unknown_scope',
    repeat('d', 64),
    clock_timestamp() + interval '1 hour'
  ),
  false,
  'an unknown rate-limit scope fails closed'
);

insert into public.guest_rate_limits (
  scope,
  subject_key_hash,
  request_count,
  expires_at
) values (
  'guest_vote',
  repeat('e', 64),
  1,
  clock_timestamp() - interval '1 second'
);

select public.consume_guest_rate_limit(
  'guest_vote',
  repeat('f', 64),
  clock_timestamp() + interval '1 hour'
);

select ok(
  not exists (
    select 1
      from public.guest_rate_limits
     where subject_key_hash = repeat('e', 64)
  ),
  'a successful consume purges expired pseudonymous counters'
);

select is_empty(
  $$select result
      from (select pg_temp.open_invite_as_service(
        repeat('Z', 43),
        repeat('Y', 43)
      ) as result) attempted
     where result is not null$$,
  'an unknown valid-format invite remains generically unavailable'
);

select is(
  (
    select count(*)::integer
      from public.guest_rate_limits
     where scope = 'invite_open'
       and subject_key_hash = encode(
         extensions.digest('open:' || repeat('Z', 43), 'sha256'),
         'hex'
       )
  ),
  1,
  'an unknown valid-format invite is still rate limited'
);

select is_empty(
  $$select result
      from (select pg_temp.submit_vote_as_service(
        '10000000-0000-4000-8000-000000000101',
        repeat('Q', 43),
        'buy'
      ) as result) attempted
     where result is not null$$,
  'an unknown valid-format guest session remains generically unavailable'
);

select is(
  (
    select count(*)::integer
      from public.guest_rate_limits
     where scope = 'guest_vote'
       and subject_key_hash = encode(
         extensions.digest('vote:' || repeat('Q', 43), 'sha256'),
         'hex'
       )
  ),
  1,
  'an unknown valid-format guest session is still rate limited'
);

select lives_ok(
  $$select pg_temp.open_invite_as_service(
    repeat('A', 43),
    repeat('S', 43)
  )$$,
  'an active invite opens the session used by voting'
);

select is(
  (
    pg_temp.submit_vote_as_service(
      '10000000-0000-4000-8000-000000000101',
      repeat('S', 43),
      'buy'
    ) ->> 'prediction'
  ),
  'buy',
  'the first valid vote is persisted'
);

select is(
  (
    pg_temp.submit_vote_as_service(
      '10000000-0000-4000-8000-000000000101',
      repeat('S', 43),
      'buy'
    ) ->> 'changed'
  )::boolean,
  false,
  'repeating the same prediction is idempotent'
);

select is(
  (select count(*)::integer from public.participations
    where dilemma_id = '10000000-0000-4000-8000-000000000101'),
  1,
  'one session creates exactly one participation'
);

select is(
  (select count(*)::integer from public.votes v
    join public.participations p on p.id = v.participation_id
   where p.dilemma_id = '10000000-0000-4000-8000-000000000101'),
  1,
  'one session creates exactly one vote'
);

select is(
  (select display_name from public.participations
    where dilemma_id = '10000000-0000-4000-8000-000000000101'),
  null,
  'guest participation persists no display name'
);

select is(
  (
    pg_temp.submit_vote_as_service(
      '10000000-0000-4000-8000-000000000101',
      repeat('S', 43),
      'skip'
    ) ->> 'changed'
  )::boolean,
  true,
  'a different prediction replaces the previous vote'
);

select is(
  (select v.prediction::text from public.votes v
    join public.participations p on p.id = v.participation_id
   where p.dilemma_id = '10000000-0000-4000-8000-000000000101'),
  'skip',
  'the replacement prediction is the active vote'
);

select is(
  (
    select (r ->> 'total_votes')::integer
      from (select pg_temp.submit_vote_as_service(
        '10000000-0000-4000-8000-000000000101',
        repeat('S', 43),
        'skip'
      ) as r) result
  ),
  1,
  'post-vote aggregates include exactly the persisted votes'
);

select is(
  (
    select
      (r ->> 'buy_count')::integer
      + (r ->> 'wait_count')::integer
      + (r ->> 'skip_count')::integer
      - (r ->> 'total_votes')::integer
      from (select pg_temp.submit_vote_as_service(
        '10000000-0000-4000-8000-000000000101',
        repeat('S', 43),
        'skip'
      ) as r) result
  ),
  0,
  'aggregate choices sum to the total'
);

select is_empty(
  $$select result
      from (select pg_temp.submit_vote_as_service(
        '10000000-0000-4000-8000-000000000102',
        repeat('S', 43),
        'buy'
      ) as result) attempted
     where result is not null$$,
  'a session cannot vote on another dilemma'
);

select is_empty(
  $$select result
      from (select pg_temp.submit_vote_as_service(
        '10000000-0000-4000-8000-000000000101',
        repeat('W', 43),
        'buy'
      ) as result) attempted
     where result is not null$$,
  'an incorrect session secret cannot vote'
);

insert into public.guest_access_sessions (
  dilemma_id,
  session_secret_hash,
  created_at,
  expires_at
)
values (
  '10000000-0000-4000-8000-000000000101',
  encode(extensions.digest(
    repeat('X', 43),
    'sha256'
  ), 'hex'),
  now() - interval '2 hours',
  now() - interval '1 second'
);

select is_empty(
  $$select result
      from (select pg_temp.submit_vote_as_service(
        '10000000-0000-4000-8000-000000000101',
        repeat('X', 43),
        'buy'
      ) as result) attempted
     where result is not null$$,
  'an expired session cannot vote'
);

select is(
  (
    select session_secret_hash
      from public.guest_access_sessions
     where dilemma_id = '10000000-0000-4000-8000-000000000101'
       and created_at < now() - interval '1 hour'
  ),
  null,
  'an expired session keeps the vote anchor but erases its credential hash'
);

insert into public.guest_access_sessions (
  dilemma_id,
  session_secret_hash,
  expires_at,
  revoked_at
)
values (
  '10000000-0000-4000-8000-000000000101',
  encode(extensions.digest(
    repeat('R', 43),
    'sha256'
  ), 'hex'),
  now() + interval '1 hour',
  now()
);

select is_empty(
  $$select result
      from (select pg_temp.submit_vote_as_service(
        '10000000-0000-4000-8000-000000000101',
        repeat('R', 43),
        'buy'
      ) as result) attempted
     where result is not null$$,
  'a revoked session cannot vote'
);

select is_empty(
  $$select result
      from (select pg_temp.submit_vote_as_service(
        '10000000-0000-4000-8000-000000000103',
        repeat('T', 43),
        'buy'
      ) as result) attempted
     where result is not null$$,
  'a revoked invite cannot accept a vote'
);

select is_empty(
  $$select result
      from (select pg_temp.submit_vote_as_service(
        '10000000-0000-4000-8000-000000000104',
        repeat('U', 43),
        'buy'
      ) as result) attempted
     where result is not null$$,
  'a dilemma outside collecting_votes cannot accept a vote'
);

select is_empty(
  $$select result
      from (select pg_temp.submit_vote_as_service(
        '10000000-0000-4000-8000-000000000105',
        repeat('V', 43),
        'buy'
      ) as result) attempted
     where result is not null$$,
  'a dilemma past its pause deadline cannot accept a vote'
);

select is(
  (select count(*)::integer from public.participations
    where dilemma_id in (
      '10000000-0000-4000-8000-000000000102',
      '10000000-0000-4000-8000-000000000103',
      '10000000-0000-4000-8000-000000000104',
      '10000000-0000-4000-8000-000000000105'
    )),
  0,
  'all denied vote paths leave other dilemmas without participation'
);

select is(
  (select v.prediction::text from public.votes v
    join public.participations p on p.id = v.participation_id
   where p.dilemma_id = '10000000-0000-4000-8000-000000000101'
     and p.guest_session_id is not null),
  'skip',
  'all denied vote paths preserve the existing active vote'
);

insert into public.guest_access_sessions (
  dilemma_id,
  session_secret_hash,
  expires_at
) values
  (
    '10000000-0000-4000-8000-000000000101',
    encode(extensions.digest(repeat('J', 43), 'sha256'), 'hex'),
    now() + interval '1 hour'
  ),
  (
    '10000000-0000-4000-8000-000000000101',
    encode(extensions.digest(repeat('K', 43), 'sha256'), 'hex'),
    now() + interval '1 hour'
  );

select is(
  (
    pg_temp.submit_vote_as_service(
      '10000000-0000-4000-8000-000000000101',
      repeat('J', 43),
      'wait'
    ) ->> 'prediction'
  ),
  'wait',
  'wait is accepted as a first guest prediction'
);

select is(
  (
    pg_temp.submit_vote_as_service(
      '10000000-0000-4000-8000-000000000101',
      repeat('K', 43),
      'skip'
    ) ->> 'prediction'
  ),
  'skip',
  'skip is accepted as a first guest prediction'
);

delete from public.guest_access_sessions
 where session_secret_hash in (
   encode(extensions.digest(repeat('J', 43), 'sha256'), 'hex'),
   encode(extensions.digest(repeat('K', 43), 'sha256'), 'hex')
 );

select throws_ok(
  $$insert into public.participations (
      dilemma_id,
      guest_session_id,
      display_name
    ) values (
      '10000000-0000-4000-8000-000000000101',
      (select id from public.guest_access_sessions
        where dilemma_id = '10000000-0000-4000-8000-000000000101'
          and revoked_at is null
          and expires_at > now()
        limit 1),
      'Persisted guest name'
    )$$,
  '23514',
  null,
  'a guest participation cannot persist a display name'
);

select throws_ok(
  $$insert into public.participations (
      dilemma_id,
      guest_session_id,
      display_name
    ) values (
      '10000000-0000-4000-8000-000000000102',
      '30000000-0000-4000-8000-000000000999',
      null
    )$$,
  '23503',
  null,
  'a forged guest session cannot become a participation'
);

select throws_ok(
  $$select 'maybe'::public.vote_prediction$$,
  '22P02',
  null,
  'the vote enum rejects predictions outside the allowlist'
);

select is(
  has_table_privilege('anon', 'public.participations', 'insert'),
  false,
  'anon still has no direct participation insert grant'
);

select is(
  has_table_privilege('anon', 'public.votes', 'insert'),
  false,
  'anon still has no direct vote insert grant'
);

select is(
  (
    select array_agg(key order by key)
      from jsonb_object_keys(pg_temp.submit_vote_as_service(
        '10000000-0000-4000-8000-000000000101',
        repeat('S', 43),
        'skip'
      )) as key
  ),
  array[
    'buy_count',
    'changed',
    'prediction',
    'rate_limited',
    'skip_count',
    'total_votes',
    'wait_count'
  ],
  'the RPC returns only the post-vote allowlist'
);

select is(
  (
    select count(*)::integer
      from public.votes v
      join public.participations p on p.id = v.participation_id
     where p.dilemma_id = '10000000-0000-4000-8000-000000000101'
       and v.reason is not null
  ),
  0,
  'guest votes persist no textual reason'
);

delete from public.guest_access_sessions
 where session_secret_hash = encode(extensions.digest(
   repeat('S', 43),
   'sha256'
 ), 'hex');

select is(
  (select count(*)::integer from public.participations
    where dilemma_id = '10000000-0000-4000-8000-000000000101'),
  0,
  'deleting a guest session cascades through participation'
);

select is(
  (select count(*)::integer from public.votes v
    join public.participations p on p.id = v.participation_id
   where p.dilemma_id = '10000000-0000-4000-8000-000000000101'),
  0,
  'deleting a guest session cascades through the vote'
);

insert into public.dilemmas (
  id,
  owner_id,
  item_name,
  price_cents,
  currency,
  category,
  purpose,
  reason,
  pause_duration_hours,
  pause_due_at,
  state,
  invite_token_hash,
  is_invite_revoked
) values (
  '10000000-0000-4000-8000-000000000106',
  '00000000-0000-4000-8000-000000000101',
  'Cascade item',
  15000,
  'BRL',
  'other',
  'for_self',
  'Motivo valido para testar exclusao em cascata.',
  24,
  now() + interval '1 day',
  'collecting_votes',
  encode(extensions.digest(repeat('L', 43), 'sha256'), 'hex'),
  false
);

insert into public.guest_access_sessions (
  id,
  dilemma_id,
  session_secret_hash,
  expires_at
) values (
  '30000000-0000-4000-8000-000000000106',
  '10000000-0000-4000-8000-000000000106',
  encode(extensions.digest(repeat('M', 43), 'sha256'), 'hex'),
  now() + interval '1 day'
);

insert into public.participations (
  id,
  dilemma_id,
  guest_session_id,
  display_name
) values (
  '40000000-0000-4000-8000-000000000106',
  '10000000-0000-4000-8000-000000000106',
  '30000000-0000-4000-8000-000000000106',
  null
);

insert into public.votes (id, participation_id, prediction)
values (
  '50000000-0000-4000-8000-000000000106',
  '40000000-0000-4000-8000-000000000106',
  'wait'
);

delete from public.dilemmas
 where id = '10000000-0000-4000-8000-000000000106';

select is(
  (select count(*)::integer from public.guest_access_sessions
    where id = '30000000-0000-4000-8000-000000000106'),
  0,
  'hard-deleting a dilemma cascades its guest sessions'
);

select is(
  (select count(*)::integer from public.participations
    where id = '40000000-0000-4000-8000-000000000106'),
  0,
  'hard-deleting a dilemma cascades its participations'
);

select is(
  (select count(*)::integer from public.votes
    where id = '50000000-0000-4000-8000-000000000106'),
  0,
  'hard-deleting a dilemma cascades its votes'
);

insert into auth.users (id)
values ('00000000-0000-4000-8000-000000000102');

insert into public.profiles (
  id,
  display_name,
  terms_accepted_version,
  privacy_accepted_version
) values (
  '00000000-0000-4000-8000-000000000102',
  'Authenticated voter',
  'v1',
  'v1'
);

insert into public.participations (
  dilemma_id,
  user_id,
  display_name
) values (
  '10000000-0000-4000-8000-000000000101',
  '00000000-0000-4000-8000-000000000102',
  'Authenticated voter'
);

create temporary table authenticated_participation_result (
  id uuid primary key
);

insert into authenticated_participation_result (id)
select id
  from public.participations
 where user_id = '00000000-0000-4000-8000-000000000102';

insert into public.votes (participation_id, prediction)
select id, 'buy'
  from authenticated_participation_result;

delete from public.profiles
 where id = '00000000-0000-4000-8000-000000000102';

select is(
  (select count(*)::integer
     from public.participations
    where user_id = '00000000-0000-4000-8000-000000000102'),
  0,
  'hard-deleting a profile cascades its authenticated participation'
);

select is(
  (
    select count(*)::integer
      from public.votes
     where participation_id in (
       select id from authenticated_participation_result
     )
  ),
  0,
  'hard-deleting a profile cascades its authenticated vote'
);

select * from finish();

rollback;
