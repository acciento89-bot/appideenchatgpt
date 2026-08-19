begin;

create or replace function public.bootstrap_household(
    p_household_name text,
    p_display_name text
)
returns table(household_id uuid, member_id uuid)
language plpgsql
security invoker
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_household_id uuid;
    v_member_id uuid;
begin
    if v_user_id is null then raise exception 'Authentication required'; end if;

    select hm.household_id, hm.id
      into v_household_id, v_member_id
      from public.household_members hm
     where hm.user_id = v_user_id
       and hm.invite_status = 'active'
     order by hm.created_at
     limit 1;

    if v_household_id is null then
        insert into public.households(name, created_by)
        values (coalesce(nullif(trim(p_household_name), ''), 'Meine Familie'), v_user_id)
        returning id into v_household_id;

        insert into public.household_members(
            household_id, user_id, display_name, role, accent_key, invite_status
        ) values (
            v_household_id,
            v_user_id,
            coalesce(nullif(trim(p_display_name), ''), 'Ich'),
            'owner',
            'indigo',
            'active'
        )
        returning id into v_member_id;
    end if;

    household_id := v_household_id;
    member_id := v_member_id;
    return next;
end;
$$;

revoke execute on function public.bootstrap_household(text, text) from public, anon;
grant execute on function public.bootstrap_household(text, text) to authenticated;

create or replace function private.ingest_text_fixture_impl(
    p_title text,
    p_text text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_household_id uuid;
    v_actor_member_id uuid;
    v_source_id uuid;
    v_run_id uuid;
    v_event_id uuid := gen_random_uuid();
    v_deadline_id uuid := gen_random_uuid();
    v_payment_id uuid := gen_random_uuid();
    v_preparation_id uuid := gen_random_uuid();
begin
    if v_user_id is null then raise exception 'Authentication required'; end if;
    if nullif(trim(p_text), '') is null then raise exception 'Text is required'; end if;

    select hm.household_id, hm.id
      into v_household_id, v_actor_member_id
      from public.household_members hm
     where hm.user_id = v_user_id
       and hm.invite_status = 'active'
       and hm.role in ('owner', 'adult')
     order by case hm.role when 'owner' then 0 else 1 end, hm.created_at
     limit 1;

    if v_household_id is null or v_actor_member_id is null then
        raise exception 'Active adult household member not found';
    end if;

    if not (select private.can_manage_household(v_household_id)) then
        raise exception 'Insufficient household permission';
    end if;

    insert into public.source_items(
        household_id, created_by_member_id, source_type, display_title,
        original_text, processing_status, processed_at
    ) values (
        v_household_id,
        v_actor_member_id,
        'text',
        coalesce(nullif(trim(p_title), ''), 'Textimport'),
        p_text,
        'review',
        now()
    ) returning id into v_source_id;

    insert into public.extraction_runs(
        source_item_id, provider, model, schema_version, normalized_output,
        status, created_at, completed_at
    ) values (
        v_source_id,
        'fixture',
        'school-letter-v1',
        1,
        jsonb_build_object('fixture', true, 'proposal_count', 4),
        'succeeded',
        now(),
        now()
    ) returning id into v_run_id;

    insert into public.action_proposals(
        id, source_item_id, extraction_run_id, kind, title, starts_at, ends_at,
        due_at, all_day, location, notes, amount_minor, currency,
        unresolved_fields, is_included, review_status
    ) values
    (
        v_event_id, v_source_id, v_run_id, 'event', 'Klassenfahrt Freilichtmuseum',
        '2026-09-18 07:30:00+02', '2026-09-18 17:00:00+02', null, false,
        'Haupteingang der Schule', null, null, null,
        '{"member":"required"}'::jsonb, true, 'proposed'
    ),
    (
        v_deadline_id, v_source_id, v_run_id, 'deadline', 'Einverständniserklärung abgeben',
        null, null, '2026-09-01 23:59:00+02', false,
        null, null, null, null,
        '{}'::jsonb, true, 'proposed'
    ),
    (
        v_payment_id, v_source_id, v_run_id, 'payment', '35 € Klassenfahrt bezahlen',
        null, null, '2026-09-05 12:00:00+02', false,
        null, null, 3500, 'EUR',
        '{}'::jsonb, true, 'proposed'
    ),
    (
        v_preparation_id, v_source_id, v_run_id, 'preparation', 'Lunchpaket und Trinkflasche vorbereiten',
        null, null, '2026-09-17 19:00:00+02', false,
        null, 'Wetterfeste Kleidung', null, null,
        '{}'::jsonb, true, 'proposed'
    );

    insert into public.action_proposal_assignees(proposal_id, member_id)
    select p.proposal_id, hm.id
      from (values (v_deadline_id), (v_payment_id), (v_preparation_id)) as p(proposal_id)
      join public.household_members hm on hm.household_id = v_household_id
     where hm.role in ('owner', 'adult')
       and hm.invite_status = 'active';

    return v_source_id;
end;
$$;

revoke all on function private.ingest_text_fixture_impl(text, text) from public, anon;
grant execute on function private.ingest_text_fixture_impl(text, text) to authenticated;

create or replace function public.ingest_text_fixture(
    p_title text,
    p_text text
)
returns uuid
language sql
security invoker
set search_path = ''
as $$
    select private.ingest_text_fixture_impl(p_title, p_text);
$$;

revoke execute on function public.ingest_text_fixture(text, text) from public, anon;
grant execute on function public.ingest_text_fixture(text, text) to authenticated;

commit;
