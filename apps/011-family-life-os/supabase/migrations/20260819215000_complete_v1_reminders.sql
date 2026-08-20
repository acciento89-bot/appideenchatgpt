begin;

alter table public.reminders
    add column if not exists kind text not null default 'custom'
    check (kind in ('event', 'task', 'preparation', 'assignment', 'inbox', 'custom'));

create unique index if not exists reminders_plan_member_trigger_unique
    on public.reminders(plan_item_id, target_member_id, trigger_at);

create or replace function private.seed_proposal_reminder()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_trigger timestamptz;
    v_kind text;
begin
    select ap.suggested_reminder_at,
           case ap.kind
             when 'event' then 'event'
             when 'preparation' then 'preparation'
             else 'task'
           end
      into v_trigger, v_kind
      from public.plan_items pi
      join public.action_proposals ap on ap.id = pi.source_proposal_id
     where pi.id = new.plan_item_id;

    if v_trigger is not null and v_trigger > now() then
        insert into public.reminders(plan_item_id, target_member_id, trigger_at, delivery_state, kind)
        values (new.plan_item_id, new.member_id, v_trigger, 'pending', v_kind)
        on conflict do nothing;
    end if;
    return new;
end;
$$;

revoke all on function private.seed_proposal_reminder() from public;

drop trigger if exists plan_item_assignee_seed_reminder on public.plan_item_assignees;
create trigger plan_item_assignee_seed_reminder
after insert on public.plan_item_assignees
for each row execute function private.seed_proposal_reminder();

create or replace function public.set_my_plan_reminder(
    p_plan_item_id uuid,
    p_trigger_at timestamptz
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_household_id uuid;
    v_member_id uuid;
    v_id uuid;
    v_kind text;
begin
    select pi.household_id,
           case pi.kind when 'event' then 'event' when 'preparation' then 'preparation' else 'task' end
      into v_household_id, v_kind
      from public.plan_items pi
     where pi.id = p_plan_item_id;

    if v_household_id is null or not private.is_household_member(v_household_id) then
        raise exception 'Plan item not found or forbidden';
    end if;

    v_member_id := private.current_household_member_id(v_household_id);
    if v_member_id is null then raise exception 'Active membership required'; end if;

    delete from public.reminders
     where plan_item_id = p_plan_item_id
       and target_member_id = v_member_id
       and delivery_state = 'pending';

    if p_trigger_at is null then return null; end if;
    if p_trigger_at <= now() then raise exception 'Reminder must be in the future'; end if;

    insert into public.reminders(plan_item_id, target_member_id, trigger_at, delivery_state, kind)
    values (p_plan_item_id, v_member_id, p_trigger_at, 'pending', v_kind)
    returning id into v_id;
    return v_id;
end;
$$;

revoke execute on function public.set_my_plan_reminder(uuid, timestamptz) from public, anon;
grant execute on function public.set_my_plan_reminder(uuid, timestamptz) to authenticated;

commit;
