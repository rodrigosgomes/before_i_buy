-- =============================================================================
-- Migration: guest session and RLS foundation for the closed-loop MVP
-- Scope: remove direct guest data access, isolate owner records, and expose
--        invite data only through service-role RPCs used by the Edge Function.
-- =============================================================================

create table if not exists public.guest_access_sessions (
  id uuid primary key default gen_random_uuid(),
  dilemma_id uuid not null references public.dilemmas(id) on delete cascade,
  session_secret_hash varchar(64) not null unique,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  revoked_at timestamptz,
  last_seen_at timestamptz not null default now(),
  constraint guest_access_sessions_expires_after_creation
    check (expires_at > created_at)
);

create index if not exists idx_guest_access_sessions_active_dilemma
  on public.guest_access_sessions (dilemma_id, expires_at)
  where revoked_at is null;

alter table public.guest_access_sessions enable row level security;

-- No client role may query product data directly. Future guest operations must
-- be introduced through narrowly scoped RPCs after their own RLS tests exist.
revoke all on table
  public.profiles,
  public.dilemmas,
  public.owner_expectations,
  public.participations,
  public.votes,
  public.decisions,
  public.reflections,
  public.guest_reveal_subscriptions,
  public.outbox_jobs,
  public.reports,
  public.guest_access_sessions
from public, anon, authenticated;

grant all on table
  public.profiles,
  public.dilemmas,
  public.owner_expectations,
  public.participations,
  public.votes,
  public.decisions,
  public.reflections,
  public.guest_reveal_subscriptions,
  public.outbox_jobs,
  public.reports,
  public.guest_access_sessions
to service_role;

grant select, insert, update, delete on table public.profiles to authenticated;
grant select, insert, update, delete on table public.dilemmas to authenticated;
grant select, insert, update, delete on table public.owner_expectations to authenticated;

drop policy if exists profiles_select_authenticated on public.profiles;
drop policy if exists profiles_insert_own on public.profiles;
drop policy if exists profiles_update_own on public.profiles;
drop policy if exists profiles_delete_own on public.profiles;
drop policy if exists dilemmas_owner_all on public.dilemmas;
drop policy if exists dilemmas_select_by_invite_or_participant on public.dilemmas;
drop policy if exists owner_expectations_owner_only on public.owner_expectations;
drop policy if exists participations_select_owner on public.participations;
drop policy if exists participations_select_self on public.participations;
drop policy if exists participations_insert_authenticated on public.participations;
drop policy if exists participations_insert_anon on public.participations;
drop policy if exists votes_select_owner on public.votes;
drop policy if exists votes_select_self on public.votes;
drop policy if exists votes_insert_authenticated on public.votes;
drop policy if exists votes_insert_anon on public.votes;
drop policy if exists decisions_select_participants on public.decisions;
drop policy if exists reflections_select_reveal on public.reflections;
drop policy if exists guest_subs_insert on public.guest_reveal_subscriptions;
drop policy if exists guest_subs_select_self on public.guest_reveal_subscriptions;
drop policy if exists reports_insert_public on public.reports;

create policy profiles_select_own
on public.profiles for select to authenticated
using (id = auth.uid());

create policy profiles_insert_own
on public.profiles for insert to authenticated
with check (id = auth.uid());

create policy profiles_update_own
on public.profiles for update to authenticated
using (id = auth.uid())
with check (id = auth.uid());

create policy profiles_delete_own
on public.profiles for delete to authenticated
using (id = auth.uid());

create policy dilemmas_owner_all
on public.dilemmas for all to authenticated
using (owner_id = auth.uid())
with check (owner_id = auth.uid());

create policy owner_expectations_owner_only
on public.owner_expectations for all to authenticated
using (owner_id = auth.uid())
with check (owner_id = auth.uid());

-- The legacy RPC leaked vote totals and optional media URLs. It is removed
-- before any guest flow is connected to a client.
drop function if exists public.exchange_invite_token(text);

