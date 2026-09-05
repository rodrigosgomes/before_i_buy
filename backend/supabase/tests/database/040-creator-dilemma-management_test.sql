begin;

select plan(20);

insert into auth.users (id)
values
  ('00000000-0000-4000-8000-000000000401'),
  ('00000000-0000-4000-8000-000000000402');

-- Setup profiles with active consent
insert into public.profiles (
  id, display_name, is_adult_confirmed, terms_accepted_version, privacy_accepted_version
) values
  ('00000000-0000-4000-8000-000000000401', 'Owner A', true, 'internal-demo-v1', 'internal-demo-v1'),
  ('00000000-0000-4000-8000-000000000402', 'Owner B', true, 'internal-demo-v1', 'internal-demo-v1');

-- Privileges tests
select is(
  has_function_privilege('anon', 'public.get_creator_dilemmas()', 'execute'),
  false,
  'anon cannot execute get_creator_dilemmas'
);

select is(
  has_function_privilege('anon', 'public.revoke_dilemma_invite(uuid)', 'execute'),
  false,
  'anon cannot execute revoke_dilemma_invite'
);

select is(
  has_function_privilege('anon', 'public.delete_creator_dilemma(uuid)', 'execute'),
  false,
  'anon cannot execute delete_creator_dilemma'
);

select is(
  has_function_privilege('authenticated', 'public.get_creator_dilemmas()', 'execute'),
  true,
  'authenticated can execute get_creator_dilemmas'
);

select is(
  has_function_privilege('authenticated', 'public.revoke_dilemma_invite(uuid)', 'execute'),
  true,
  'authenticated can execute revoke_dilemma_invite'
);

select is(
  has_function_privilege('authenticated', 'public.delete_creator_dilemma(uuid)', 'execute'),
  true,
  'authenticated can execute delete_creator_dilemma'
);

-- Helper functions to execute as authenticated
create or replace function pg_temp.publish_as(
  p_user_id uuid,
  p_item_name varchar,
  p_idempotency_key uuid
) returns uuid
language plpgsql as $$
declare
  v_dilemma_id uuid;
