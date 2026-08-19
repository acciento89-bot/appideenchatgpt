begin;

alter table public.action_proposals
    add column if not exists suggested_reminder_at timestamptz;

alter table public.reminders
    add column if not exists reminder_kind text not null default 'default'
        check (reminder_kind in ('default', 'event', 'task', 'deadline', 'payment', 'preparation', 'custom'));

create unique index if not exists reminders_plan_member_trigger_unique
    on public.reminders(plan_item_id, target_member_id, trigger_at);

create or replace function private.default_reminder_time(p_plan_item_id uuid)
returns timestamptz
language sql
stable
security definer
set search_path = ''
as $$
    select coalesce(
        ap.suggested_reminder_at,
        case pi.kind
            when 'event' then pi.starts_at - interval '1 hour'
            when 'deadline' then pi.due_at - interval '1 day'
            when 'payment' then pi.due_at - interval '1 day'
            when 'preparation' then coalesce(pi.due_at, pi.starts_at) - interval '2 hours'
            when 'task' then pi.due_at - interval '2 hours'
            else null
        end
    )
    from public.plan_items pi
    left join public.action_proposals ap on ap.id = pi.source_proposal_id
    where pi.id = p_plan_item_id;
$$;

create or replace function private.ensure_default_reminder(
    p_plan_item_id uuid,
    p_member_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_trigger_at timestamptz;
    v_kind text;
begin
    select private.default_reminder_time(p_plan_item_id), pi.kind
      into v_trigger_at, v_kind
      from public.plan_items pi
     where pi.id = p_plan_item_id
       and pi.status = 'open';

    if v_trigger_at is null or v_trigger_at <= now() then
        return;
    end if;

    insert into public.reminders(
        plan_item_id, target_member_id, trigger_at, delivery_state, reminder_kind
    ) values (
        p_plan_item_id,
        p_member_id,
        v_trigger_at,
        'pending',
        case when v_kind in ('event','task','deadline','payment','preparation') then v_kind else 'default' end
    ) on conflict (plan_item_id, target_member_id, trigger_at) do nothing;
end;
$$;

create or replace function private.plan_assignee_default_reminder()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    perform private.ensure_default_reminder(new.plan_item_id, new.member_id);
    return new;
end;
$$;

create or replace function private.recalculate_plan_reminders()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_assignee record;
begin
    if new.starts_at is not distinct from old.starts_at
       and new.due_at is not distinct from old.due_at
       and new.status is not distinct from old.status then
        return new;
    end if;

    update public.reminders
       set delivery_state = 'cancelled'
     where plan_item_id = new.id
       and delivery_state = 'pending';

    if new.status = 'open' then
        for v_assignee in
            select pia.member_id
              from public.plan_item_assignees pia
             where pia.plan_item_id = new.id
        loop
            perform private.ensure_default_reminder(new.id, v_assignee.member_id);
        end loop;
    end if;

    return new;
end;
$$;

revoke all on function private.default_reminder_time(uuid) from public, anon;
revoke all on function private.ensure_default_reminder(uuid, uuid) from public, anon;
revoke all on function private.plan_assignee_default_reminder() from public;
revoke all on function private.recalculate_plan_reminders() from public;

grant execute on function private.default_reminder_time(uuid) to authenticated;

create or replace trigger plan_item_assignees_default_reminder
after insert on public.plan_item_assignees
for each row execute function private.plan_assignee_default_reminder();

create or replace trigger plan_items_recalculate_reminders
after update of starts_at, due_at, status on public.plan_items
for each row execute function private.recalculate_plan_reminders();

-- The reminder suggestion is reviewable/editable proposal data.
revoke update on public.action_proposals from authenticated;
grant update (
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
    unresolved_fields,
    is_included,
    suggested_reminder_at
) on public.action_proposals to authenticated;

commit;
