begin;

create extension if not exists pgtap with schema extensions;

select plan(10);

select is(
    has_function_privilege('anon', 'public.create_source_item(text,text,text,uuid,uuid)', 'execute'),
    false,
    'anonymous role cannot execute idempotent source creation RPC'
);

insert into auth.users (id, email)
values ('77777777-7777-4777-8777-777777777777', 'offline-idempotency@example.test');

set local role authenticated;
set local request.jwt.claim.sub = '77777777-7777-4777-8777-777777777777';

select lives_ok(
    $$select * from public.bootstrap_household('Offline Familie', 'Offline Owner')$$,
    'authenticated user can bootstrap household'
);

select lives_ok(
    $$select * from public.create_source_item(
        'text',
        'Legacy kompatibel',
        'Bestehende Drei-Parameter-Clients funktionieren weiter.'
    )$$,
    'existing three-argument clients remain compatible'
);

select throws_ok(
    $$select * from public.create_source_item(
        'text',
        'Falscher Haushalt',
        'Darf nicht angelegt werden.',
        'cccccccc-cccc-4ccc-8ccc-cccccccccccc'::uuid,
        'dddddddd-dddd-4ddd-8ddd-dddddddddddd'::uuid
    )$$,
    'Active adult household member not found',
    'client cannot route an offline source into a household it does not belong to'
);

select lives_ok(
    $$select * from public.create_source_item(
        'text',
        'Elternabend',
        'Elternabend am 21.08.2026 um 18:00 Uhr.',
        'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'::uuid,
        (select id from public.households limit 1)
    )$$,
    'first household-bound source creation with client request id succeeds'
);

select lives_ok(
    $$select * from public.create_source_item(
        'text',
        'Elternabend',
        'Elternabend am 21.08.2026 um 18:00 Uhr.',
        'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'::uuid,
        (select id from public.households limit 1)
    )$$,
    'retry with the same client request id and household succeeds'
);

select is(
    (select count(*) from public.source_items where client_request_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'::uuid),
    1::bigint,
    'same client request id creates exactly one source item'
);

select is(
    (
        select count(distinct source_item_id)
        from (
            select * from public.create_source_item(
                'text',
                'Elternabend',
                'Elternabend am 21.08.2026 um 18:00 Uhr.',
                'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'::uuid,
                (select id from public.households limit 1)
            )
            union all
            select * from public.create_source_item(
                'text',
                'Elternabend',
                'Elternabend am 21.08.2026 um 18:00 Uhr.',
                'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'::uuid,
                (select id from public.households limit 1)
            )
        ) retried
    ),
    1::bigint,
    'retries return the same canonical source id'
);

select lives_ok(
    $$select * from public.create_source_item(
        'text',
        'Zweiter Import',
        'Andere Quelle',
        'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'::uuid,
        (select id from public.households limit 1)
    )$$,
    'a different client request id creates another source'
);

select is(
    (select count(*) from public.source_items where client_request_id is not null),
    2::bigint,
    'two distinct client request ids produce two canonical sources'
);

select * from finish();
rollback;
