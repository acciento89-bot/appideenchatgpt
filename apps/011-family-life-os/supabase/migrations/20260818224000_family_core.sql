-- Family Life OS / candidate #011
-- Core collaborative schema for the first real text-ingestion vertical slice.
-- Target: Supabase Postgres + Auth, iOS client using authenticated publishable-key access.

begin;

create schema if not exists private;

-- -----------------------------------------------------------------------------
-- Core tables
-- -----------------------------------------------------------------------------

create table if not exists public.households (
    id uuid primary key default gen_random_uuid(),
    name text not null check (char_length(trim(name)) between 1 and 120),
    locale text not null default 'de-DE',
    timezone text not null default 'Europe/Berlin',
    created_by uuid not null references auth.users(id) on delete restrict,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.household_members (
    id uuid primary key default gen_random_uuid(),
    household_id uuid not null references public.households(id) on delete cascade,
    user_id uuid references auth.users(id) on delete set null,
    display_name text not null check (char_length(trim(display_name)) between 1 and 120),
    role text not null check (role in ('owner', 'adult', 'child', 'guest')),
    accent_key text not null default 'indigo',
    invite_status text not null default 'active' check (invite_status in ('pending', 'active', 'revoked')),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint household_member_user_unique unique nulls not distinct (household_id, user_id)
);

create table if not exists public.source_items (
    id uuid primary key default gen_random_uuid(),
    household_id uuid not null references public.households(id) on delete cascade,
    created_by_member_id uuid not null references public.household_members(id) on delete restrict,
    source_type text not null check (source_type in ('image', 'pdf', 'text', 'voice', 'share')),
    display_title text not null check (char_length(trim(display_title)) between 1 and 240),
    original_text text,
    storage_path text,
    processing_status text not null default 'queued' check (
        processing_status in ('queued', 'uploading', 'processing', 'review', 'partial', 'done', 'failed')
    ),
    processing_error_code text,
    created_at timestamptz not null default now(),
    processed_at timestamptz,
    updated_at timestamptz not null default now()
);

create table if not exists public.extraction_runs (
    id uuid primary key default gen_random_uuid(),
    source_item_id uuid not null references public.source_items(id) on delete cascade,
    provider text,
    model text,
    schema_version integer not null default 1 check (schema_version > 0),
    normalized_output jsonb,
    status text not null check (status in ('processing', 'succeeded', 'failed')),
    error_code text,
    created_at timestamptz not null default now(),
    completed_at timestamptz
);

create table if not exists public.action_proposals (
    id uuid primary key default gen_random_uuid(),
    source_item_id uuid not null references public.source_items(id) on delete cascade,
    extraction_run_id uuid references public.extraction_runs(id) on delete set null,
    kind text not null check (kind in ('event', 'task', 'deadline', 'payment', 'preparation')),
    title text not null check (char_length(trim(title)) between 1 and 240),
    starts_at timestamptz,
    ends_at timestamptz,
    due_at timestamptz,
    all_day boolean not null default false,
    location text,
    notes text,
    amount_minor bigint check (amount_minor is null or amount_minor >= 0),
    currency text check (currency is null or currency ~ '^[A-Z]{3}$'),
    unresolved_fields jsonb not null default '{}'::jsonb,
    is_included boolean not null default true,
    review_status text not null default 'proposed' check (review_status in ('proposed', 'confirmed', 'rejected')),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint proposal_time_order check (starts_at is null or ends_at is null or ends_at >= starts_at)
);

create table if not exists public.action_proposal_assignees (
    proposal_id uuid not null references public.action_proposals(id) on delete cascade,
    member_id uuid not null references public.household_members(id) on delete cascade,
    primary key (proposal_id, member_id)
);

create table if not exists public.plan_items (
    id uuid primary key default gen_random_uuid(),
    household_id uuid not null references public.households(id) on delete cascade,
    kind text not null check (kind in ('event', 'task', 'deadline', 'payment', 'preparation')),
    title text not null check (char_length(trim(title)) between 1 and 240),
    starts_at timestamptz,
    ends_at timestamptz,
    due_at timestamptz,
    all_day boolean not null default false,
    location text,
    notes text,
    amount_minor bigint check (amount_minor is null or amount_minor >= 0),
    currency text check (currency is null or currency ~ '^[A-Z]{3}$'),
    status text not null default 'open' check (status in ('open', 'completed', 'cancelled')),
    created_by_member_id uuid not null references public.household_members(id) on delete restrict,
    source_item_id uuid references public.source_items(id) on delete set null,
    source_proposal_id uuid unique references public.action_proposals(id) on delete set null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    completed_at timestamptz,
    constraint plan_time_order check (starts_at is null or ends_at is null or ends_at >= starts_at)
);

create table if not exists public.plan_item_assignees (
    plan_item_id uuid not null references public.plan_items(id) on delete cascade,
    member_id uuid not null references public.household_members(id) on delete cascade,
    primary key (plan_item_id, member_id)
);

create table if not exists public.reminders (
    id uuid primary key default gen_random_uuid(),
    plan_item_id uuid not null references public.plan_items(id) on delete cascade,
    target_member_id uuid not null references public.household_members(id) on delete cascade,
    trigger_at timestamptz not null,
    delivery_state text not null default 'pending' check (delivery_state in ('pending', 'sent', 'cancelled', 'failed')),
    created_at timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- Indexes used both by normal queries and authorization policies.
-- -----------------------------------------------------------------------------

create index if not exists household_members_household_id_idx on public.household_members(household_id);
create index if not exists household_members_user_id_idx on public.household_members(user_id) where user_id is not null;
create index if not exists source_items_household_id_created_at_idx on public.source_items(household_id, created_at desc);
create index if not exists source_items_created_by_member_idx on public.source_items(created_by_member_id);
create index if not exists extraction_runs_source_item_idx on public.extraction_runs(source_item_id, created_at desc);
create index if not exists action_proposals_source_item_idx on public.action_proposals(source_item_id, created_at);
create index if not exists action_proposal_assignees_member_idx on public.action_proposal_assignees(member_id);
create index if not exists plan_items_household_date_idx on public.plan_items(household_id, starts_at, due_at);
create index if not exists plan_items_source_item_idx on public.plan_items(source_item_id) where source_item_id is not null;
create index if not exists plan_item_assignees_member_idx on public.plan_item_assignees(member_id);
create index if not exists reminders_member_trigger_idx on public.reminders(target_member_id, trigger_at);

-- -----------------------------------------------------------------------------
-- updated_at trigger
-- -----------------------------------------------------------------------------

create or replace function private.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

revoke all on function private.set_updated_at() from public;

create or replace trigger households_set_updated_at
before update on public.households
for each row execute function private.set_updated_at();

create or replace trigger household_members_set_updated_at
before update on public.household_members
for each row execute function private.set_updated_at();

create or replace trigger source_items_set_updated_at
before update on public.source_items
for each row execute function private.set_updated_at();

create or replace trigger action_proposals_set_updated_at
before update on public.action_proposals
for each row execute function private.set_updated_at();

create or replace trigger plan_items_set_updated_at
before update on public.plan_items
for each row execute function private.set_updated_at();

-- -----------------------------------------------------------------------------
-- Authorization helpers.
-- SECURITY DEFINER is deliberately limited to membership lookup so policies can
-- check the membership table without recursive RLS evaluation.
-- -----------------------------------------------------------------------------

create or replace function private.is_household_member(p_household_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1
        from public.household_members hm
        where hm.household_id = p_household_id
          and hm.user_id = (select auth.uid())
          and hm.invite_status = 'active'
    );
$$;

create or replace function private.can_manage_household(p_household_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1
        from public.household_members hm
        where hm.household_id = p_household_id
          and hm.user_id = (select auth.uid())
          and hm.invite_status = 'active'
          and hm.role in ('owner', 'adult')
    );
$$;

create or replace function private.is_household_owner(p_household_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1
        from public.household_members hm
        where hm.household_id = p_household_id
          and hm.user_id = (select auth.uid())
          and hm.invite_status = 'active'
          and hm.role = 'owner'
    );
$$;

create or replace function private.is_current_user_member(p_member_id uuid, p_household_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1
        from public.household_members hm
        where hm.id = p_member_id
          and hm.household_id = p_household_id
          and hm.user_id = (select auth.uid())
          and hm.invite_status = 'active'
    );
$$;

revoke all on function private.is_household_member(uuid) from public, anon;
revoke all on function private.can_manage_household(uuid) from public, anon;
revoke all on function private.is_household_owner(uuid) from public, anon;
revoke all on function private.is_current_user_member(uuid, uuid) from public, anon;

grant execute on function private.is_household_member(uuid) to authenticated;
grant execute on function private.can_manage_household(uuid) to authenticated;
grant execute on function private.is_household_owner(uuid) to authenticated;
grant execute on function private.is_current_user_member(uuid, uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- RLS enablement
-- -----------------------------------------------------------------------------

alter table public.households enable row level security;
alter table public.household_members enable row level security;
alter table public.source_items enable row level security;
alter table public.extraction_runs enable row level security;
alter table public.action_proposals enable row level security;
alter table public.action_proposal_assignees enable row level security;
alter table public.plan_items enable row level security;
alter table public.plan_item_assignees enable row level security;
alter table public.reminders enable row level security;

-- -----------------------------------------------------------------------------
-- Household policies
-- -----------------------------------------------------------------------------

create policy households_select
on public.households
for select
to authenticated
using (
    created_by = (select auth.uid())
    or (select private.is_household_member(id))
);

create policy households_insert
on public.households
for insert
to authenticated
with check (created_by = (select auth.uid()));

create policy households_update
on public.households
for update
to authenticated
using ((select private.is_household_owner(id)))
with check ((select private.is_household_owner(id)));

create policy households_delete
on public.households
for delete
to authenticated
using ((select private.is_household_owner(id)));

-- -----------------------------------------------------------------------------
-- Membership policies
-- -----------------------------------------------------------------------------

create policy household_members_select
on public.household_members
for select
to authenticated
using (
    user_id = (select auth.uid())
    or (select private.is_household_member(household_id))
);

create policy household_members_insert
on public.household_members
for insert
to authenticated
with check (
    (select private.is_household_owner(household_id))
    or exists (
        select 1
        from public.households h
        where h.id = household_id
          and h.created_by = (select auth.uid())
          and role = 'owner'
          and user_id = (select auth.uid())
    )
);

create policy household_members_update
on public.household_members
for update
to authenticated
using ((select private.is_household_owner(household_id)))
with check ((select private.is_household_owner(household_id)));

create policy household_members_delete
on public.household_members
for delete
to authenticated
using ((select private.is_household_owner(household_id)));

-- -----------------------------------------------------------------------------
-- Source policies
-- -----------------------------------------------------------------------------

create policy source_items_select
on public.source_items
for select
to authenticated
using ((select private.is_household_member(household_id)));

create policy source_items_insert
on public.source_items
for insert
to authenticated
with check (
    (select private.can_manage_household(household_id))
    and (select private.is_current_user_member(created_by_member_id, household_id))
);

create policy source_items_update
on public.source_items
for update
to authenticated
using ((select private.can_manage_household(household_id)))
with check ((select private.can_manage_household(household_id)));

create policy source_items_delete
on public.source_items
for delete
to authenticated
using ((select private.can_manage_household(household_id)));

-- -----------------------------------------------------------------------------
-- Extraction/proposal read + review policies.
-- Extraction run/proposal INSERT is intentionally not granted to authenticated
-- clients; trusted server/Edge processing writes machine output.
-- -----------------------------------------------------------------------------

create policy extraction_runs_select
on public.extraction_runs
for select
to authenticated
using (
    exists (
        select 1
        from public.source_items s
        where s.id = source_item_id
          and (select private.is_household_member(s.household_id))
    )
);

create policy action_proposals_select
on public.action_proposals
for select
to authenticated
using (
    exists (
        select 1
        from public.source_items s
        where s.id = source_item_id
          and (select private.is_household_member(s.household_id))
    )
);

create policy action_proposals_update
on public.action_proposals
for update
to authenticated
using (
    exists (
        select 1
        from public.source_items s
        where s.id = source_item_id
          and (select private.can_manage_household(s.household_id))
    )
)
with check (
    exists (
        select 1
        from public.source_items s
        where s.id = source_item_id
          and (select private.can_manage_household(s.household_id))
    )
);

create policy action_proposal_assignees_select
on public.action_proposal_assignees
for select
to authenticated
using (
    exists (
        select 1
        from public.action_proposals p
        join public.source_items s on s.id = p.source_item_id
        where p.id = proposal_id
          and (select private.is_household_member(s.household_id))
    )
);

create policy action_proposal_assignees_insert
on public.action_proposal_assignees
for insert
to authenticated
with check (
    exists (
        select 1
        from public.action_proposals p
        join public.source_items s on s.id = p.source_item_id
        join public.household_members hm on hm.id = member_id and hm.household_id = s.household_id
        where p.id = proposal_id
          and (select private.can_manage_household(s.household_id))
    )
);

create policy action_proposal_assignees_delete
on public.action_proposal_assignees
for delete
to authenticated
using (
    exists (
        select 1
        from public.action_proposals p
        join public.source_items s on s.id = p.source_item_id
        where p.id = proposal_id
          and (select private.can_manage_household(s.household_id))
    )
);

-- -----------------------------------------------------------------------------
-- Canonical plan/reminder policies
-- -----------------------------------------------------------------------------

create policy plan_items_select
on public.plan_items
for select
to authenticated
using ((select private.is_household_member(household_id)));

create policy plan_items_insert
on public.plan_items
for insert
to authenticated
with check (
    (select private.can_manage_household(household_id))
    and exists (
        select 1
        from public.household_members hm
        where hm.id = created_by_member_id
          and hm.household_id = plan_items.household_id
          and hm.user_id = (select auth.uid())
          and hm.invite_status = 'active'
    )
);

create policy plan_items_update
on public.plan_items
for update
to authenticated
using ((select private.can_manage_household(household_id)))
with check ((select private.can_manage_household(household_id)));

create policy plan_items_delete
on public.plan_items
for delete
to authenticated
using ((select private.can_manage_household(household_id)));

create policy plan_item_assignees_select
on public.plan_item_assignees
for select
to authenticated
using (
    exists (
        select 1
        from public.plan_items pi
        where pi.id = plan_item_id
          and (select private.is_household_member(pi.household_id))
    )
);

create policy plan_item_assignees_insert
on public.plan_item_assignees
for insert
to authenticated
with check (
    exists (
        select 1
        from public.plan_items pi
        join public.household_members hm on hm.id = member_id and hm.household_id = pi.household_id
        where pi.id = plan_item_id
          and (select private.can_manage_household(pi.household_id))
    )
);

create policy plan_item_assignees_delete
on public.plan_item_assignees
for delete
to authenticated
using (
    exists (
        select 1
        from public.plan_items pi
        where pi.id = plan_item_id
          and (select private.can_manage_household(pi.household_id))
    )
);

create policy reminders_select
on public.reminders
for select
to authenticated
using (
    exists (
        select 1
        from public.plan_items pi
        where pi.id = plan_item_id
          and (select private.is_household_member(pi.household_id))
    )
);

create policy reminders_all_manage
on public.reminders
for all
to authenticated
using (
    exists (
        select 1
        from public.plan_items pi
        where pi.id = plan_item_id
          and (select private.can_manage_household(pi.household_id))
    )
)
with check (
    exists (
        select 1
        from public.plan_items pi
        join public.household_members hm on hm.id = target_member_id and hm.household_id = pi.household_id
        where pi.id = plan_item_id
          and (select private.can_manage_household(pi.household_id))
    )
);

-- -----------------------------------------------------------------------------
-- Atomic proposal confirmation.
-- Runs as invoker so the normal RLS/role checks stay active. A unique
-- source_proposal_id makes retries idempotent rather than duplicating plan data.
-- -----------------------------------------------------------------------------

create or replace function public.confirm_action_proposals(
    p_source_item_id uuid,
    p_proposal_ids uuid[]
)
returns table(proposal_id uuid, plan_item_id uuid)
language plpgsql
security invoker
set search_path = ''
as $$
declare
    v_household_id uuid;
    v_actor_member_id uuid;
    v_proposal public.action_proposals%rowtype;
    v_plan_item_id uuid;
begin
    if coalesce(array_length(p_proposal_ids, 1), 0) = 0 then
        raise exception 'No proposals selected';
    end if;

    select s.household_id
      into v_household_id
      from public.source_items s
     where s.id = p_source_item_id;

    if v_household_id is null then
        raise exception 'Source item not found';
    end if;

    if not (select private.can_manage_household(v_household_id)) then
        raise exception 'Insufficient household permission';
    end if;

    select hm.id
      into v_actor_member_id
      from public.household_members hm
     where hm.household_id = v_household_id
       and hm.user_id = (select auth.uid())
       and hm.invite_status = 'active'
       and hm.role in ('owner', 'adult')
     order by case hm.role when 'owner' then 0 else 1 end
     limit 1;

    if v_actor_member_id is null then
        raise exception 'Active adult household member not found';
    end if;

    if exists (
        select 1
          from unnest(p_proposal_ids) requested(id)
          left join public.action_proposals p on p.id = requested.id
         where p.id is null
            or p.source_item_id <> p_source_item_id
            or p.review_status <> 'proposed'
            or p.is_included is not true
            or p.unresolved_fields <> '{}'::jsonb
    ) then
        raise exception 'Selected proposal is missing, unresolved, excluded, or already reviewed';
    end if;

    for v_proposal in
        select p.*
          from public.action_proposals p
         where p.source_item_id = p_source_item_id
           and p.id = any(p_proposal_ids)
         order by p.created_at, p.id
    loop
        insert into public.plan_items (
            household_id,
            kind,
            title,
            starts_at,
            ends_at,
            due_at,
            all_day,
            location,
            notes,
            amount_minor,
            currency,
            status,
            created_by_member_id,
            source_item_id,
            source_proposal_id
        ) values (
            v_household_id,
            v_proposal.kind,
            v_proposal.title,
            v_proposal.starts_at,
            v_proposal.ends_at,
            v_proposal.due_at,
            v_proposal.all_day,
            v_proposal.location,
            v_proposal.notes,
            v_proposal.amount_minor,
            v_proposal.currency,
            'open',
            v_actor_member_id,
            p_source_item_id,
            v_proposal.id
        )
        on conflict (source_proposal_id) do nothing
        returning id into v_plan_item_id;

        if v_plan_item_id is null then
            select pi.id
              into v_plan_item_id
              from public.plan_items pi
             where pi.source_proposal_id = v_proposal.id;
        end if;

        insert into public.plan_item_assignees (plan_item_id, member_id)
        select v_plan_item_id, apa.member_id
          from public.action_proposal_assignees apa
          join public.household_members hm
            on hm.id = apa.member_id
           and hm.household_id = v_household_id
         where apa.proposal_id = v_proposal.id
        on conflict do nothing;

        update public.action_proposals
           set review_status = 'confirmed'
         where id = v_proposal.id;

        proposal_id := v_proposal.id;
        plan_item_id := v_plan_item_id;
        return next;
    end loop;

    update public.source_items s
       set processing_status = case
            when exists (
                select 1
                  from public.action_proposals p
                 where p.source_item_id = p_source_item_id
                   and p.review_status = 'proposed'
            ) then 'partial'
            else 'done'
           end,
           processed_at = now()
     where s.id = p_source_item_id;
end;
$$;

revoke execute on function public.confirm_action_proposals(uuid, uuid[]) from public, anon;
grant execute on function public.confirm_action_proposals(uuid, uuid[]) to authenticated;

-- -----------------------------------------------------------------------------
-- Data API grants. RLS remains the row-level authorization boundary.
-- Machine extraction writes are intentionally reserved for trusted server roles.
-- -----------------------------------------------------------------------------

grant select, insert, update, delete on public.households to authenticated;
grant select, insert, update, delete on public.household_members to authenticated;
grant select, insert, update, delete on public.source_items to authenticated;
grant select on public.extraction_runs to authenticated;
grant select, update on public.action_proposals to authenticated;
grant select, insert, delete on public.action_proposal_assignees to authenticated;
grant select, insert, update, delete on public.plan_items to authenticated;
grant select, insert, delete on public.plan_item_assignees to authenticated;
grant select, insert, update, delete on public.reminders to authenticated;

commit;
