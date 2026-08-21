begin;

create extension if not exists pgtap with schema extensions;

select plan(7);

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
        'Elternabend',
        'Elternabend am 21.08.2026 um 18:00 Uhr.',
        'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'::uuid
    )$$,
    'first source creation with client request id succeeds'
);

select lives_ok(
    $$select * from public.create_source_item(
        'text',
        'Elternabend',
        'Elternabend am 21.08.2026 um 18:00 Uhr.',
        'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'::uuid
    )$$,
    'retry with the same client request id succeeds'
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
                'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'::uuid
            )
            union all
            select * from public.create_source_item(
                'text',
                'Elternabend',
                'Elternabend am 21.08.2026 um 18:00 Uhr.',
                'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'::uuid
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
        'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'::uuid
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
