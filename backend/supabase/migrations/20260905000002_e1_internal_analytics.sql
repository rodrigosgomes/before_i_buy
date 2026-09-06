-- Entrega 1 internal analytics. The store is deliberately outside the exposed
-- API schema and accepts only the eleven events allowlisted by the mini-PRD.

create schema if not exists private;
revoke all on schema private from public, anon, authenticated, service_role;

do $$
begin
  if not exists (
    select 1 from vault.secrets where name = 'before_i_buy_analytics_hmac_key'
  ) then
    perform vault.create_secret(
      encode(extensions.gen_random_bytes(32), 'hex'),
      'before_i_buy_analytics_hmac_key',
      'Server-only key for pseudonymous internal product analytics.'
    );
  end if;
end;
$$;

create table private.e1_analytics_events (
  id uuid primary key default extensions.gen_random_uuid(),
  event_name text not null,
  schema_version smallint not null default 1,
  deduplication_key varchar(64) not null unique,
  occurred_at timestamptz not null,
  recorded_at timestamptz not null default clock_timestamp(),
  subject_key varchar(64),
  draft_key varchar(64),
  dilemma_key varchar(64),
  guest_session_key varchar(64),
  category public.item_category,
  purpose public.purchase_purpose,
  currency varchar(3),
  price_band text,
  pause_duration_hours integer,
  prediction public.vote_prediction,
  constraint e1_analytics_event_name_check check (event_name in (
    'dilemma_create_started',
    'dilemma_draft_saved',
    'offline_draft_recovered',
    'offline_draft_publish_reviewed',
    'dilemma_published',
    'dilemma_share_invoked',
    'invite_opened',
    'vote_submitted',
    'vote_changed',
    'invite_link_revoked',
    'dilemma_deleted'
  )),
  constraint e1_analytics_schema_version_check check (schema_version = 1),
  constraint e1_analytics_hashes_check check (
    (subject_key is null or subject_key ~ '^[0-9a-f]{64}$') and
    (draft_key is null or draft_key ~ '^[0-9a-f]{64}$') and
    (dilemma_key is null or dilemma_key ~ '^[0-9a-f]{64}$') and
    (guest_session_key is null or guest_session_key ~ '^[0-9a-f]{64}$')
  ),
  constraint e1_analytics_currency_check check (
    currency is null or currency = 'BRL'
  ),
  constraint e1_analytics_price_band_check check (
    price_band is null or price_band in (
      'under_100', '100_to_499', '500_to_1999', '2000_plus'
    )
  ),
  constraint e1_analytics_pause_check check (
    pause_duration_hours is null or pause_duration_hours in (24, 72, 168)
  )
);

alter table private.e1_analytics_events enable row level security;
revoke all on table private.e1_analytics_events
from public, anon, authenticated, service_role;

create index e1_analytics_events_occurred_at_idx
  on private.e1_analytics_events (occurred_at);
create index e1_analytics_events_name_occurred_idx
  on private.e1_analytics_events (event_name, occurred_at);
create index e1_analytics_events_dilemma_idx
  on private.e1_analytics_events (dilemma_key, occurred_at)
  where dilemma_key is not null;

create table private.e1_analytics_rate_limits (
  subject_key varchar(64) not null,
  window_started_at timestamptz not null,
  event_count integer not null check (event_count between 1 and 120),
  primary key (subject_key, window_started_at)
);
alter table private.e1_analytics_rate_limits enable row level security;
revoke all on table private.e1_analytics_rate_limits
from public, anon, authenticated, service_role;

create or replace function private.e1_analytics_pseudonym(p_value text)
returns varchar(64)
language plpgsql
stable
security definer
set search_path = private, vault, extensions, pg_catalog
as $$
declare
  v_key text;
begin
  if p_value is null or btrim(p_value) = '' then
    return null;
  end if;

  select decrypted_secret into v_key
    from vault.decrypted_secrets
   where name = 'before_i_buy_analytics_hmac_key';

  if v_key is null or v_key !~ '^[0-9a-f]{64}$' then
    raise exception 'Analytics pseudonym key is unavailable.';
  end if;

  return encode(extensions.hmac(
    convert_to('e1-analytics-v1:' || p_value, 'utf8'),
    decode(v_key, 'hex'),
    'sha256'
  ), 'hex');
end;
$$;

revoke all on function private.e1_analytics_pseudonym(text)
from public, anon, authenticated, service_role;

