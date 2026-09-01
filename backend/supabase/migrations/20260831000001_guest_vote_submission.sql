-- Guest vote vertical slice: server-issued session -> one anonymous vote.
-- Historical migrations remain unchanged; direct client table access stays off.

create extension if not exists supabase_vault with schema vault;

do $$
begin
  if exists (
    select 1
      from public.participations p
      left join public.guest_access_sessions gas
        on gas.id = p.guest_session_id
       and gas.dilemma_id = p.dilemma_id
     where p.guest_session_id is not null
       and gas.id is null
  ) then
    raise exception
      'Cannot scope guest participations: an existing guest session is missing or belongs to another dilemma.';
  end if;
end;
$$;

alter table public.participations
  alter column display_name drop not null;

alter table public.participations
  drop constraint if exists chk_user_or_guest;

alter table public.participations
  add constraint participations_identity_shape
  check (
    (
      user_id is not null
      and guest_session_id is null
      and display_name is not null
    )
    or
    (
      user_id is null
      and guest_session_id is not null
      and display_name is null
    )
  );

-- Account deletion is a hard delete. SET NULL would leave an identity-less
-- authenticated participation that violates participations_identity_shape.
alter table public.participations
  drop constraint if exists participations_user_id_fkey;

alter table public.participations
  add constraint participations_user_id_fkey
  foreign key (user_id)
  references public.profiles (id)
  on delete cascade;

alter table public.guest_access_sessions
  add constraint guest_access_sessions_id_dilemma_key
  unique (id, dilemma_id);

alter table public.participations
  add constraint participations_guest_session_fk
  foreign key (guest_session_id, dilemma_id)
  references public.guest_access_sessions (id, dilemma_id)
  on delete cascade;

-- Keep the non-identifying session row as the vote's relational anchor, but
-- erase the authentication credential after expiry so it is no longer a
-- stable pseudonymous lookup key.
alter table public.guest_access_sessions
  alter column session_secret_hash drop not null;

alter table public.guest_access_sessions
  drop constraint if exists guest_access_sessions_secret_hash_is_sha256;

alter table public.guest_access_sessions
  add constraint guest_access_sessions_secret_hash_is_sha256
  check (
    session_secret_hash is null
    or session_secret_hash ~ '^[0-9a-f]{64}$'
  );

-- Rate-limit subjects are HMAC digests produced at the Edge boundary. They
-- cannot be reversed into invite or session secrets and are purged after TTL.
create table public.guest_rate_limits (
  scope text not null,
  subject_key_hash varchar(64) not null,
  request_count integer not null,
  expires_at timestamptz not null,
  primary key (scope, subject_key_hash),
  constraint guest_rate_limits_scope_check
    check (scope in ('invite_open', 'guest_vote')),
  constraint guest_rate_limits_subject_hash_check
    check (subject_key_hash ~ '^[0-9a-f]{64}$'),
  constraint guest_rate_limits_request_count_check
    check (request_count > 0)
);

create index guest_rate_limits_expires_at_idx
  on public.guest_rate_limits (expires_at);

alter table public.guest_rate_limits enable row level security;

revoke all on table public.guest_rate_limits
from public, anon, authenticated;
grant all on table public.guest_rate_limits to service_role;

create or replace function public.consume_guest_rate_limit(
  p_scope text,
  p_subject_key_hash text,
  p_subject_expires_at timestamptz
)
returns boolean
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_now timestamptz := clock_timestamp();
  v_limit integer;
  v_window interval := interval '60 seconds';
  v_expires_at timestamptz;
  v_request_count integer;
