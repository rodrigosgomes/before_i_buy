begin;

select plan(13);

create or replace function pg_temp.upsert_profile_as_authenticated(
  p_user_id uuid,
  p_display_name varchar,
  p_adult boolean default true,
  p_terms boolean default true,
  p_privacy boolean default true
) returns jsonb
language plpgsql
as $$
declare
  v_result jsonb;
begin
  perform set_config('request.jwt.claim.sub', p_user_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  set local role authenticated;
  select to_jsonb(p)
    into v_result
    from public.upsert_creator_profile(
      p_display_name,
      p_adult,
      p_terms,
      p_privacy
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
values
  ('00000000-0000-4000-8000-000000000301'),
  ('00000000-0000-4000-8000-000000000302');

select is(
  has_table_privilege('authenticated', 'public.profiles', 'insert'),
  false,
  'authenticated cannot insert a profile directly'
);

select is(
  has_table_privilege('authenticated', 'public.profiles', 'update'),
  false,
  'authenticated cannot update a profile directly'
);

select is(
  has_function_privilege(
    'anon',
    'public.upsert_creator_profile(varchar, boolean, boolean, boolean)',
    'execute'
  ),
  false,
  'anon cannot upsert a creator profile'
);

select ok(
  has_function_privilege(
    'authenticated',
    'public.upsert_creator_profile(varchar, boolean, boolean, boolean)',
    'execute'
  ),
  'authenticated can upsert its own creator profile through the narrow RPC'
);

select is(
  (pg_temp.upsert_profile_as_authenticated(
    '00000000-0000-4000-8000-000000000301',
    '  Creator Dev  '
  )->>'display_name'),
  'Creator Dev',
  'the RPC trims and saves only the authenticated creator name'
);

select is(
  (select display_name from public.profiles
    where id = '00000000-0000-4000-8000-000000000301'),
  'Creator Dev',
  'the profile row belongs to auth.uid()'
);

select is(
  (select terms_accepted_version from public.profiles
    where id = '00000000-0000-4000-8000-000000000301'),
  'internal-demo-v1',
  'the server selects the internal Terms version'
);

select is(
  (select privacy_accepted_version from public.profiles
    where id = '00000000-0000-4000-8000-000000000301'),
  'internal-demo-v1',
  'the server selects the internal Privacy version'
);

select throws_ok(
  $$select pg_temp.upsert_profile_as_authenticated(
    '00000000-0000-4000-8000-000000000302',
    'Another Creator',
    false,
    true,
    true
  )$$,
  'P0001',
  'Adult confirmation and both internal acknowledgements are required.',
  'the RPC rejects incomplete acknowledgements'
);

select throws_ok(
  $$select pg_temp.upsert_profile_as_authenticated(
    '00000000-0000-4000-8000-000000000302',
    'x'
  )$$,
  'P0001',
  'Display name must contain 2 to 50 characters.',
  'the RPC enforces the public display-name bounds'
);

select throws_ok(
  $$select pg_temp.upsert_profile_as_authenticated(
    '00000000-0000-4000-8000-000000000302',
    repeat('a', 51)
  )$$,
  'P0001',
  'Display name must contain 2 to 50 characters.',
  'the RPC keeps names within the invite projection limit'
);

select is(
  public.creator_profile_has_active_consents(
    'internal-demo-v1',
    'internal-demo-v1'
  ),
  true,
  'only registered active versions satisfy the publication consent check'
);

select is(
  public.creator_profile_has_active_consents('forged-v1', 'forged-v1'),
  false,
  'forged consent versions do not satisfy publication'
);

select * from finish();
rollback;