create or replace function private.record_e1_analytics_event(
  p_event_name text,
  p_deduplication_value text,
  p_occurred_at timestamptz,
  p_subject_value text default null,
  p_draft_value text default null,
  p_dilemma_value text default null,
  p_guest_session_value text default null,
  p_category public.item_category default null,
  p_purpose public.purchase_purpose default null,
  p_currency varchar default null,
  p_price_cents bigint default null,
  p_pause_duration_hours integer default null,
  p_prediction public.vote_prediction default null
)
returns void
language plpgsql
security definer
set search_path = private, public, pg_catalog
as $$
begin
  if p_event_name not in (
    'dilemma_create_started', 'dilemma_draft_saved',
    'offline_draft_recovered', 'offline_draft_publish_reviewed',
    'dilemma_published', 'dilemma_share_invoked', 'invite_opened',
    'vote_submitted', 'vote_changed', 'invite_link_revoked',
    'dilemma_deleted'
  ) then
    raise exception 'Analytics event is not allowlisted.';
  end if;

  if p_deduplication_value is null or btrim(p_deduplication_value) = '' then
    raise exception 'Analytics deduplication value is required.';
  end if;

  insert into private.e1_analytics_events (
    event_name, deduplication_key, occurred_at, subject_key, draft_key,
    dilemma_key, guest_session_key, category, purpose, currency, price_band,
    pause_duration_hours, prediction
  ) values (
    p_event_name,
    private.e1_analytics_pseudonym('dedupe:' || p_event_name || ':' || p_deduplication_value),
    coalesce(p_occurred_at, clock_timestamp()),
    private.e1_analytics_pseudonym('subject:' || p_subject_value),
    private.e1_analytics_pseudonym('draft:' || p_draft_value),
    private.e1_analytics_pseudonym('dilemma:' || p_dilemma_value),
    private.e1_analytics_pseudonym('guest-session:' || p_guest_session_value),
    p_category,
    p_purpose,
    case when p_currency = 'BRL' then 'BRL' else null end,
    case
      when p_price_cents is null then null
      when p_price_cents < 10000 then 'under_100'
      when p_price_cents < 50000 then '100_to_499'
      when p_price_cents < 200000 then '500_to_1999'
      else '2000_plus'
    end,
    p_pause_duration_hours,
    p_prediction
  )
  on conflict (deduplication_key) do nothing;
end;
$$;

revoke all on function private.record_e1_analytics_event(
  text, text, timestamptz, text, text, text, text,
  public.item_category, public.purchase_purpose, varchar, bigint, integer,
  public.vote_prediction
) from public, anon, authenticated, service_role;

create or replace function public.record_creator_analytics_event(
  p_event_name text,
  p_client_event_id uuid,
  p_draft_id uuid default null,
  p_dilemma_id uuid default null,
  p_occurred_at timestamptz default null
)
returns void
language plpgsql
security definer
set search_path = public, private, pg_catalog
as $$
declare
  v_owner_id uuid := auth.uid();
  v_dilemma public.dilemmas%rowtype;
  v_rate_count integer;
begin
  if v_owner_id is null then
    raise exception 'Authentication required.' using errcode = '42501';
  end if;
  if p_client_event_id is null then
    raise exception 'Client event ID is required.';
  end if;
  if p_occurred_at is not null and (
    p_occurred_at < clock_timestamp() - interval '7 days' or
    p_occurred_at > clock_timestamp() + interval '5 minutes'
  ) then
    raise exception 'Event timestamp is outside the accepted window.';
  end if;

  insert into private.e1_analytics_rate_limits (
    subject_key, window_started_at, event_count
  ) values (
    private.e1_analytics_pseudonym('subject:' || v_owner_id::text),
    date_trunc('hour', clock_timestamp()), 1
  )
  on conflict (subject_key, window_started_at) do update
    set event_count = private.e1_analytics_rate_limits.event_count + 1
    where private.e1_analytics_rate_limits.event_count < 120
  returning event_count into v_rate_count;
  if v_rate_count is null then
    raise exception 'Analytics rate limit exceeded.' using errcode = 'P0001';
  end if;

  if p_event_name = 'dilemma_share_invoked' then
    select d.* into v_dilemma
      from public.dilemmas d
     where d.id = p_dilemma_id and d.owner_id = v_owner_id;
    if not found then
      raise exception 'Dilemma not found or unauthorized.' using errcode = 'P0002';
    end if;
    perform private.record_e1_analytics_event(
      p_event_name, p_client_event_id::text,
      coalesce(p_occurred_at, clock_timestamp()), v_owner_id::text,
      v_dilemma.client_idempotency_key::text, v_dilemma.id::text, null,
      v_dilemma.category, v_dilemma.purpose, v_dilemma.currency,
      v_dilemma.price_cents, v_dilemma.pause_duration_hours, null
    );
  elsif p_event_name in (
    'dilemma_create_started', 'dilemma_draft_saved',
    'offline_draft_recovered', 'offline_draft_publish_reviewed'
  ) then
    if p_draft_id is null or p_dilemma_id is not null then
      raise exception 'A local draft event requires only a draft ID.';
    end if;
    perform private.record_e1_analytics_event(
      p_event_name, p_client_event_id::text,
      coalesce(p_occurred_at, clock_timestamp()), v_owner_id::text,
      p_draft_id::text
    );
  else
    raise exception 'Event is not accepted from the creator client.';
  end if;
