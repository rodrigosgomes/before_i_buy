-- An expectation belongs to its owner and to a dilemma owned by that same user.

drop policy if exists owner_expectations_owner_only on public.owner_expectations;

create policy owner_expectations_owner_only
on public.owner_expectations for all to authenticated
using (
  owner_id = auth.uid()
  and exists (
    select 1
      from public.dilemmas d
     where d.id = owner_expectations.dilemma_id
       and d.owner_id = auth.uid()
  )
)
with check (
  owner_id = auth.uid()
  and exists (
    select 1
      from public.dilemmas d
     where d.id = owner_expectations.dilemma_id
       and d.owner_id = auth.uid()
  )
);