begin
  if p_scope = 'invite_open' then
    v_limit := 30;
  elsif p_scope = 'guest_vote' then
    v_limit := 10;
  else
    return false;
  end if;

  if p_subject_key_hash is null
     or p_subject_key_hash !~ '^[0-9a-f]{64}$'
     or p_subject_expires_at is null
     or p_subject_expires_at <= v_now then
    return false;
  end if;

  -- Keep the counter logically and physically ephemeral without retaining a
  -- stable guest identifier after its short window.
  delete from public.guest_rate_limits
   where expires_at <= v_now;

  update public.guest_access_sessions
     set session_secret_hash = null
   where id in (
     select gas.id
       from public.guest_access_sessions gas
      where gas.expires_at <= v_now
        and gas.session_secret_hash is not null
      order by gas.expires_at
      for update skip locked
      limit 100
   );

  v_expires_at := least(v_now + v_window, p_subject_expires_at);

  insert into public.guest_rate_limits (
    scope,
    subject_key_hash,
    request_count,
    expires_at
  ) values (
    p_scope,
    p_subject_key_hash,
    1,
    v_expires_at
  )
  on conflict (scope, subject_key_hash) do update
    set request_count = case
          when public.guest_rate_limits.expires_at <= v_now then 1
          else public.guest_rate_limits.request_count + 1
        end,
        expires_at = case
          when public.guest_rate_limits.expires_at <= v_now then v_expires_at
          else least(public.guest_rate_limits.expires_at, p_subject_expires_at)
        end
  returning request_count into v_request_count;

  return v_request_count <= v_limit;
end;
$$;

revoke all on function public.consume_guest_rate_limit(text, text, timestamptz)
from public, anon, authenticated;
grant execute on function public.consume_guest_rate_limit(text, text, timestamptz)
to service_role;

-- Replace the client-supplied invite-token publisher with an authenticated
-- boundary that derives an unpredictable 256-bit token from a Vault-protected
-- server key and persists only SHA-256. The deterministic derivation lets a
-- retry replay the same result without retaining the raw token.
revoke all on function public.publish_dilemma(
  varchar, bigint, varchar, public.item_category, public.purchase_purpose,
  text, text, text, varchar, integer, text, uuid
) from public, anon, authenticated;

do $$
begin
  if exists (
    select 1
      from public.dilemmas
     where client_idempotency_key is not null
  ) then
    raise exception
      'Cannot enable idempotent publication while legacy keyed dilemmas exist.';
  end if;

  if not exists (
    select 1
      from vault.secrets
     where name = 'before_i_buy_invite_token_hmac_key'
  ) then
    perform vault.create_secret(
      encode(extensions.gen_random_bytes(32), 'hex'),
      'before_i_buy_invite_token_hmac_key',
      'Server-only key for deterministic invite tokens on publish retries.'
    );
  end if;
end;
$$;

create unique index dilemmas_owner_idempotency_key_idx
  on public.dilemmas (owner_id, client_idempotency_key)
  where client_idempotency_key is not null;

-- Owner mutations that affect publication credentials must cross a narrow RPC.
-- SELECT and hard DELETE remain available under owner-scoped RLS.
revoke insert, update on table public.dilemmas from authenticated;

