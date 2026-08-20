begin;

-- Keep trigger functions explicit for INSERT/UPDATE/DELETE records. This avoids
-- relying on record-valued CASE/COALESCE behavior inside PL/pgSQL triggers.

create or replace function private.audit_plan_item()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_row public.plan_items%rowtype;
    v_action text;
    v_actor uuid;
begin
    if tg_op = 'DELETE' then
        v_row := old;
    else
        v_row := new;
    end if;

    v_actor := private.current_household_member_id(v_row.household_id);

    if tg_op = 'INSERT' then
        v_action := 'created';
    elsif tg_op = 'DELETE' then
        v_action := 'deleted';
    elsif old.status is distinct from new.status and new.status = 'completed' then
        v_action := 'completed';
    elsif old.status is distinct from new.status and old.status = 'completed' then
        v_action := 'reopened';
    else
        v_action := 'updated';
    end if;

    insert into public.activity_log(
        household_id, actor_user_id, actor_member_id, entity_type, entity_id, action, metadata
    ) values (
        v_row.household_id,
        (select auth.uid()),
        v_actor,
        'plan_item',
        v_row.id,
        v_action,
        jsonb_strip_nulls(jsonb_build_object(
            'kind', v_row.kind,
            'status', v_row.status,
            'starts_at', v_row.starts_at,
            'due_at', v_row.due_at,
            'version', v_row.version
        ))
    );

    if tg_op = 'DELETE' then return old; end if;
    return new;
end;
$$;

create or replace function private.audit_source_item()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_row public.source_items%rowtype;
    v_action text;
begin
    if tg_op = 'DELETE' then
        v_row := old;
    else
        v_row := new;
    end if;

    if tg_op = 'INSERT' then
        v_action := 'created';
    elsif tg_op = 'DELETE' then
        v_action := 'deleted';
    elsif old.processing_status is distinct from new.processing_status then
        v_action := 'status_' || new.processing_status;
    elsif old.archived_at is distinct from new.archived_at then
        v_action := case when new.archived_at is null then 'restored' else 'archived' end;
    else
        if tg_op = 'DELETE' then return old; end if;
        return new;
    end if;

    insert into public.activity_log(
        household_id, actor_user_id, actor_member_id, entity_type, entity_id, action, metadata
    ) values (
        v_row.household_id,
        (select auth.uid()),
        private.current_household_member_id(v_row.household_id),
        'source_item',
        v_row.id,
        v_action,
        jsonb_build_object('source_type', v_row.source_type, 'processing_status', v_row.processing_status)
    );

    if tg_op = 'DELETE' then return old; end if;
    return new;
end;
$$;

create or replace function private.audit_member()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_row public.household_members%rowtype;
begin
    if tg_op = 'DELETE' then
        v_row := old;
    else
        v_row := new;
    end if;

    insert into public.activity_log(
        household_id, actor_user_id, actor_member_id, entity_type, entity_id, action, metadata
    ) values (
        v_row.household_id,
        (select auth.uid()),
        private.current_household_member_id(v_row.household_id),
        'member',
        v_row.id,
        lower(tg_op),
        jsonb_build_object('role', v_row.role, 'invite_status', v_row.invite_status)
    );

    if tg_op = 'DELETE' then return old; end if;
    return new;
end;
$$;

revoke all on function private.audit_plan_item() from public;
revoke all on function private.audit_source_item() from public;
revoke all on function private.audit_member() from public;

commit;