end;
$$;

revoke all on function public.record_creator_analytics_event(
  text, uuid, uuid, uuid, timestamptz
) from public, anon, service_role;
grant execute on function public.record_creator_analytics_event(
  text, uuid, uuid, uuid, timestamptz
) to authenticated;

create or replace function private.capture_dilemma_analytics()
returns trigger
language plpgsql
security definer
set search_path = private, public, pg_catalog
as $$
begin
  if tg_op = 'INSERT' then
    perform private.record_e1_analytics_event(
      'dilemma_published', new.id::text, new.created_at, new.owner_id::text,
      new.client_idempotency_key::text, new.id::text, null, new.category,
      new.purpose, new.currency, new.price_cents, new.pause_duration_hours, null
    );
    return new;
  elsif tg_op = 'UPDATE' and old.is_invite_revoked is false
        and new.is_invite_revoked is true then
    perform private.record_e1_analytics_event(
      'invite_link_revoked', new.id::text, clock_timestamp(), new.owner_id::text,
      new.client_idempotency_key::text, new.id::text, null, new.category,
      new.purpose, new.currency, new.price_cents, new.pause_duration_hours, null
    );
    return new;
  elsif tg_op = 'DELETE' then
    perform private.record_e1_analytics_event(
      'dilemma_deleted', old.id::text, clock_timestamp(), old.owner_id::text,
      old.client_idempotency_key::text, old.id::text, null, old.category,
      old.purpose, old.currency, old.price_cents, old.pause_duration_hours, null
    );
    return old;
  end if;
  return coalesce(new, old);
end;
$$;

create trigger capture_dilemma_analytics
after insert or update of is_invite_revoked or delete on public.dilemmas
for each row execute function private.capture_dilemma_analytics();

create or replace function private.capture_guest_session_analytics()
returns trigger
language plpgsql
security definer
set search_path = private, public, pg_catalog
as $$
declare
  v_dilemma public.dilemmas%rowtype;
begin
  select d.* into v_dilemma from public.dilemmas d where d.id = new.dilemma_id;
  perform private.record_e1_analytics_event(
    'invite_opened', new.id::text, new.created_at, v_dilemma.owner_id::text,
    v_dilemma.client_idempotency_key::text, v_dilemma.id::text, new.id::text,
    v_dilemma.category, v_dilemma.purpose, v_dilemma.currency,
    v_dilemma.price_cents, v_dilemma.pause_duration_hours, null
  );
  return new;
end;
$$;

create trigger capture_guest_session_analytics
after insert on public.guest_access_sessions
for each row execute function private.capture_guest_session_analytics();

create or replace function private.capture_vote_analytics()
returns trigger
language plpgsql
security definer
set search_path = private, public, pg_catalog
as $$
declare
  v_participation public.participations%rowtype;
  v_dilemma public.dilemmas%rowtype;
  v_event_name text;
  v_dedupe text;
begin
  if tg_op = 'UPDATE' and old.prediction is not distinct from new.prediction then
    return new;
  end if;

  select p.* into v_participation
    from public.participations p where p.id = new.participation_id;
  if v_participation.guest_session_id is null then
    return new;
  end if;
  select d.* into v_dilemma
    from public.dilemmas d where d.id = v_participation.dilemma_id;

  v_event_name := case when tg_op = 'INSERT' then 'vote_submitted' else 'vote_changed' end;
  v_dedupe := case when tg_op = 'INSERT' then new.id::text
    else new.id::text || ':' || txid_current()::text end;
  perform private.record_e1_analytics_event(
    v_event_name, v_dedupe,
    case when tg_op = 'INSERT' then new.created_at else new.updated_at end,
    v_dilemma.owner_id::text, v_dilemma.client_idempotency_key::text,
    v_dilemma.id::text, v_participation.guest_session_id::text,
    v_dilemma.category, v_dilemma.purpose, v_dilemma.currency,
    v_dilemma.price_cents, v_dilemma.pause_duration_hours, new.prediction
  );
  return new;
end;
$$;

create trigger capture_vote_analytics
after insert or update of prediction on public.votes
for each row execute function private.capture_vote_analytics();

create view private.e1_event_funnel_daily
with (security_invoker = true)
as
select occurred_at::date as event_date, event_name, count(*)::bigint as event_count
from private.e1_analytics_events
group by occurred_at::date, event_name;

