begin;

create extension if not exists pgtap with schema extensions;

select plan(23);

select is(
    has_function_privilege('anon', 'public.create_source_item(text,text,text,uuid,uuid)', 'execute'),
    false,
    'anonymous role cannot execute idempotent source creation RPC'
);

select is(
    has_function_privilege('anon', 'public.finalize_source_upload(uuid,text,text,text,bigint,text,boolean)', 'execute'),
    false,
    'anonymous role cannot execute deferred source finalization RPC'
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

select is(
    (select processing_status from public.source_items where display_title = 'Legacy kompatibel' limit 1),
    'processing',
    'legacy text creation preserves historical processing state'
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

select is(
    (select processing_status from public.source_items where client_request_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'::uuid),
    'queued',
    'durable text source stays queued until Edge processing actually starts'
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
    'two distinct client request ids produce two canonical sources before file test'
);

select lives_ok(
    $$select * from public.create_source_item(
        'pdf',
        'Offline PDF',
        null,
        'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'::uuid,
        (select id from public.households limit 1)
    )$$,
    'durable file source can be created for the current household'
);

select is(
    (select processing_status from public.source_items where client_request_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'::uuid),
    'uploading',
    'durable file source starts in uploading state'
);

select lives_ok(
    $$select public.finalize_source_upload(
        (select id from public.source_items where client_request_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'::uuid),
        'households/' || (select household_id::text from public.source_items where client_request_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'::uuid) ||
            '/sources/' || (select id::text from public.source_items where client_request_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'::uuid) || '/queued.pdf',
        'queued.pdf',
        'application/pdf',
        123,
        'OCR text',
        true
    )$$,
    'durable file finalization may defer processing until Edge invocation'
);

select is(
    (select processing_status from public.source_items where client_request_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'::uuid),
    'queued',
    'deferred finalization leaves source queued'
);

select is(
    (select processing_attempts from public.source_items where client_request_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'::uuid),
    0,
    'deferred finalization does not claim a processing attempt'
);

select ok(
    (select last_processing_started_at is null from public.source_items where client_request_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'::uuid),
    'deferred finalization does not start the processing lease clock'
);

select lives_ok(
    $$select public.finalize_source_upload(
        (select id from public.source_items where client_request_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'::uuid),
        'households/' || (select household_id::text from public.source_items where client_request_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'::uuid) ||
            '/sources/' || (select id::text from public.source_items where client_request_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'::uuid) || '/legacy.pdf',
        'legacy.pdf',
        'application/pdf',
        124,
        'OCR text legacy'
    )$$,
    'existing six-argument finalization remains compatible'
);

select is(
    (select processing_status from public.source_items where client_request_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'::uuid),
    'processing',
    'legacy finalization still claims processing immediately'
);

select is(
    (select processing_attempts from public.source_items where client_request_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'::uuid),
    1,
    'legacy finalization increments processing attempt count'
);

select ok(
    (select last_processing_started_at is not null from public.source_items where client_request_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'::uuid),
    'legacy finalization starts the processing lease clock'
);

select * from finish();
rollback;
