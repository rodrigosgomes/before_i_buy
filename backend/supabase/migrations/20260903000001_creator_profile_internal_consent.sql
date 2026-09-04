-- Task 3B: narrow creator-profile persistence for the development project.
-- The internal-demo version is not a legal document and must be disabled before
-- any external beta or production promotion (DEC-015).

create table if not exists public.creator_consent_versions (
  document_kind text not null,
  version varchar(20) not null,
  is_active boolean not null default false,
  is_internal_demo boolean not null default false,
  primary key (document_kind, version),
  constraint creator_consent_versions_document_kind_check
    check (document_kind in ('terms', 'privacy')),
  constraint creator_consent_versions_version_check
    check (btrim(version) <> '')
);

alter table public.creator_consent_versions enable row level security;
revoke all on table public.creator_consent_versions
from public, anon, authenticated;
grant select on table public.creator_consent_versions to service_role;

insert into public.creator_consent_versions (
  document_kind,
  version,
  is_active,
  is_internal_demo
) values
  ('terms', 'internal-demo-v1', true, true),
  ('privacy', 'internal-demo-v1', true, true)
on conflict (document_kind, version) do update
  set is_active = excluded.is_active,
      is_internal_demo = excluded.is_internal_demo;

alter table public.profiles
  alter column display_name type varchar(80);

alter table public.profiles
  drop constraint if exists profiles_display_name_length;

alter table public.profiles
  add constraint profiles_display_name_length
  check (char_length(btrim(display_name)) between 2 and 50);

-- A client may read its own profile under RLS, but profile creation and updates
-- must pass through the RPC below so it cannot fabricate consent versions.
revoke insert, update on table public.profiles from authenticated;

create or replace function public.creator_profile_has_active_consents(
  p_terms_version varchar,
  p_privacy_version varchar
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
      from public.creator_consent_versions v
     where v.document_kind = 'terms'
       and v.version = p_terms_version
       and v.is_active
  )
  and exists (
    select 1
      from public.creator_consent_versions v
     where v.document_kind = 'privacy'
       and v.version = p_privacy_version
       and v.is_active
  );
$$;

revoke all on function public.creator_profile_has_active_consents(varchar, varchar)
from public, anon, authenticated;

create or replace function public.upsert_creator_profile(
  p_display_name varchar(80),
  p_is_adult_confirmed boolean,
  p_terms_accepted boolean,
  p_privacy_accepted boolean
)
returns table (
  display_name varchar(80),
  is_adult_confirmed boolean,
  terms_accepted_version varchar(20),
  privacy_accepted_version varchar(20)
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owner_id uuid := auth.uid();
  v_terms_version varchar(20) := 'internal-demo-v1';
  v_privacy_version varchar(20) := 'internal-demo-v1';
begin
  if v_owner_id is null then
    raise exception 'Authentication required.';
  end if;

  if char_length(btrim(coalesce(p_display_name, ''))) not between 2 and 50 then
    raise exception 'Display name must contain 2 to 50 characters.';
  end if;

  if p_is_adult_confirmed is not true
     or p_terms_accepted is not true
     or p_privacy_accepted is not true then
    raise exception 'Adult confirmation and both internal acknowledgements are required.';
  end if;

  if not exists (
    select 1
      from public.creator_consent_versions v
     where v.document_kind = 'terms'
       and v.version = v_terms_version
       and v.is_active
       and v.is_internal_demo
  ) or not exists (
    select 1
      from public.creator_consent_versions v
     where v.document_kind = 'privacy'
       and v.version = v_privacy_version
       and v.is_active
       and v.is_internal_demo
  ) then
    raise exception 'The internal development consent version is unavailable.';
  end if;

  insert into public.profiles (
    id,
    display_name,
    is_adult_confirmed,
    terms_accepted_version,
    privacy_accepted_version
  ) values (
    v_owner_id,
    btrim(p_display_name),
    true,
    v_terms_version,
    v_privacy_version
  )
  on conflict (id) do update
    set display_name = excluded.display_name,
        is_adult_confirmed = true,
        terms_accepted_version = excluded.terms_accepted_version,
        privacy_accepted_version = excluded.privacy_accepted_version
  returning
    profiles.display_name,
    profiles.is_adult_confirmed,
    profiles.terms_accepted_version,
    profiles.privacy_accepted_version
  into
    display_name,
    is_adult_confirmed,
    terms_accepted_version,
    privacy_accepted_version;

  return next;
end;
$$;

revoke all on function public.upsert_creator_profile(varchar, boolean, boolean, boolean)
from public, anon;
grant execute on function public.upsert_creator_profile(varchar, boolean, boolean, boolean)
to authenticated;

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
       and public.creator_profile_has_active_consents(
         p.terms_accepted_version,
         p.privacy_accepted_version
       )
  ) then
    raise exception 'Adult confirmation and active consent versions are required.';
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