create view private.e1_usability_daily
with (security_invoker = true)
as
with creation_times as (
  select p.occurred_at::date as event_date,
         extract(epoch from (p.occurred_at - s.occurred_at)) as seconds
    from private.e1_analytics_events p
    join private.e1_analytics_events s using (draft_key)
   where p.event_name = 'dilemma_published'
     and s.event_name = 'dilemma_create_started'
     and p.occurred_at >= s.occurred_at
), vote_times as (
  select v.occurred_at::date as event_date,
         extract(epoch from (v.occurred_at - o.occurred_at)) as seconds
    from private.e1_analytics_events v
    join private.e1_analytics_events o using (guest_session_key)
   where v.event_name = 'vote_submitted'
     and o.event_name = 'invite_opened'
     and v.occurred_at >= o.occurred_at
), dates as (
  select event_date from creation_times union select event_date from vote_times
)
select d.event_date,
  (select percentile_cont(0.5) within group (order by seconds)
     from creation_times c where c.event_date = d.event_date) as median_creation_seconds,
  (select percentile_cont(0.5) within group (order by seconds)
     from vote_times v where v.event_date = d.event_date) as median_vote_seconds
from dates d;

create view private.e1_delivery_dashboard
with (security_invoker = true)
as
with per_dilemma as (
  select dilemma_key,
    min(occurred_at) filter (where event_name = 'dilemma_published') as published_at,
    count(*) filter (
      where event_name = 'vote_submitted'
        and occurred_at <= (
          select min(e2.occurred_at) + interval '24 hours'
          from private.e1_analytics_events e2
          where e2.dilemma_key = e1.dilemma_key
            and e2.event_name = 'dilemma_published'
        )
    ) as votes_in_24h
  from private.e1_analytics_events e1
  where dilemma_key is not null
  group by dilemma_key
)
select
  (select count(*) from private.e1_analytics_events
    where event_name = 'dilemma_published')::bigint as published_dilemmas,
  (select count(*) from private.e1_analytics_events
    where event_name = 'invite_opened')::bigint as eligible_visits,
  (select count(*) from private.e1_analytics_events
    where event_name = 'vote_submitted')::bigint as submitted_votes,
  (select count(*) from per_dilemma where votes_in_24h >= 2)::bigint
    as dilemmas_with_two_votes_in_24h,
  round(100.0 * (select count(*) from private.e1_analytics_events
    where event_name = 'vote_submitted') /
    nullif((select count(*) from private.e1_analytics_events
      where event_name = 'invite_opened'), 0), 2) as vote_conversion_percent,
  round(100.0 * (select count(*) from per_dilemma where votes_in_24h >= 2) /
    nullif((select count(*) from per_dilemma where published_at is not null), 0), 2)
    as liquidity_percent,
  round(100.0 * (
    select count(distinct published.subject_key)
      from private.e1_analytics_events published
      join auth.users creator
        on published.subject_key = private.e1_analytics_pseudonym(
          'subject:' || creator.id::text
        )
     where published.event_name = 'dilemma_published'
       and published.occurred_at <= creator.created_at + interval '7 days'
  ) / nullif((select count(*) from auth.users), 0), 2)
    as creator_activation_7d_percent,
  (select count(distinct changed.dilemma_key) from private.e1_analytics_events changed
    join private.e1_analytics_events published using (dilemma_key)
   where changed.event_name in ('invite_link_revoked', 'dilemma_deleted')
     and published.event_name = 'dilemma_published'
     and changed.occurred_at <= published.occurred_at + interval '10 minutes')::bigint
    as revoked_or_deleted_within_10m;

revoke all on private.e1_event_funnel_daily,
  private.e1_usability_daily, private.e1_delivery_dashboard
from public, anon, authenticated, service_role;

create or replace function private.purge_expired_e1_analytics_events()
returns integer
language plpgsql
set search_path = private, pg_catalog
as $$
declare
  v_count integer;
begin
  delete from private.e1_analytics_events
   where recorded_at < clock_timestamp() - interval '13 months';
  get diagnostics v_count = row_count;
  delete from private.e1_analytics_rate_limits
   where window_started_at < clock_timestamp() - interval '2 hours';
  return v_count;
end;
$$;

revoke all on function private.purge_expired_e1_analytics_events()
from public, anon, authenticated, service_role;

do $$
declare
  v_job_id bigint;
begin
  if not exists (select 1 from pg_extension where extname = 'pg_cron') then
    raise exception 'pg_cron is required for E1 analytics retention.';
  end if;
  select jobid into v_job_id from cron.job
   where jobname = 'purge-e1-analytics-events';
  if v_job_id is null then
    perform cron.schedule(
      'purge-e1-analytics-events', '17 3 * * *',
      'select private.purge_expired_e1_analytics_events();'
    );
  else
    perform cron.alter_job(
      job_id := v_job_id,
      schedule := '17 3 * * *',
      command := 'select private.purge_expired_e1_analytics_events();',
      active := true
    );
  end if;
end;
$$;
