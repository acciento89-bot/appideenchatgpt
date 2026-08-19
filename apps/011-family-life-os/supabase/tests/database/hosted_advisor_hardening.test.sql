begin;

create extension if not exists pgtap with schema extensions;

select plan(6);

select is(
    (
        select p.prosecdef
        from pg_proc p
        join pg_namespace n on n.oid = p.pronamespace
        where n.nspname = 'public'
          and p.proname = 'confirm_action_proposals'
          and pg_get_function_identity_arguments(p.oid) = 'p_source_item_id uuid, p_proposal_ids uuid[]'
    ),
    false,
    'public confirmation RPC runs as SECURITY INVOKER'
);

select is(
    (
        select p.prosecdef
        from pg_proc p
        join pg_namespace n on n.oid = p.pronamespace
        where n.nspname = 'private'
          and p.proname = 'confirm_action_proposals_impl'
          and pg_get_function_identity_arguments(p.oid) = 'p_source_item_id uuid, p_proposal_ids uuid[]'
    ),
    true,
    'privileged confirmation implementation is isolated in private schema'
);

select is(
    has_function_privilege(
        'anon',
        'public.confirm_action_proposals(uuid,uuid[])',
        'EXECUTE'
    ),
    false,
    'anon cannot execute confirmation RPC'
);

select is(
    has_function_privilege(
        'authenticated',
        'public.confirm_action_proposals(uuid,uuid[])',
        'EXECUTE'
    ),
    true,
    'authenticated users can execute the reviewed confirmation RPC'
);

select is(
    (
        select count(*)
        from pg_policies
        where schemaname = 'public'
          and tablename = 'reminders'
          and roles = array['authenticated']::name[]
          and cmd = 'SELECT'
    ),
    1::bigint,
    'reminders have a single authenticated SELECT policy'
);

select is(
    (
        select count(*)
        from pg_indexes
        where schemaname = 'public'
          and indexname in (
              'action_proposals_extraction_run_id_idx',
              'households_created_by_idx',
              'plan_items_created_by_member_id_idx',
              'reminders_plan_item_id_idx'
          )
    ),
    4::bigint,
    'hosted advisor foreign-key indexes exist'
);

select * from finish();
rollback;
