-- Replaces the invite-opening projection with a final active-invite check.
-- This keeps a concurrent revocation from returning an already-invalid invite.

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
  where d.id = v_dilemma_id
    and d.is_invite_revoked is false
    and d.state = 'collecting_votes'
    and d.pause_due_at > now();
end;
$$;

revoke all on function public.open_guest_invite_session(text, text)
from public, anon, authenticated;
grant execute on function public.open_guest_invite_session(text, text)
to service_role;