create or replace function public.publish_dilemma(
  p_item_name varchar(80),
  p_price_cents bigint,
  p_currency varchar(3),
  p_category public.item_category,
  p_purpose public.purchase_purpose,
  p_reason text,
  p_wanted_since varchar(30),
  p_pause_hours integer,
  p_client_idempotency_key uuid default null
)
returns table (
  dilemma_id uuid,
  invite_token text
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_owner_id uuid := auth.uid();
  v_dilemma_id uuid;
  v_invite_token text;
  v_invite_token_key text;
  v_pause_due_at timestamptz;
  v_follow_up public.follow_up_horizon;
  v_existing public.dilemmas%rowtype;
begin
  if v_owner_id is null then
    raise exception 'Authentication required.';
  end if;

  if not exists (
    select 1
      from public.profiles p
     where p.id = v_owner_id
       and p.is_adult_confirmed is true
       and btrim(p.terms_accepted_version) <> ''
       and btrim(p.privacy_accepted_version) <> ''
  ) then
    raise exception 'Adult confirmation and current consents are required.';
  end if;

  if p_client_idempotency_key is null then
    raise exception 'Idempotency key is required.';
  end if;

  if p_pause_hours not in (24, 72, 168) then
    raise exception 'Invalid pause window.';
  end if;

  v_pause_due_at := clock_timestamp()
    + make_interval(hours => p_pause_hours);
  v_follow_up := case
    when p_category = 'food_experiences' then '7_days'
    else '30_days'
  end;

  -- Serialize retries before checking/inserting the unique owner/key pair.
  perform pg_advisory_xact_lock(hashtextextended(
    v_owner_id::text || ':' || p_client_idempotency_key::text,
    0
  ));

  select decrypted_secret
    into v_invite_token_key
    from vault.decrypted_secrets
   where name = 'before_i_buy_invite_token_hmac_key';

  if v_invite_token_key is null
     or v_invite_token_key !~ '^[0-9a-f]{64}$' then
    raise exception 'Invite-token key is unavailable.';
  end if;

  v_invite_token := rtrim(translate(encode(extensions.hmac(
    convert_to(
      'invite-token-v1:' || v_owner_id::text || ':'
      || p_client_idempotency_key::text,
      'utf8'
    ),
    decode(v_invite_token_key, 'hex'),
    'sha256'
  ), 'base64'), '+/', '-_'), '=');

  select d.*
    into v_existing
    from public.dilemmas d
   where d.owner_id = v_owner_id
     and d.client_idempotency_key = p_client_idempotency_key;

  if found then
    if v_existing.item_name is distinct from p_item_name
       or v_existing.price_cents is distinct from p_price_cents
       or v_existing.currency is distinct from coalesce(p_currency, 'BRL')
       or v_existing.category is distinct from p_category
       or v_existing.purpose is distinct from p_purpose
       or v_existing.reason is distinct from p_reason
       or v_existing.wanted_since_bucket is distinct from p_wanted_since
       or v_existing.pause_duration_hours is distinct from p_pause_hours then
      raise exception 'Idempotency key was already used with another payload.';
    end if;

    if v_existing.invite_token_hash is distinct from encode(
      extensions.digest(v_invite_token, 'sha256'),
      'hex'
    ) then
      raise exception 'Idempotent publication credential mismatch.';
    end if;

    return query select v_existing.id, v_invite_token;
    return;
  end if;

  insert into public.dilemmas (
    owner_id,
    item_name,
    price_cents,
    currency,
    category,
    purpose,
    reason,
    wanted_since_bucket,
    pause_duration_hours,
    pause_due_at,
    planned_follow_up_horizon,
    state,
    invite_token_hash,
    client_idempotency_key
  ) values (
    v_owner_id,
    p_item_name,
    p_price_cents,
    coalesce(p_currency, 'BRL'),
    p_category,
    p_purpose,
    p_reason,
    p_wanted_since,
    p_pause_hours,
    v_pause_due_at,
    v_follow_up,
    'collecting_votes',
    encode(extensions.digest(v_invite_token, 'sha256'), 'hex'),
    p_client_idempotency_key
  )
  returning id into v_dilemma_id;

  return query select v_dilemma_id, v_invite_token;
end;
$$;

revoke all on function public.publish_dilemma(
  varchar, bigint, varchar, public.item_category, public.purchase_purpose,
  text, varchar, integer, uuid
) from public, anon;
grant execute on function public.publish_dilemma(
  varchar, bigint, varchar, public.item_category, public.purchase_purpose,
  text, varchar, integer, uuid
) to authenticated;

drop function public.open_guest_invite_session(text, text);

create or replace function public.open_guest_invite_session(
  p_invite_token_plain text,
  p_session_secret_plain text,
  p_rate_limit_key_hash text
)
returns table (
  rate_limited boolean,
  dilemma_id uuid,
  owner_display_name varchar(50),
  item_name varchar(80),
  price_cents bigint,
  currency varchar(3),
  category public.item_category,
  purpose public.purchase_purpose,
  reason text,
  pause_due_at timestamptz,
  state public.dilemma_state,
  expires_at timestamptz
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_token_hash varchar(64);
  v_session_secret_hash varchar(64);
  v_dilemma_id uuid;
  v_pause_due_at timestamptz;
  v_rate_limit_expires_at timestamptz;
  v_is_invite_revoked boolean;
  v_dilemma_state public.dilemma_state;
begin
  if p_invite_token_plain is null
     or p_session_secret_plain is null
     or p_invite_token_plain !~ '^[A-Za-z0-9_-]{43}$'
     or p_session_secret_plain !~ '^[A-Za-z0-9_-]{43}$'
     or p_rate_limit_key_hash !~ '^[0-9a-f]{64}$' then
    return;
  end if;

  v_token_hash := encode(
    extensions.digest(p_invite_token_plain, 'sha256'),
    'hex'
  );
  v_session_secret_hash := encode(
    extensions.digest(p_session_secret_plain, 'sha256'),
    'hex'
  );

  -- Count valid-format attempts even when the token does not resolve. For a
  -- known invite, keep the pseudonymous counter no longer than its deadline.
  select d.pause_due_at
    into v_rate_limit_expires_at
    from public.dilemmas d
   where d.invite_token_hash = v_token_hash
     and d.is_invite_revoked is false
     and d.state = 'collecting_votes'
     and d.pause_due_at > clock_timestamp();

  v_rate_limit_expires_at := coalesce(
    v_rate_limit_expires_at,
    clock_timestamp() + interval '60 seconds'
  );

  if not public.consume_guest_rate_limit(
    'invite_open',
    p_rate_limit_key_hash,
    v_rate_limit_expires_at
  ) then
    return query select
      true,
      null::uuid,
      null::varchar(50),
      null::varchar(80),
      null::bigint,
      null::varchar(3),
      null::public.item_category,
      null::public.purchase_purpose,
      null::text,
      null::timestamptz,
      null::public.dilemma_state,
      null::timestamptz;
    return;
  end if;

  select d.id, d.pause_due_at, d.is_invite_revoked, d.state
    into v_dilemma_id, v_pause_due_at, v_is_invite_revoked, v_dilemma_state
    from public.dilemmas d
   where d.invite_token_hash = v_token_hash
   for update;

  if not found
     or v_is_invite_revoked is true
     or v_dilemma_state <> 'collecting_votes'
     or v_pause_due_at <= clock_timestamp() then
    return;
  end if;

  insert into public.guest_access_sessions (
    dilemma_id,
    session_secret_hash,
    expires_at
  ) values (
    v_dilemma_id,
    v_session_secret_hash,
    v_pause_due_at
  )
  on conflict (session_secret_hash) do update
    set last_seen_at = clock_timestamp()
  where public.guest_access_sessions.dilemma_id = excluded.dilemma_id
    and public.guest_access_sessions.revoked_at is null
    and public.guest_access_sessions.expires_at > clock_timestamp();

  if not found and not exists (
    select 1
      from public.guest_access_sessions gas
     where gas.dilemma_id = v_dilemma_id
       and gas.session_secret_hash = v_session_secret_hash
       and gas.revoked_at is null
       and gas.expires_at > clock_timestamp()
  ) then
    return;
  end if;

  return query
  select
    false,
    d.id,
    p.display_name,
    d.item_name,
    d.price_cents,
    d.currency,
    d.category,
    d.purpose,
    d.reason,
    d.pause_due_at,
    d.state,
    v_pause_due_at
  from public.dilemmas d
  join public.profiles p on p.id = d.owner_id
  where d.id = v_dilemma_id
    and d.is_invite_revoked is false
    and d.state = 'collecting_votes'
    and d.pause_due_at > clock_timestamp();
end;
$$;

revoke all on function public.open_guest_invite_session(text, text, text)
from public, anon, authenticated;
grant execute on function public.open_guest_invite_session(text, text, text)
to service_role;

create or replace function public.submit_guest_vote(
  p_dilemma_id uuid,
  p_session_secret_plain text,
  p_prediction public.vote_prediction,
  p_rate_limit_key_hash text
)
returns table (
  rate_limited boolean,
  prediction public.vote_prediction,
  changed boolean,
  buy_count bigint,
  wait_count bigint,
  skip_count bigint,
  total_votes bigint
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_session_hash varchar(64);
  v_session_id uuid;
  v_dilemma_pause_due_at timestamptz;
  v_participation_id uuid;
  v_previous_prediction public.vote_prediction;
  v_is_invite_revoked boolean;
  v_dilemma_state public.dilemma_state;
  v_changed boolean := false;
  v_buy_count bigint;
  v_wait_count bigint;
  v_skip_count bigint;
  v_total_votes bigint;
begin
  if p_dilemma_id is null
     or p_session_secret_plain is null
     or length(p_session_secret_plain) < 43
     or length(p_session_secret_plain) > 512
     or p_prediction is null
     or p_rate_limit_key_hash !~ '^[0-9a-f]{64}$' then
    return;
  end if;

  v_session_hash := encode(
    extensions.digest(p_session_secret_plain, 'sha256'),
    'hex'
  );

  -- This row lock serializes voting with owner revocation. The conditions are
  -- re-evaluated after waiting for a concurrent owner mutation.
  select d.pause_due_at, d.is_invite_revoked, d.state
    into v_dilemma_pause_due_at, v_is_invite_revoked, v_dilemma_state
    from public.dilemmas d
   where d.id = p_dilemma_id
   for update;

  if not found
     or v_is_invite_revoked is true
     or v_dilemma_state <> 'collecting_votes'
     or v_dilemma_pause_due_at <= clock_timestamp() then
    return;
  end if;

  -- Count valid-format session attempts before revealing whether the cookie
  -- resolves. This also limits repeated forged/cross-dilemma sessions.
  if not public.consume_guest_rate_limit(
    'guest_vote',
    p_rate_limit_key_hash,
    v_dilemma_pause_due_at
  ) then
    return query select
      true,
      null::public.vote_prediction,
      false,
      0::bigint,
      0::bigint,
      0::bigint,
      0::bigint;
    return;
  end if;

  select gas.id
    into v_session_id
    from public.guest_access_sessions gas
   where gas.dilemma_id = p_dilemma_id
     and gas.session_secret_hash = v_session_hash
     and gas.revoked_at is null
     and gas.expires_at > clock_timestamp()
   for update;

  if not found then
    return;
  end if;

  update public.guest_access_sessions
     set last_seen_at = clock_timestamp()
   where id = v_session_id;

  select p.id
    into v_participation_id
    from public.participations p
   where p.dilemma_id = p_dilemma_id
     and p.guest_session_id = v_session_id
   for update;

  if not found then
    insert into public.participations (
      dilemma_id,
      user_id,
      guest_session_id,
      display_name
    ) values (
      p_dilemma_id,
      null,
      v_session_id,
      null
    )
    returning id into v_participation_id;
  end if;

  select v.prediction
    into v_previous_prediction
    from public.votes v
   where v.participation_id = v_participation_id
   for update;

  if found then
    v_changed := v_previous_prediction is distinct from p_prediction;
    if v_changed then
      update public.votes
         set prediction = p_prediction
       where participation_id = v_participation_id;
    end if;
  else
    insert into public.votes (
      participation_id,
      prediction,
      reason
    ) values (
      v_participation_id,
      p_prediction,
      null
    );
  end if;

  select
    count(*) filter (where v.prediction = 'buy'),
    count(*) filter (where v.prediction = 'wait'),
    count(*) filter (where v.prediction = 'skip'),
    count(*)
    into v_buy_count, v_wait_count, v_skip_count, v_total_votes
    from public.votes v
    join public.participations p on p.id = v.participation_id
   where p.dilemma_id = p_dilemma_id;

  return query
  select
    false,
    p_prediction,
    v_changed,
    v_buy_count,
    v_wait_count,
    v_skip_count,
    v_total_votes;
end;
$$;

revoke all on function public.submit_guest_vote(
  uuid,
  text,
  public.vote_prediction,
  text
) from public, anon, authenticated;

grant execute on function public.submit_guest_vote(
  uuid,
  text,
  public.vote_prediction,
  text
) to service_role;
