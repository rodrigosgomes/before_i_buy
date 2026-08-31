begin;

select plan(44);

create or replace function pg_temp.can_read_row_as(
  p_role name,
  p_user_id uuid,
  p_relation regclass,
  p_row_id uuid
) returns boolean
language plpgsql
as $$
declare
  v_can_read boolean := false;
begin
  perform set_config(
    'request.jwt.claim.sub',
    coalesce(p_user_id::text, ''),
    true
  );
  perform set_config(
    'request.jwt.claim.role',
    p_role::text,
    true
  );
  execute format('set local role %I', p_role);
  execute format(
    'select exists (select 1 from %s where id = $1)',
    p_relation
  ) into v_can_read using p_row_id;
  reset role;
  return v_can_read;
exception
  when insufficient_privilege then
    reset role;
    return false;
end;
$$;

create or replace function pg_temp.rename_dilemma_as(
  p_user_id uuid,
  p_dilemma_id uuid,
  p_item_name varchar
) returns integer
language plpgsql
as $$
declare
  v_rows integer := 0;
begin
  perform set_config('request.jwt.claim.sub', p_user_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
  update public.dilemmas
     set item_name = p_item_name
   where id = p_dilemma_id;
  get diagnostics v_rows = row_count;
  reset role;
  return v_rows;
exception
  when insufficient_privilege then
    reset role;
    return 0;
end;
$$;

create or replace function pg_temp.open_guest_invite_as_service(
  p_invite_token_plain text,
  p_session_secret_plain text
) returns jsonb
language plpgsql
as $$
declare
  v_projection jsonb;
begin
  set local role service_role;
  select to_jsonb(s)
    into v_projection
    from public.open_guest_invite_session(
      p_invite_token_plain,
      p_session_secret_plain
    ) s;
  reset role;
  return v_projection;
exception
  when others then
    reset role;
    raise;
end;
$$;

create or replace function pg_temp.get_guest_invite_as_service(
  p_dilemma_id uuid,
  p_session_secret_plain text
) returns jsonb
language plpgsql
as $$
declare
  v_projection jsonb;
begin
  set local role service_role;
  select to_jsonb(s)
    into v_projection
    from public.get_guest_invite_session(
      p_dilemma_id,
      p_session_secret_plain
    ) s;
  reset role;
  return v_projection;
exception
  when others then
    reset role;
    raise;
end;
$$;

create or replace function pg_temp.can_insert_forged_guest_participation()
returns boolean
language plpgsql
as $$
begin
  perform set_config('request.jwt.claim.role', 'anon', true);
  set local role anon;
  insert into public.participations (
    dilemma_id,
    guest_session_id,
    display_name
  ) values (
    '10000000-0000-4000-8000-000000000001',
    '30000000-0000-4000-8000-000000000001',
    'Forged guest'
  );
  reset role;
  return true;
exception
  when insufficient_privilege then
    reset role;
    return false;
end;
$$;

create or replace function pg_temp.can_insert_owner_expectation_as(
  p_user_id uuid,
  p_dilemma_id uuid
) returns boolean
language plpgsql
as $$
begin
  perform set_config('request.jwt.claim.sub', p_user_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
  insert into public.owner_expectations (
    id,
    dilemma_id,
    owner_id,
    expected_satisfaction
  ) values (
    '20000000-0000-4000-8000-000000000002',
    p_dilemma_id,
    p_user_id,
    'yes'
  );
  reset role;
  return true;
exception
  when insufficient_privilege then
    reset role;
    return false;
end;
$$;

insert into auth.users (id)
values
  ('00000000-0000-4000-8000-000000000001'),
  ('00000000-0000-4000-8000-000000000002');

insert into public.profiles (
  id,
  display_name,
  terms_accepted_version,
  privacy_accepted_version
)
values
  ('00000000-0000-4000-8000-000000000001', 'Owner A', 'v1', 'v1'),
  ('00000000-0000-4000-8000-000000000002', 'Owner B', 'v1', 'v1');

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
    '10000000-0000-4000-8000-000000000001',
    '00000000-0000-4000-8000-000000000001',
    'Camera A',
    150000,
    'BRL',
    'tech_electronics',
    'for_self',
    'Preciso de uma camera para viagens.',
    24,
    now() + interval '2 days',
    'collecting_votes',
    encode(extensions.digest('invite-token-alpha', 'sha256'), 'hex'),
    false
  ),
  (
    '10000000-0000-4000-8000-000000000002',
    '00000000-0000-4000-8000-000000000002',
    'Camera B',
    180000,
    'BRL',
    'tech_electronics',
    'for_self',
    'Preciso de uma camera para trabalho.',
    24,
    now() + interval '2 days',
    'collecting_votes',
    encode(extensions.digest('invite-token-bravo', 'sha256'), 'hex'),
    false
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
    '10000000-0000-4000-8000-000000000003',
    '00000000-0000-4000-8000-000000000001',
    'Revoked camera',
    151000,
    'BRL',
    'tech_electronics',
    'for_self',
    'Dilema de convite revogado.',
    24,
    now() + interval '2 days',
    'collecting_votes',
    encode(extensions.digest('invite-token-charlie', 'sha256'), 'hex'),
    true
  ),
  (
    '10000000-0000-4000-8000-000000000004',
    '00000000-0000-4000-8000-000000000001',
    'Decision due camera',
    152000,
    'BRL',
    'tech_electronics',
    'for_self',
    'Dilema fora do estado permitido.',
    24,
    now() + interval '2 days',
    'decision_due',
    encode(extensions.digest('invite-token-delta', 'sha256'), 'hex'),
    false
  ),
  (
    '10000000-0000-4000-8000-000000000005',
    '00000000-0000-4000-8000-000000000001',
    'Hidden camera',
    153000,
    'BRL',
    'tech_electronics',
    'for_self',
    'Dilema oculto pela moderacao.',
    24,
    now() + interval '2 days',
    'moderation_hidden',
    encode(extensions.digest('invite-token-echo', 'sha256'), 'hex'),
    false
  ),
  (
    '10000000-0000-4000-8000-000000000006',
    '00000000-0000-4000-8000-000000000001',
    'Expired camera',
    154000,
    'BRL',
    'tech_electronics',
    'for_self',
    'Dilema com pausa vencida.',
    24,
    now() - interval '1 second',
    'collecting_votes',
    encode(extensions.digest('invite-token-foxtrot', 'sha256'), 'hex'),
    false
  ),
  (
    '10000000-0000-4000-8000-000000000007',
    '00000000-0000-4000-8000-000000000001',
    'Deleted camera',
    155000,
    'BRL',
    'tech_electronics',
    'for_self',
    'Dilema que sera apagado.',
    24,
    now() + interval '2 days',
    'collecting_votes',
    encode(extensions.digest('invite-token-golf', 'sha256'), 'hex'),
    false
  );

insert into public.owner_expectations (id, dilemma_id, owner_id, expected_satisfaction)
values (
  '20000000-0000-4000-8000-000000000001',
  '10000000-0000-4000-8000-000000000001',
  '00000000-0000-4000-8000-000000000001',
  'yes'
);

select is(
  (select count(*)::integer from pg_policies
   where schemaname = 'public'
     and tablename in ('dilemmas', 'participations', 'votes', 'guest_access_sessions')
     and (
       roles @> array['public']::name[]
       or roles @> array['anon']::name[]
     )),
  0,
  'no dilemma, participation, vote, or guest-session policy targets public/anon'
);

select is(
  has_table_privilege('anon', 'public.dilemmas', 'select'),
  false,
  'anon has no direct select grant on dilemmas'
);

select is(
  has_table_privilege('anon', 'public.participations', 'select'),
  false,
  'anon has no direct select grant on participations'
);

select is(
  has_table_privilege('anon', 'public.votes', 'select'),
  false,
  'anon has no direct select grant on votes'
);

select is(
  has_table_privilege('anon', 'public.guest_access_sessions', 'select'),
  false,
  'anon has no direct select grant on guest access sessions'
);

select ok(
  not pg_temp.can_read_row_as(
    'anon',
    null,
    'public.dilemmas',
    '10000000-0000-4000-8000-000000000001'
  ),
  'anon cannot directly read an active dilemma'
);

select ok(
  (select rowsecurity
     from pg_tables
    where schemaname = 'public'
      and tablename = 'guest_access_sessions'),
  'guest access sessions have RLS enabled'
);

select ok(
  not pg_temp.can_insert_forged_guest_participation(),
  'anon cannot create a participation with an invented guest_session_id'
);

select ok(
  not pg_temp.can_read_row_as(
    'authenticated',
    '00000000-0000-4000-8000-000000000002',
    'public.profiles',
    '00000000-0000-4000-8000-000000000001'
  ),
  'a signed-in user cannot read another profile'
);

select ok(
  pg_temp.can_read_row_as(
    'authenticated',
    '00000000-0000-4000-8000-000000000001',
    'public.dilemmas',
    '10000000-0000-4000-8000-000000000001'
  ),
  'owner can read the owner dilemma'
);

select ok(
  not pg_temp.can_read_row_as(
    'authenticated',
    '00000000-0000-4000-8000-000000000002',
    'public.dilemmas',
    '10000000-0000-4000-8000-000000000001'
  ),
  'a signed-in non-owner cannot read another dilemma'
);

select ok(
  pg_temp.can_read_row_as(
    'authenticated',
    '00000000-0000-4000-8000-000000000001',
    'public.profiles',
    '00000000-0000-4000-8000-000000000001'
  ),
  'a signed-in user can read the own profile'
);

select ok(
  not pg_temp.can_insert_owner_expectation_as(
    '00000000-0000-4000-8000-000000000001',
    '10000000-0000-4000-8000-000000000002'
  ),
  'an owner cannot create an expectation for another owner dilemma'
);

select is(
  (select count(*)::integer from public.owner_expectations
   where dilemma_id = '10000000-0000-4000-8000-000000000002'),
  0,
  'cross-owner expectation insertion leaves the other dilemma unchanged'
);

select is(
  pg_temp.rename_dilemma_as(
    '00000000-0000-4000-8000-000000000002',
    '10000000-0000-4000-8000-000000000001',
    'Attempted rename'
  ),
  0,
  'a signed-in non-owner cannot mutate another dilemma'
);

select is(
  (select item_name from public.dilemmas where id = '10000000-0000-4000-8000-000000000001'),
  'Camera A',
  'the rejected cross-owner mutation leaves the dilemma unchanged'
);

select ok(
  not pg_temp.can_read_row_as(
    'anon',
    null,
    'public.owner_expectations',
    '20000000-0000-4000-8000-000000000001'
  ),
  'anon cannot read owner expectations'
);

select is(
  has_function_privilege(
    'anon',
    'public.open_guest_invite_session(text, text)',
    'execute'
  ),
  false,
  'anon cannot execute the private invite-session RPC'
);

select ok(
  has_function_privilege(
    'service_role',
    'public.open_guest_invite_session(text, text)',
    'execute'
  ),
  'only the service role can execute the invite-session RPC'
);

select is(
  has_function_privilege(
    'anon',
    'public.get_guest_invite_session(uuid, text)',
    'execute'
  ),
  false,
  'anon cannot execute the private guest-session lookup RPC'
);

select is(
  to_regprocedure('public.exchange_invite_token(text)') is null,
  true,
  'the legacy broad invite-token RPC is removed'
);

select is(
  has_function_privilege(
    'anon',
    'public.publish_dilemma(varchar, bigint, varchar, public.item_category, public.purchase_purpose, text, text, text, varchar, integer, text, uuid)',
    'execute'
  ),
  false,
  'anon cannot execute publish_dilemma'
);

select ok(
  has_function_privilege(
    'authenticated',
    'public.publish_dilemma(varchar, bigint, varchar, public.item_category, public.purchase_purpose, text, text, text, varchar, integer, text, uuid)',
    'execute'
  ),
  'authenticated can execute publish_dilemma'
);

select is(
  has_function_privilege(
    'anon',
    'public.record_decision(uuid, public.decision_type, varchar, text)',
    'execute'
  ),
  false,
  'anon cannot execute record_decision'
);

select is(
  has_function_privilege(
    'anon',
    'public.record_reflection(uuid, public.satisfaction_outcome, text, boolean)',
    'execute'
  ),
  false,
  'anon cannot execute record_reflection'
);

select is_empty(
  $$select projection
      from (select pg_temp.open_guest_invite_as_service(
        'not-a-token',
        'test-secret-0000000000000000000000000000000000000000000'
      ) as projection) result
     where projection is not null$$,
  'an invalid invite token returns no projection'
);

select is_empty(
  $$select projection
      from (select pg_temp.open_guest_invite_as_service(
        'invite-token-charlie',
        'test-secret-0000000000000000000000000000000000000000003'
      ) as projection) result
     where projection is not null$$,
  'a revoked invite returns no projection'
);

select is_empty(
  $$select projection
      from (select pg_temp.open_guest_invite_as_service(
        'invite-token-delta',
        'test-secret-0000000000000000000000000000000000000000004'
      ) as projection) result
     where projection is not null$$,
  'an invite outside collecting_votes returns no projection'
);

select is_empty(
  $$select projection
      from (select pg_temp.open_guest_invite_as_service(
        'invite-token-echo',
        'test-secret-0000000000000000000000000000000000000000005'
      ) as projection) result
     where projection is not null$$,
  'a moderation-hidden invite returns no projection'
);

select is_empty(
  $$select projection
      from (select pg_temp.open_guest_invite_as_service(
        'invite-token-foxtrot',
        'test-secret-0000000000000000000000000000000000000000006'
      ) as projection) result
     where projection is not null$$,
  'an expired invite returns no projection'
);

select is(
  (select count(*)::integer from public.guest_access_sessions
   where dilemma_id in (
     '10000000-0000-4000-8000-000000000003',
     '10000000-0000-4000-8000-000000000004',
     '10000000-0000-4000-8000-000000000005',
     '10000000-0000-4000-8000-000000000006'
   )),
  0,
  'invalid invite states create no guest session'
);

select lives_ok(
  $$select pg_temp.open_guest_invite_as_service(
    'invite-token-alpha',
    'test-secret-0000000000000000000000000000000000000000001'
  )$$,
  'a valid invite can create a server-side guest session'
);

select is(
  (select count(*)::integer from public.guest_access_sessions
   where dilemma_id = '10000000-0000-4000-8000-000000000001'),
  1,
  'opening a valid invite creates exactly one session'
);

select is(
  (select session_secret_hash::text from public.guest_access_sessions
   where dilemma_id = '10000000-0000-4000-8000-000000000001'),
  encode(extensions.digest('test-secret-0000000000000000000000000000000000000000001', 'sha256'), 'hex')::text,
  'only the SHA-256 hash of the guest secret is stored'
);

select ok(
  (select gas.expires_at <= d.pause_due_at
     from public.guest_access_sessions gas
     join public.dilemmas d on d.id = gas.dilemma_id
    where gas.dilemma_id = '10000000-0000-4000-8000-000000000001'),
  'the guest session never outlives the dilemma pause window'
);

select throws_ok(
  $$insert into public.guest_access_sessions (
      dilemma_id,
      session_secret_hash,
      expires_at
    ) values (
      '10000000-0000-4000-8000-000000000001',
      'not-a-sha256-hash',
      now() + interval '1 hour'
    )$$,
  '23514',
  'new row for relation "guest_access_sessions" violates check constraint "guest_access_sessions_secret_hash_is_sha256"',
  'guest session storage rejects values that are not SHA-256 hex digests'
);

select is(
  (
    select array_agg(key order by key)
      from jsonb_object_keys(pg_temp.open_guest_invite_as_service(
        'invite-token-alpha',
        'test-secret-0000000000000000000000000000000000000000002'
      )) as key
  ) && array['total_votes', 'image_url', 'product_url', 'invite_token_hash', 'session_secret_hash'],
  false,
  'the guest projection omits aggregates, media URLs, and secret hashes'
);

select is_empty(
  $$select projection
      from (select pg_temp.get_guest_invite_as_service(
        '10000000-0000-4000-8000-000000000002',
        'test-secret-0000000000000000000000000000000000000000001'
      ) as projection) result
     where projection is not null$$,
  'a guest session cannot be used for a different dilemma'
);

select lives_ok(
  $$select pg_temp.open_guest_invite_as_service(
    'invite-token-golf',
    'test-secret-0000000000000000000000000000000000000000007'
  )$$,
  'an active invite can create a session before dilemma deletion'
);

delete from public.dilemmas
 where id = '10000000-0000-4000-8000-000000000007';

select is(
  (select count(*)::integer from public.guest_access_sessions
   where dilemma_id = '10000000-0000-4000-8000-000000000007'),
  0,
  'deleting a dilemma cascades to its guest sessions'
);

select is_empty(
  $$select projection
      from (select pg_temp.open_guest_invite_as_service(
        'invite-token-golf',
        'test-secret-0000000000000000000000000000000000000000007'
      ) as projection) result
     where projection is not null$$,
  'a deleted invite returns no projection and creates no session'
);

insert into public.guest_access_sessions (
  dilemma_id,
  session_secret_hash,
  created_at,
  expires_at
)
values (
  '10000000-0000-4000-8000-000000000001',
  encode(extensions.digest('expired-secret-00000000000000000000000000000000000000001', 'sha256'), 'hex'),
  now() - interval '2 hours',
  now() - interval '1 second'
);

select is_empty(
  $$select projection
      from (select pg_temp.get_guest_invite_as_service(
        '10000000-0000-4000-8000-000000000001',
        'expired-secret-00000000000000000000000000000000000000001'
      ) as projection) result
     where projection is not null$$,
  'an expired guest session cannot read the invite projection'
);

update public.dilemmas
   set is_invite_revoked = true
 where id = '10000000-0000-4000-8000-000000000001';

select is_empty(
  $$select projection
      from (select pg_temp.get_guest_invite_as_service(
        '10000000-0000-4000-8000-000000000001',
        'test-secret-0000000000000000000000000000000000000000001'
      ) as projection) result
     where projection is not null$$,
  'revoking the invite invalidates previously issued guest sessions'
);

select is(
  (select count(*)::integer from pg_policies
   where schemaname = 'public'
     and tablename = 'outbox_jobs'
     and cardinality(roles) > 0),
  0,
  'outbox jobs have no client-facing policy'
);

select * from finish();

rollback;
