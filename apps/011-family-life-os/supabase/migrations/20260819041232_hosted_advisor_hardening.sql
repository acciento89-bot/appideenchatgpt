begin;

-- Foreign-key coverage reported by the hosted Supabase performance advisor.
create index if not exists action_proposals_extraction_run_id_idx
    on public.action_proposals(extraction_run_id)
    where extraction_run_id is not null;
create index if not exists households_created_by_idx
    on public.households(created_by);
create index if not exists plan_items_created_by_member_id_idx
    on public.plan_items(created_by_member_id);
create index if not exists reminders_plan_item_id_idx
    on public.reminders(plan_item_id);

-- Avoid two permissive SELECT policies on reminders. Read access stays in the
-- dedicated SELECT policy; mutations get their own policies.
drop policy if exists reminders_all_manage on public.reminders;

create policy reminders_insert
on public.reminders
for insert
to authenticated
with check (
    exists (
        select 1
        from public.plan_items pi
        join public.household_members hm
          on hm.id = target_member_id
         and hm.household_id = pi.household_id
        where pi.id = plan_item_id
          and (select private.can_manage_household(pi.household_id))
    )
);

create policy reminders_update
on public.reminders
for update
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
        join public.household_members hm
          on hm.id = target_member_id
         and hm.household_id = pi.household_id
        where pi.id = plan_item_id
          and (select private.can_manage_household(pi.household_id))
    )
);

create policy reminders_delete
on public.reminders
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

-- Keep privileged canonicalization outside the exposed API schema. The public
-- RPC is now SECURITY INVOKER and delegates to this private implementation.
create or replace function private.confirm_action_proposals_impl(
    p_source_item_id uuid,
    p_proposal_ids uuid[]
)
returns table(proposal_id uuid, plan_item_id uuid)
language plpgsql
security definer
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
            or p.review_status not in ('proposed', 'confirmed')
            or p.is_included is not true
            or p.unresolved_fields <> '{}'::jsonb
    ) then
        raise exception 'Selected proposal is missing, unresolved, excluded, or rejected';
    end if;

    for v_proposal in
        select p.*
          from public.action_proposals p
         where p.source_item_id = p_source_item_id
           and p.id = any(p_proposal_ids)
         order by p.created_at, p.id
    loop
        v_plan_item_id := null;

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
             where pi.source_proposal_id = v_proposal.id
               and pi.household_id = v_household_id;
        end if;

        if v_plan_item_id is null then
            raise exception 'Canonical plan item could not be resolved';
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
         where id = v_proposal.id
           and source_item_id = p_source_item_id
           and review_status <> 'confirmed';

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
           processed_at = coalesce(s.processed_at, now())
     where s.id = p_source_item_id
       and s.household_id = v_household_id;
end;
$$;

revoke all on function private.confirm_action_proposals_impl(uuid, uuid[]) from public, anon;
grant execute on function private.confirm_action_proposals_impl(uuid, uuid[]) to authenticated;

create or replace function public.confirm_action_proposals(
    p_source_item_id uuid,
    p_proposal_ids uuid[]
)
returns table(proposal_id uuid, plan_item_id uuid)
language sql
security invoker
set search_path = ''
as $$
    select *
      from private.confirm_action_proposals_impl(p_source_item_id, p_proposal_ids);
$$;

revoke execute on function public.confirm_action_proposals(uuid, uuid[]) from public, anon;
grant execute on function public.confirm_action_proposals(uuid, uuid[]) to authenticated;

commit;
