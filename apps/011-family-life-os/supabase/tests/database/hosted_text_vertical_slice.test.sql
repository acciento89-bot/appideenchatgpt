begin;

create extension if not exists pgtap with schema extensions;

select plan(13);

insert into auth.users (id, email)
values ('44444444-4444-4444-8444-444444444444', 'hosted-slice@example.test');

set local role authenticated;
set local request.jwt.claim.sub = '44444444-4444-4444-8444-444444444444';

select lives_ok(
    $$select * from public.bootstrap_household('Familie Test', 'Mara Test')$$,
    'authenticated user can bootstrap a household'
);

select lives_ok(
    $$select * from public.bootstrap_household('Ignored second name', 'Ignored')$$,
    'household bootstrap is idempotent'
);

select is(
    (select count(*) from public.households),
    1::bigint,
    'bootstrap creates exactly one household'
);

select is(
    (select count(*) from public.household_members where user_id = '44444444-4444-4444-8444-444444444444'),
    1::bigint,
    'bootstrap creates exactly one owner membership'
);

insert into public.household_members(
    household_id, user_id, display_name, role, accent_key, invite_status
)
select id, null, 'Lina Test', 'child', 'orange', 'active'
from public.households
limit 1;

select lives_ok(
    $$select public.ingest_text_fixture(
        'Klassenfahrt 6b · Text',
        'Klassenfahrt am 18. September. 35 EUR bis 5. September. Einverständniserklärung bis 1. September. Lunchpaket mitbringen.'
    )$$,
    'authenticated adult can ingest the server-side text fixture'
);

select is(
    (select count(*) from public.source_items where source_type = 'text' and processing_status = 'review'),
    1::bigint,
    'fixture creates one reviewable text source'
);

select is(
    (select count(*) from public.extraction_runs where provider = 'fixture' and model = 'school-letter-v1' and status = 'succeeded'),
    1::bigint,
    'fixture creates one auditable extraction run'
);

select is(
    (select count(*) from public.action_proposals where review_status = 'proposed'),
    4::bigint,
    'fixture creates exactly four proposals'
);

select is(
    (select count(*) from public.action_proposals where unresolved_fields = '{"member":"required"}'::jsonb),
    1::bigint,
    'exactly the event requires a member decision'
);

update public.action_proposals
set unresolved_fields = '{}'::jsonb
where kind = 'event';

insert into public.action_proposal_assignees(proposal_id, member_id)
select p.id, hm.id
from public.action_proposals p
cross join public.household_members hm
where p.kind = 'event'
  and hm.role = 'child'
  and hm.display_name = 'Lina Test';

select lives_ok(
    $$select * from public.confirm_action_proposals(
        (select id from public.source_items where source_type = 'text' limit 1),
        array(select id from public.action_proposals where is_included and review_status = 'proposed' order by created_at, id)
    )$$,
    'reviewed fixture proposals confirm through the canonical RPC'
);

select is(
    (select count(*) from public.plan_items),
    4::bigint,
    'confirmation creates four canonical plan items'
);

select is(
    (select processing_status from public.source_items where source_type = 'text' limit 1),
    'done'::text,
    'source is done after all proposals are confirmed'
);

select lives_ok(
    $$select * from public.confirm_action_proposals(
        (select id from public.source_items where source_type = 'text' limit 1),
        array(select id from public.action_proposals where review_status = 'confirmed' order by created_at, id)
    )$$,
    'confirmation retry remains idempotent'
);

select * from finish();
rollback;
