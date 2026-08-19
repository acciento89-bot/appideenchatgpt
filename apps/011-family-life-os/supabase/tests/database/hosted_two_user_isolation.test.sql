begin;

create extension if not exists pgtap with schema extensions;

select plan(14);

insert into auth.users (id, email) values
    ('55555555-5555-4555-8555-555555555555', 'family-a@example.test'),
    ('66666666-6666-4666-8666-666666666666', 'family-b@example.test');

create temporary table isolation_ids (
    label text primary key,
    id uuid not null
) on commit drop;

grant select, insert, update on isolation_ids to authenticated;

-- -----------------------------------------------------------------------------
-- User A: bootstrap a household and create one school-letter source.
-- -----------------------------------------------------------------------------

set local role authenticated;
set local request.jwt.claim.sub = '55555555-5555-4555-8555-555555555555';

select lives_ok(
    $$select * from public.bootstrap_household('Familie A', 'Alex A')$$,
    'user A can bootstrap a household'
);

select lives_ok(
    $$select public.ingest_text_fixture(
        'Schulbrief Familie A',
        'Klassenfahrt am 18. September. 35 EUR bis 5. September. Einverständniserklärung bis 1. September. Lunchpaket mitbringen.'
    )$$,
    'user A can create the hosted text fixture'
);

select is(
    (select count(*) from public.households),
    1::bigint,
    'user A can see exactly one household'
);

select is(
    (select count(*) from public.source_items where display_title = 'Schulbrief Familie A'),
    1::bigint,
    'user A can see its own source'
);

select is(
    (select count(*) from public.action_proposals),
    4::bigint,
    'user A can see exactly the four proposals from its source'
);

insert into isolation_ids(label, id)
select 'source_a', id
from public.source_items
where display_title = 'Schulbrief Familie A';

-- -----------------------------------------------------------------------------
-- User B: must start with no visibility into A, then receive an isolated family.
-- -----------------------------------------------------------------------------

set local request.jwt.claim.sub = '66666666-6666-4666-8666-666666666666';

select is(
    (select count(*) from public.source_items),
    0::bigint,
    'user B cannot see user A sources before bootstrap'
);

select lives_ok(
    $$select * from public.bootstrap_household('Familie B', 'Bianca B')$$,
    'user B can bootstrap a separate household'
);

select is(
    (select count(*) from public.households),
    1::bigint,
    'user B can see exactly one household after bootstrap'
);

select lives_ok(
    $$select public.ingest_text_fixture(
        'Schulbrief Familie B',
        'Klassenfahrt am 18. September. 35 EUR bis 5. September. Einverständniserklärung bis 1. September. Lunchpaket mitbringen.'
    )$$,
    'user B can create its own hosted text fixture'
);

select is(
    (select count(*) from public.source_items where display_title = 'Schulbrief Familie B'),
    1::bigint,
    'user B can see its own source'
);

select is(
    (select count(*) from public.source_items where display_title = 'Schulbrief Familie A'),
    0::bigint,
    'user B cannot read user A source by title'
);

update public.source_items
set display_title = 'Fremdzugriff gelungen'
where id = (select id from isolation_ids where label = 'source_a');

select is(
    (select count(*) from public.source_items where display_title = 'Fremdzugriff gelungen'),
    0::bigint,
    'user B cannot update user A source through RLS'
);

-- -----------------------------------------------------------------------------
-- Switch back to A and prove B stayed invisible and A data stayed unchanged.
-- -----------------------------------------------------------------------------

set local request.jwt.claim.sub = '55555555-5555-4555-8555-555555555555';

select is(
    (select count(*) from public.source_items where display_title = 'Schulbrief Familie B'),
    0::bigint,
    'user A cannot read user B source'
);

select is(
    (
        select display_title
        from public.source_items
        where id = (select id from isolation_ids where label = 'source_a')
    ),
    'Schulbrief Familie A'::text,
    'user A source remains unchanged after user B mutation attempt'
);

select * from finish();
rollback;
