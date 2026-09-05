-- Persist the collecting_votes -> decision_due boundary and schedule it.

create schema if not exists private;

revoke all on schema private from public, anon, authenticated, service_role;

create or replace function private.expire_due_dilemmas()
returns integer
language plpgsql
set search_path = pg_catalog, public, private
as $$
declare
  v_cutoff timestamptz := clock_timestamp();
  v_expired_count integer;
begin
  with due_dilemmas as (
    select d.id
      from public.dilemmas d
     where d.state = 'collecting_votes'
       and d.pause_due_at <= v_cutoff
     order by d.pause_due_at, d.id
     for update skip locked
     limit 1000
  )
  update public.dilemmas d
     set state = 'decision_due'
    from due_dilemmas due
   where d.id = due.id
     and d.state = 'collecting_votes'
     and d.pause_due_at <= v_cutoff;

  get diagnostics v_expired_count = row_count;
  return v_expired_count;
end;
$$;

revoke all on function private.expire_due_dilemmas() from public;
revoke all on function private.expire_due_dilemmas()
  from anon, authenticated, service_role;

do $$
begin
  if not exists (
    select 1
      from pg_available_extensions
     where name = 'pg_cron'
  ) then
    raise exception 'Required extension pg_cron is unavailable';
  end if;
end;
$$;

create extension if not exists pg_cron with schema pg_catalog;

revoke all on schema cron from public, anon, authenticated, service_role;

select cron.schedule(
  'expire-due-dilemmas',
  '* * * * *',
  'select private.expire_due_dilemmas();'
);
