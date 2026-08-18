begin;

create extension if not exists pgtap with schema extensions;

select plan(12);

select has_table('public', 'households', 'households table exists');
select has_table('public', 'source_items', 'source_items table exists');
select has_table('public', 'action_proposals', 'action_proposals table exists');
select has_table('public', 'plan_items', 'plan_items table exists');

-- -----------------------------------------------------------------------------
-- Seed two isolated households as the database owner. Test rows are rolled back.
-- -----------------------------------------------------------------------------

insert into auth.users (id, email) values
    ('11111111-1111-4111-8111-111111111111', 'owner-a@example.test'),
    ('22222222-2222-4222-8222-222222222222', 'owner-b@example.test'),
    ('33333333-3333-4333-8333-333333333333', 'child-a@example.test');

insert into public.households (id, name, created_by) values
    ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Household A', '11111111-1111-4111-8111-111111111111'),
    ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'Household B', '22222222-2222-4222-8222-222222222222');

insert into public.household_members (id, household_id, user_id, display_name, role, accent_key) values
    ('a1000000-0000-4000-8000-000000000001', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111111', 'Owner A', 'owner', 'indigo'),
    ('a1000000-0000-4000-8000-000000000002', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '33333333-3333-4333-8333-333333333333', 'Child A Login', 'child', 'orange'),
    ('a1000000-0000-4000-8000-000000000003', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', null, 'Child A No Login', 'child', 'purple'),
    ('a1000000-0000-4000-8000-000000000004', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', null, 'Child A2 No Login', 'child', 'teal'),
    ('b1000000-0000-4000-8000-000000000001', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', '22222222-2222-4222-8222-222222222222', 'Owner B', 'owner', 'teal');

select is(
    (select count(*) from public.household_members where household_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa' and user_id is null),
    2::bigint,
    'a household can contain multiple child profiles without login users'
);

insert into public.source_items (
    id,
    household_id,
    created_by_member_id,
    source_type,
    display_title,
    original_text,
    processing_status
) values
    (
        'a2000000-0000-4000-8000-000000000001',
        'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'a1000000-0000-4000-8000-000000000001',
        'text',
        'Ready source A',
        'Klassenfahrt 35,00 Einverständniserklärung',
        'review'
    ),
    (
        'a2000000-0000-4000-8000-000000000002',
        'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'a1000000-0000-4000-8000-000000000001',
        'text',
        'Unresolved source A',
        'Ambiguous child',
        'review'
    ),
    (
        'b2000000-0000-4000-8000-000000000001',
        'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        'b1000000-0000-4000-8000-000000000001',
        'text',
        'Source B',
        'Private household B text',
        'review'
    );

insert into public.action_proposals (
    id,
    source_item_id,
    kind,
    title,
    due_at,
    unresolved_fields,
    is_included,
    review_status
) values
    (
        'a3000000-0000-4000-8000-000000000001',
        'a2000000-0000-4000-8000-000000000001',
        'payment',
        '35 EUR Klassenfahrt bezahlen',
        '2026-09-05T12:00:00+02',
        '{}'::jsonb,
        true,
        'proposed'
    ),
    (
        'a3000000-0000-4000-8000-000000000002',
        'a2000000-0000-4000-8000-000000000002',
        'event',
        'Ambiguous event',
        '2026-09-18T07:30:00+02',
        '{"member":"required"}'::jsonb,
        true,
        'proposed'
    );

insert into public.action_proposal_assignees (proposal_id, member_id) values
    ('a3000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001');

-- -----------------------------------------------------------------------------
-- Household A owner: RLS isolation and confirm behavior.
-- -----------------------------------------------------------------------------

set local role authenticated;
set local request.jwt.claim.sub = '11111111-1111-4111-8111-111111111111';

select results_eq(
    $$select id from public.households order by id$$,
    $$values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'::uuid)$$,
    'owner A can only read household A'
);

select results_eq(
    $$select id from public.source_items order by id$$,
    $$values
        ('a2000000-0000-4000-8000-000000000001'::uuid),
        ('a2000000-0000-4000-8000-000000000002'::uuid)$$,
    'owner A cannot read household B source rows'
);

select throws_ok(
    $$select * from public.confirm_action_proposals(
        'a2000000-0000-4000-8000-000000000002'::uuid,
        array['a3000000-0000-4000-8000-000000000002'::uuid]
    )$$,
    'P0001',
    'Selected proposal is missing, unresolved, excluded, or rejected',
    'unresolved proposal cannot be confirmed'
);

select lives_ok(
    $$select * from public.confirm_action_proposals(
        'a2000000-0000-4000-8000-000000000001'::uuid,
        array['a3000000-0000-4000-8000-000000000001'::uuid]
    )$$,
    'ready proposal can be confirmed'
);

select lives_ok(
    $$select * from public.confirm_action_proposals(
        'a2000000-0000-4000-8000-000000000001'::uuid,
        array['a3000000-0000-4000-8000-000000000001'::uuid]
    )$$,
    'confirm retry is idempotent and does not fail'
);

select is(
    (select count(*) from public.plan_items where source_proposal_id = 'a3000000-0000-4000-8000-000000000001'),
    1::bigint,
    'confirm retry creates only one canonical plan item'
);

-- -----------------------------------------------------------------------------
-- Child login in household A: read membership is fine, adult mutation is not.
-- -----------------------------------------------------------------------------

set local request.jwt.claim.sub = '33333333-3333-4333-8333-333333333333';

select is(
    (select private.can_manage_household('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa')),
    false,
    'child role cannot manage household data'
);

select * from finish();
rollback;
