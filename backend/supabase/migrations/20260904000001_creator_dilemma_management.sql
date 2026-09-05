-- Creator dilemma management slice: aggregates query, invite revocation and dilemma deletion.
-- Preserves RLS deny-by-default; callable only by authenticated owner.

create or replace function public.get_creator_dilemmas()
returns table (
  dilemma_id uuid,
  item_name varchar(80),
  price_cents bigint,
  currency varchar(3),
  category public.item_category,
  purpose public.purchase_purpose,
  reason text,
  pause_due_at timestamptz,
  state public.dilemma_state,
  is_invite_revoked boolean,
  created_at timestamptz,
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
  v_owner_id uuid;
begin
  v_owner_id := auth.uid();
  if v_owner_id is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;

  return query
  select
    d.id as dilemma_id,
    d.item_name,
    d.price_cents,
    d.currency,
    d.category,
    d.purpose,
    d.reason,
    d.pause_due_at,
    d.state,
    d.is_invite_revoked,
    d.created_at,
    coalesce(count(case when v.prediction = 'buy' then 1 end), 0)::bigint as buy_count,
    coalesce(count(case when v.prediction = 'wait' then 1 end), 0)::bigint as wait_count,
    coalesce(count(case when v.prediction = 'skip' then 1 end), 0)::bigint as skip_count,
    coalesce(count(v.id), 0)::bigint as total_votes
  from public.dilemmas d
  left join public.participations p on p.dilemma_id = d.id
  left join public.votes v on v.participation_id = p.id
  where d.owner_id = v_owner_id
  group by d.id
  order by d.created_at desc;
end;
$$;

create or replace function public.revoke_dilemma_invite(p_dilemma_id uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_owner_id uuid;
begin
  v_owner_id := auth.uid();
  if v_owner_id is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;

  update public.dilemmas
     set is_invite_revoked = true
   where id = p_dilemma_id
     and owner_id = v_owner_id;

  if not found then
    raise exception 'Dilemma not found or unauthorized' using errcode = 'P0002';
  end if;

  update public.guest_access_sessions
     set revoked_at = clock_timestamp()
   where dilemma_id = p_dilemma_id
     and revoked_at is null;
end;
$$;

create or replace function public.delete_creator_dilemma(p_dilemma_id uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_owner_id uuid;
begin
  v_owner_id := auth.uid();
  if v_owner_id is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;

  delete from public.dilemmas
   where id = p_dilemma_id
     and owner_id = v_owner_id;

  if not found then
    raise exception 'Dilemma not found or unauthorized' using errcode = 'P0002';
  end if;
end;
$$;

revoke all on function public.get_creator_dilemmas() from public, anon;
grant execute on function public.get_creator_dilemmas() to authenticated;

revoke all on function public.revoke_dilemma_invite(uuid) from public, anon;
grant execute on function public.revoke_dilemma_invite(uuid) to authenticated;

revoke all on function public.delete_creator_dilemma(uuid) from public, anon;
grant execute on function public.delete_creator_dilemma(uuid) to authenticated;

