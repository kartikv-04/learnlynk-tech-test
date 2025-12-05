-- LearnLynk Tech Test - Task 2: RLS Policies on leads

alter table public.leads enable row level security;

-- Example helper: assume JWT has tenant_id, user_id, role.
-- You can use: current_setting('request.jwt.claims', true)::jsonb

-- TODO: write a policy so:
-- - counselors see leads where they are owner_id OR in one of their teams
-- - admins can see all leads of their tenant

create policy "leads_select_policy"
on public.leads
for select
using (
  (
    (current_setting('request.jwt.claims', true)::jsonb ->> 'role') = 'admin'
    AND tenant_id = ((current_setting('request.jwt.claims', true)::jsonb ->> 'tenant_id')::uuid)
  )
  OR
  (
    owner_id = ((current_setting('request.jwt.claims', true)::jsonb ->> 'user_id')::uuid)
    AND tenant_id = ((current_setting('request.jwt.claims', true)::jsonb ->> 'tenant_id')::uuid)
  )
  OR
  exists (
    select 1
    from public.user_teams ut_me
    join public.user_teams ut_owner
      on ut_me.team_id = ut_owner.team_id
    where ut_me.user_id = ((current_setting('request.jwt.claims', true)::jsonb ->> 'user_id')::uuid)
      and ut_owner.user_id = public.leads.owner_id
      and public.leads.tenant_id = ((current_setting('request.jwt.claims', true)::jsonb ->> 'tenant_id')::uuid)
  )
);

-- TODO: add INSERT policy that:
-- - allows counselors/admins to insert leads for their tenant
-- - ensures tenant_id is correctly set/validated

create policy "leads_insert_policy"
on public.leads
for insert
with check (
  (
    (current_setting('request.jwt.claims', true)::jsonb ->> 'role') = 'admin'
    AND tenant_id = ((current_setting('request.jwt.claims', true)::jsonb ->> 'tenant_id')::uuid)
  )
  OR
  (
    owner_id = ((current_setting('request.jwt.claims', true)::jsonb ->> 'user_id')::uuid)
    AND tenant_id = ((current_setting('request.jwt.claims', true)::jsonb ->> 'tenant_id')::uuid)
  )
);