begin
  perform set_config('request.jwt.claim.sub', p_user_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
  select dilemma_id into v_dilemma_id
    from public.publish_dilemma(
      p_item_name, 15000, 'BRL', 'other', 'for_self', 'Motivo teste',
      null, 24, p_idempotency_key
    );
  reset role;
  return v_dilemma_id;
exception when others then
  reset role;
  raise;
end;
$$;

create or replace function pg_temp.get_dilemmas_as(p_user_id uuid)
returns table (
  item_name varchar(80),
  buy_count bigint,
  wait_count bigint,
  skip_count bigint,
  total_votes bigint,
  is_invite_revoked boolean
)
language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', p_user_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
  return query
  select
    d.item_name,
    d.buy_count,
    d.wait_count,
    d.skip_count,
    d.total_votes,
    d.is_invite_revoked
  from public.get_creator_dilemmas() d;
  reset role;
end;
$$;

create or replace function pg_temp.revoke_as(p_user_id uuid, p_dilemma_id uuid)
returns void
language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', p_user_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
  perform public.revoke_dilemma_invite(p_dilemma_id);
  reset role;
exception when others then
  reset role;
  raise;
end;
$$;

create or replace function pg_temp.delete_as(p_user_id uuid, p_dilemma_id uuid)
returns void
language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', p_user_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
  perform public.delete_creator_dilemma(p_dilemma_id);
  reset role;
exception when others then
  reset role;
  raise;
end;
$$;

-- Publish dilemmas
select lives_ok(
  $$select pg_temp.publish_as('00000000-0000-4000-8000-000000000401', 'Item A', '00000000-0000-4000-8000-000000000411')$$,
  'Owner A can publish a dilemma'
);

select lives_ok(
  $$select pg_temp.publish_as('00000000-0000-4000-8000-000000000402', 'Item B', '00000000-0000-4000-8000-000000000412')$$,
  'Owner B can publish a dilemma'
);

-- Insert sample guest session and votes for Item A
do $$
declare
  v_dilemma_a uuid;
  v_session_1 uuid := gen_random_uuid();
  v_session_2 uuid := gen_random_uuid();
  v_part_1 uuid;
  v_part_2 uuid;
begin
  select id into v_dilemma_a from public.dilemmas where owner_id = '00000000-0000-4000-8000-000000000401';

  insert into public.guest_access_sessions (id, dilemma_id, session_secret_hash, expires_at)
  values
    (v_session_1, v_dilemma_a, repeat('a', 64), now() + interval '24 hours'),
    (v_session_2, v_dilemma_a, repeat('b', 64), now() + interval '24 hours');

  insert into public.participations (dilemma_id, guest_session_id)
  values
    (v_dilemma_a, v_session_1)
  returning id into v_part_1;

  insert into public.participations (dilemma_id, guest_session_id)
  values
    (v_dilemma_a, v_session_2)
  returning id into v_part_2;

  insert into public.votes (participation_id, prediction)
  values
    (v_part_1, 'buy'),
    (v_part_2, 'skip');
end;
$$;

-- Verify Owner A sees exact aggregates and only their dilemma
select results_eq(
  $$select item_name, buy_count, wait_count, skip_count, total_votes, is_invite_revoked
      from pg_temp.get_dilemmas_as('00000000-0000-4000-8000-000000000401')$$,
  $$values ('Item A'::varchar(80), 1::bigint, 0::bigint, 1::bigint, 2::bigint, false)$$,
  'Owner A sees only Item A with exact vote counts'
);

-- Verify Owner B sees 0 votes on Item B
select results_eq(
  $$select item_name, buy_count, wait_count, skip_count, total_votes, is_invite_revoked
      from pg_temp.get_dilemmas_as('00000000-0000-4000-8000-000000000402')$$,
  $$values ('Item B'::varchar(80), 0::bigint, 0::bigint, 0::bigint, 0::bigint, false)$$,
  'Owner B sees only Item B with zero votes'
);

-- Owner B cannot revoke Owner A's dilemma
select throws_ok(
  $$select pg_temp.revoke_as(
    '00000000-0000-4000-8000-000000000402',
    (select id from public.dilemmas where owner_id = '00000000-0000-4000-8000-000000000401')
  )$$,
  'P0002', 'Dilemma not found or unauthorized',
  'Owner B cannot revoke Owner A dilemma'
);

-- Owner A revokes their dilemma
select lives_ok(
  $$select pg_temp.revoke_as(
    '00000000-0000-4000-8000-000000000401',
    (select id from public.dilemmas where owner_id = '00000000-0000-4000-8000-000000000401')
  )$$,
  'Owner A can revoke own dilemma'
);

-- Owner A sees is_invite_revoked = true and guest sessions are marked revoked
select results_eq(
  $$select is_invite_revoked
      from pg_temp.get_dilemmas_as('00000000-0000-4000-8000-000000000401')$$,
  $$values (true)$$,
  'Owner A sees is_invite_revoked = true after revoking'
);

select is(
  (
    select count(*)::bigint
      from public.guest_access_sessions gas
      join public.dilemmas d on d.id = gas.dilemma_id
     where d.owner_id = '00000000-0000-4000-8000-000000000401'
       and gas.revoked_at is not null
  ),
  2::bigint,
  'revoking through the owner RPC invalidates every existing guest session'
);

-- Owner B cannot delete Owner A's dilemma
select throws_ok(
  $$select pg_temp.delete_as(
    '00000000-0000-4000-8000-000000000402',
    (select id from public.dilemmas where owner_id = '00000000-0000-4000-8000-000000000401')
  )$$,
  'P0002', 'Dilemma not found or unauthorized',
  'Owner B cannot delete Owner A dilemma'
);

create temp table pg_temp.test_dilemma_ref as
select id as dilemma_id from public.dilemmas where owner_id = '00000000-0000-4000-8000-000000000401';

-- Owner A deletes their dilemma
select lives_ok(
  $$select pg_temp.delete_as(
    '00000000-0000-4000-8000-000000000401',
    (select dilemma_id from pg_temp.test_dilemma_ref)
  )$$,
  'Owner A can delete own dilemma'
);

-- Assert permanent cascade deletion (LGPD)
select is(
  (select count(*)::bigint from public.dilemmas where id in (select dilemma_id from pg_temp.test_dilemma_ref)),
  0::bigint,
  'Dilemma record is permanently deleted'
);

select is(
  (select count(*)::bigint from public.participations where dilemma_id in (select dilemma_id from pg_temp.test_dilemma_ref)),
  0::bigint,
  'Participations are purged in cascade'
);

select is(
  (select count(*)::bigint from public.guest_access_sessions where dilemma_id in (select dilemma_id from pg_temp.test_dilemma_ref)),
  0::bigint,
  'Guest sessions are purged in cascade'
);

select is(
  (select count(*)::bigint from public.votes where participation_id not in (select id from public.participations)),
  0::bigint,
  'No orphan votes remain after cascade delete'
);

select * from finish();
rollback;