create or replace function public.open_guest_invite_session(
  p_invite_token_plain text,
  p_session_secret_plain text
)
returns table (
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
begin
  if p_invite_token_plain is null
     or p_session_secret_plain is null
     or length(p_invite_token_plain) < 16
     or length(p_session_secret_plain) < 43 then
    return;
  end if;

  v_token_hash := encode(extensions.digest(p_invite_token_plain, 'sha256'), 'hex');
  v_session_secret_hash := encode(extensions.digest(p_session_secret_plain, 'sha256'), 'hex');

  select d.id, d.pause_due_at
    into v_dilemma_id, v_pause_due_at
    from public.dilemmas d
   where d.invite_token_hash = v_token_hash
     and d.is_invite_revoked is false
     and d.state = 'collecting_votes'
     and d.pause_due_at > now();

  if not found then
    return;
  end if;

  insert into public.guest_access_sessions (
    dilemma_id,
    session_secret_hash,
    expires_at
  )
  values (
    v_dilemma_id,
    v_session_secret_hash,
    v_pause_due_at
  )
  on conflict (session_secret_hash) do update
    set last_seen_at = now()
  where public.guest_access_sessions.dilemma_id = excluded.dilemma_id
    and public.guest_access_sessions.revoked_at is null
    and public.guest_access_sessions.expires_at > now();

  if not found and not exists (
    select 1
      from public.guest_access_sessions gas
     where gas.dilemma_id = v_dilemma_id
       and gas.session_secret_hash = v_session_secret_hash
       and gas.revoked_at is null
       and gas.expires_at > now()
  ) then
    return;
  end if;

  return query
  select
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
  where d.id = v_dilemma_id;
end;
$$;

create or replace function public.get_guest_invite_session(
  p_dilemma_id uuid,
  p_session_secret_plain text
)
returns table (
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
  v_session_secret_hash varchar(64);
  v_expires_at timestamptz;
begin
  if p_dilemma_id is null
     or p_session_secret_plain is null
     or length(p_session_secret_plain) < 43 then
    return;
  end if;

  v_session_secret_hash := encode(extensions.digest(p_session_secret_plain, 'sha256'), 'hex');

  update public.guest_access_sessions gas
     set last_seen_at = now()
   where gas.dilemma_id = p_dilemma_id
     and gas.session_secret_hash = v_session_secret_hash
     and gas.revoked_at is null
     and gas.expires_at > now()
   returning gas.expires_at into v_expires_at;

  if not found then
    return;
  end if;

  return query
  select
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
    v_expires_at
  from public.dilemmas d
  join public.profiles p on p.id = d.owner_id
  where d.id = p_dilemma_id
    and d.is_invite_revoked is false
    and d.state = 'collecting_votes'
    and d.pause_due_at > now();
end;
$$;

revoke all on function public.publish_dilemma(
  varchar, bigint, varchar, public.item_category, public.purchase_purpose,
  text, text, text, varchar, integer, text, uuid
) from public, anon;
grant execute on function public.publish_dilemma(
  varchar, bigint, varchar, public.item_category, public.purchase_purpose,
  text, text, text, varchar, integer, text, uuid
) to authenticated;

revoke all on function public.record_decision(
  uuid, public.decision_type, varchar, text
) from public, anon;
grant execute on function public.record_decision(
  uuid, public.decision_type, varchar, text
) to authenticated;

revoke all on function public.record_reflection(
  uuid, public.satisfaction_outcome, text, boolean
) from public, anon;
grant execute on function public.record_reflection(
  uuid, public.satisfaction_outcome, text, boolean
) to authenticated;

revoke all on function public.open_guest_invite_session(text, text)
from public, anon, authenticated;
grant execute on function public.open_guest_invite_session(text, text)
to service_role;

revoke all on function public.get_guest_invite_session(uuid, text)
from public, anon, authenticated;
grant execute on function public.get_guest_invite_session(uuid, text)
to service_role;
