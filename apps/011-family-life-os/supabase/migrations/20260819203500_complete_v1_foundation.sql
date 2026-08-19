-- Family Life OS / candidate #011
-- Complete v1 backend foundation: private attachments, secure invites,
-- activity history, notification preferences/device registry, realtime,
-- billing/usage read models and source-ingestion RPCs.

begin;

create extension if not exists pgcrypto with schema extensions;

-- -----------------------------------------------------------------------------
-- Existing core extensions
-- -----------------------------------------------------------------------------

alter table public.source_items
    add column if not exists content_type text,
    add column if not exists file_name text,
    add column if not exists size_bytes bigint check (size_bytes is null or size_bytes >= 0),
    add column if not exists extracted_text text,
    add column if not exists archived_at timestamptz,
    add column if not exists processing_attempts integer not null default 0 check (processing_attempts >= 0),
    add column if not exists last_processing_started_at timestamptz;

alter table public.plan_items
    add column if not exists version bigint not null default 1 check (version > 0);

-- -----------------------------------------------------------------------------
-- New v1 tables
-- -----------------------------------------------------------------------------

create table if not exists public.source_attachments (
    id uuid primary key default gen_random_uuid(),
    household_id uuid not null references public.households(id) on delete cascade,
    source_item_id uuid not null references public.source_items(id) on delete cascade,
    storage_path text not null unique,
    file_name text not null,
    content_type text not null,
    size_bytes bigint not null check (size_bytes >= 0 and size_bytes <= 26214400),
    sha256 text,
    created_at timestamptz not null default now()
);

create index if not exists source_attachments_household_idx
    on public.source_attachments(household_id, created_at desc);
create index if not exists source_attachments_source_idx
    on public.source_attachments(source_item_id);

create table if not exists public.household_invites (
    id uuid primary key default gen_random_uuid(),
    household_id uuid not null references public.households(id) on delete cascade,
    created_by_member_id uuid not null references public.household_members(id) on delete restrict,
    role text not null check (role in ('adult', 'guest')),
    token_hash text not null unique,
    expires_at timestamptz not null,
    accepted_at timestamptz,
    accepted_by_user_id uuid references auth.users(id) on delete set null,
    revoked_at timestamptz,
    created_at timestamptz not null default now()
);

create index if not exists household_invites_household_idx
    on public.household_invites(household_id, created_at desc);
create index if not exists household_invites_active_idx
    on public.household_invites(token_hash)
    where accepted_at is null and revoked_at is null;

create table if not exists public.activity_log (
    id uuid primary key default gen_random_uuid(),
    household_id uuid not null references public.households(id) on delete cascade,
    actor_user_id uuid references auth.users(id) on delete set null,
    actor_member_id uuid references public.household_members(id) on delete set null,
    entity_type text not null check (entity_type in ('plan_item', 'source_item', 'member', 'invite', 'reminder', 'household')),
    entity_id uuid not null,
    action text not null,
    metadata jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now()
);

create index if not exists activity_log_household_created_idx
    on public.activity_log(household_id, created_at desc);

create table if not exists public.notification_preferences (
    household_id uuid not null references public.households(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    event_reminders boolean not null default true,
    task_reminders boolean not null default true,
    preparation_reminders boolean not null default true,
    assignment_updates boolean not null default true,
    inbox_review boolean not null default true,
    daily_digest boolean not null default true,
    quiet_start time,
    quiet_end time,
    updated_at timestamptz not null default now(),
    primary key (household_id, user_id)
);

create table if not exists public.device_tokens (
    id uuid primary key default gen_random_uuid(),
    household_id uuid not null references public.households(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    platform text not null default 'ios' check (platform in ('ios')),
    token text not null,
    environment text not null default 'sandbox' check (environment in ('sandbox', 'production')),
    app_version text,
    build_number text,
    last_seen_at timestamptz not null default now(),
    created_at timestamptz not null default now(),
    unique (user_id, token)
);

create index if not exists device_tokens_household_user_idx
    on public.device_tokens(household_id, user_id);

create table if not exists public.household_entitlements (
    household_id uuid primary key references public.households(id) on delete cascade,
    tier text not null default 'free' check (tier in ('free', 'pro')),
    product_id text,
    original_transaction_id text,
    expires_at timestamptz,
    updated_at timestamptz not null default now()
);

create table if not exists public.household_usage_monthly (
    household_id uuid not null references public.households(id) on delete cascade,
    period_start date not null,
    ai_imports integer not null default 0 check (ai_imports >= 0),
    storage_bytes bigint not null default 0 check (storage_bytes >= 0),
    updated_at timestamptz not null default now(),
    primary key (household_id, period_start)
);

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

create or replace function private.current_household_member_id(p_household_id uuid)
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
    select hm.id
    from public.household_members hm
    where hm.household_id = p_household_id
      and hm.user_id = (select auth.uid())
      and hm.invite_status = 'active'
    order by case hm.role when 'owner' then 0 when 'adult' then 1 else 2 end, hm.created_at
    limit 1;
$$;

create or replace function private.storage_path_household_id(p_name text)
returns uuid
language plpgsql
immutable
security invoker
set search_path = ''
as $$
declare
    v_segment text;
begin
    if split_part(p_name, '/', 1) <> 'households' then
        return null;
    end if;
    v_segment := split_part(p_name, '/', 2);
    if v_segment !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' then
        return null;
    end if;
    return v_segment::uuid;
exception when others then
    return null;
end;
$$;

create or replace function private.bump_plan_version()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
    if row(new.*) is distinct from row(old.*) then
        new.version := old.version + 1;
    end if;
    return new;
end;
$$;

revoke all on function private.current_household_member_id(uuid) from public, anon;
revoke all on function private.storage_path_household_id(text) from public, anon;
revoke all on function private.bump_plan_version() from public;
grant execute on function private.current_household_member_id(uuid) to authenticated;
grant execute on function private.storage_path_household_id(text) to authenticated;

create or replace trigger plan_items_bump_version
before update on public.plan_items
for each row execute function private.bump_plan_version();

-- -----------------------------------------------------------------------------
-- Activity logging. Metadata intentionally excludes raw family-document content.
-- -----------------------------------------------------------------------------

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
    v_row := case when tg_op = 'DELETE' then old else new end;
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
    return coalesce(new, old);
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
    v_row := case when tg_op = 'DELETE' then old else new end;
    if tg_op = 'INSERT' then
        v_action := 'created';
    elsif tg_op = 'DELETE' then
        v_action := 'deleted';
    elsif old.processing_status is distinct from new.processing_status then
        v_action := 'status_' || new.processing_status;
    elsif old.archived_at is distinct from new.archived_at then
        v_action := case when new.archived_at is null then 'restored' else 'archived' end;
    else
        return coalesce(new, old);
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
    return coalesce(new, old);
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
    v_action text;
begin
    v_row := case when tg_op = 'DELETE' then old else new end;
    v_action := lower(tg_op);
    insert into public.activity_log(
        household_id, actor_user_id, actor_member_id, entity_type, entity_id, action, metadata
    ) values (
        v_row.household_id,
        (select auth.uid()),
        private.current_household_member_id(v_row.household_id),
        'member',
        v_row.id,
        v_action,
        jsonb_build_object('role', v_row.role, 'invite_status', v_row.invite_status)
    );
    return coalesce(new, old);
end;
$$;

revoke all on function private.audit_plan_item() from public;
revoke all on function private.audit_source_item() from public;
revoke all on function private.audit_member() from public;

create or replace trigger plan_items_audit
after insert or update or delete on public.plan_items
for each row execute function private.audit_plan_item();

create or replace trigger source_items_audit
after insert or update or delete on public.source_items
for each row execute function private.audit_source_item();

create or replace trigger household_members_audit
after insert or update or delete on public.household_members
for each row execute function private.audit_member();

-- -----------------------------------------------------------------------------
-- Secure invitation RPCs. Only a hash is stored; the raw token is returned once.
-- -----------------------------------------------------------------------------

create or replace function public.create_household_invite(
    p_household_id uuid,
    p_role text default 'adult',
    p_expires_hours integer default 168
)
returns table(invite_id uuid, invite_token text, expires_at timestamptz)
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_token text;
    v_invite_id uuid;
    v_expires timestamptz;
    v_actor_member_id uuid;
begin
    if (select auth.uid()) is null then raise exception 'Authentication required'; end if;
    if p_role not in ('adult', 'guest') then raise exception 'Unsupported invite role'; end if;
    if p_expires_hours < 1 or p_expires_hours > 720 then raise exception 'Invalid invite lifetime'; end if;
    if not private.is_household_owner(p_household_id) then raise exception 'Owner permission required'; end if;

    v_actor_member_id := private.current_household_member_id(p_household_id);
    if v_actor_member_id is null then raise exception 'Active household member not found'; end if;

    v_token := encode(extensions.gen_random_bytes(24), 'hex');
    v_expires := now() + make_interval(hours => p_expires_hours);

    insert into public.household_invites(
        household_id, created_by_member_id, role, token_hash, expires_at
    ) values (
        p_household_id,
        v_actor_member_id,
        p_role,
        encode(extensions.digest(v_token, 'sha256'), 'hex'),
        v_expires
    ) returning id into v_invite_id;

    insert into public.activity_log(
        household_id, actor_user_id, actor_member_id, entity_type, entity_id, action, metadata
    ) values (
        p_household_id, (select auth.uid()), v_actor_member_id, 'invite', v_invite_id,
        'created', jsonb_build_object('role', p_role, 'expires_at', v_expires)
    );

    invite_id := v_invite_id;
    invite_token := v_token;
    expires_at := v_expires;
    return next;
end;
$$;

create or replace function public.accept_household_invite(
    p_token text,
    p_display_name text
)
returns table(household_id uuid, member_id uuid, role text)
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_invite public.household_invites%rowtype;
    v_member_id uuid;
    v_existing_role text;
    v_name text;
begin
    if v_user_id is null then raise exception 'Authentication required'; end if;
    if nullif(trim(p_token), '') is null then raise exception 'Invite token required'; end if;
    v_name := coalesce(nullif(trim(p_display_name), ''), 'Erwachsen');

    select * into v_invite
      from public.household_invites i
     where i.token_hash = encode(extensions.digest(p_token, 'sha256'), 'hex')
       and i.accepted_at is null
       and i.revoked_at is null
       and i.expires_at > now()
     for update;

    if v_invite.id is null then raise exception 'Invite invalid or expired'; end if;

    select hm.id, hm.role into v_member_id, v_existing_role
      from public.household_members hm
     where hm.household_id = v_invite.household_id
       and hm.user_id = v_user_id
       and hm.invite_status = 'active'
     limit 1;

    if v_member_id is null then
        insert into public.household_members(
            household_id, user_id, display_name, role, accent_key, invite_status
        ) values (
            v_invite.household_id,
            v_user_id,
            v_name,
            v_invite.role,
            case v_invite.role when 'adult' then 'teal' else 'purple' end,
            'active'
        ) returning id, household_members.role into v_member_id, v_existing_role;
    end if;

    update public.household_invites
       set accepted_at = now(), accepted_by_user_id = v_user_id
     where id = v_invite.id;

    insert into public.activity_log(
        household_id, actor_user_id, actor_member_id, entity_type, entity_id, action, metadata
    ) values (
        v_invite.household_id, v_user_id, v_member_id, 'invite', v_invite.id,
        'accepted', jsonb_build_object('role', v_existing_role)
    );

    household_id := v_invite.household_id;
    member_id := v_member_id;
    role := v_existing_role;
    return next;
end;
$$;

create or replace function public.revoke_household_invite(p_invite_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_household_id uuid;
begin
    select i.household_id into v_household_id
      from public.household_invites i
     where i.id = p_invite_id;
    if v_household_id is null then raise exception 'Invite not found'; end if;
    if not private.is_household_owner(v_household_id) then raise exception 'Owner permission required'; end if;

    update public.household_invites
       set revoked_at = now()
     where id = p_invite_id and accepted_at is null;
end;
$$;

-- -----------------------------------------------------------------------------
-- Source-ingestion RPCs. Machine proposals remain server-owned.
-- -----------------------------------------------------------------------------

create or replace function public.create_source_item(
    p_source_type text,
    p_title text,
    p_original_text text default null
)
returns table(source_item_id uuid, household_id uuid, member_id uuid)
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_household_id uuid;
    v_member_id uuid;
    v_source_id uuid;
begin
    if (select auth.uid()) is null then raise exception 'Authentication required'; end if;
    if p_source_type not in ('image', 'pdf', 'text', 'voice', 'share') then raise exception 'Unsupported source type'; end if;
    if nullif(trim(p_title), '') is null then raise exception 'Title required'; end if;

    select hm.household_id, hm.id into v_household_id, v_member_id
      from public.household_members hm
     where hm.user_id = (select auth.uid())
       and hm.invite_status = 'active'
       and hm.role in ('owner', 'adult')
     order by case hm.role when 'owner' then 0 else 1 end, hm.created_at
     limit 1;

    if v_household_id is null or v_member_id is null then raise exception 'Active adult household member not found'; end if;
    if not private.can_manage_household(v_household_id) then raise exception 'Insufficient household permission'; end if;

    insert into public.source_items(
        household_id, created_by_member_id, source_type, display_title,
        original_text, processing_status, processing_attempts, last_processing_started_at
    ) values (
        v_household_id, v_member_id, p_source_type, trim(p_title), p_original_text,
        case when p_source_type = 'text' then 'processing' else 'uploading' end,
        case when p_source_type = 'text' then 1 else 0 end,
        case when p_source_type = 'text' then now() else null end
    ) returning id into v_source_id;

    source_item_id := v_source_id;
    household_id := v_household_id;
    member_id := v_member_id;
    return next;
end;
$$;

create or replace function public.finalize_source_upload(
    p_source_item_id uuid,
    p_storage_path text,
    p_file_name text,
    p_content_type text,
    p_size_bytes bigint,
    p_extracted_text text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_household_id uuid;
begin
    select s.household_id into v_household_id
      from public.source_items s
     where s.id = p_source_item_id;

    if v_household_id is null then raise exception 'Source item not found'; end if;
    if not private.can_manage_household(v_household_id) then raise exception 'Insufficient household permission'; end if;
    if private.storage_path_household_id(p_storage_path) is distinct from v_household_id then
        raise exception 'Storage path household mismatch';
    end if;
    if p_size_bytes < 0 or p_size_bytes > 26214400 then raise exception 'Attachment too large'; end if;

    update public.source_items
       set storage_path = p_storage_path,
           file_name = nullif(trim(p_file_name), ''),
           content_type = nullif(trim(p_content_type), ''),
           size_bytes = p_size_bytes,
           extracted_text = nullif(p_extracted_text, ''),
           processing_status = 'processing',
           processing_error_code = null,
           processing_attempts = processing_attempts + 1,
           last_processing_started_at = now()
     where id = p_source_item_id and household_id = v_household_id;

    insert into public.source_attachments(
        household_id, source_item_id, storage_path, file_name, content_type, size_bytes
    ) values (
        v_household_id, p_source_item_id, p_storage_path,
        coalesce(nullif(trim(p_file_name), ''), 'Quelle'),
        coalesce(nullif(trim(p_content_type), ''), 'application/octet-stream'),
        p_size_bytes
    ) on conflict (storage_path) do update
       set file_name = excluded.file_name,
           content_type = excluded.content_type,
           size_bytes = excluded.size_bytes;
end;
$$;

create or replace function public.retry_source_processing(
    p_source_item_id uuid,
    p_extracted_text text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_household_id uuid;
begin
    select s.household_id into v_household_id from public.source_items s where s.id = p_source_item_id;
    if v_household_id is null then raise exception 'Source item not found'; end if;
    if not private.can_manage_household(v_household_id) then raise exception 'Insufficient household permission'; end if;

    update public.source_items
       set processing_status = 'processing',
           processing_error_code = null,
           extracted_text = coalesce(nullif(p_extracted_text, ''), extracted_text),
           processing_attempts = processing_attempts + 1,
           last_processing_started_at = now()
     where id = p_source_item_id;
end;
$$;

create or replace function public.set_source_archived(
    p_source_item_id uuid,
    p_archived boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_household_id uuid;
begin
    select s.household_id into v_household_id from public.source_items s where s.id = p_source_item_id;
    if v_household_id is null then raise exception 'Source item not found'; end if;
    if not private.can_manage_household(v_household_id) then raise exception 'Insufficient household permission'; end if;
    update public.source_items
       set archived_at = case when p_archived then now() else null end
     where id = p_source_item_id;
end;
$$;

-- -----------------------------------------------------------------------------
-- RLS and grants for new tables
-- -----------------------------------------------------------------------------

alter table public.source_attachments enable row level security;
alter table public.household_invites enable row level security;
alter table public.activity_log enable row level security;
alter table public.notification_preferences enable row level security;
alter table public.device_tokens enable row level security;
alter table public.household_entitlements enable row level security;
alter table public.household_usage_monthly enable row level security;

create policy source_attachments_select
on public.source_attachments for select to authenticated
using (private.is_household_member(household_id));

create policy household_invites_select
on public.household_invites for select to authenticated
using (private.is_household_owner(household_id));

create policy activity_log_select
on public.activity_log for select to authenticated
using (private.is_household_member(household_id));

create policy notification_preferences_select
on public.notification_preferences for select to authenticated
using (user_id = (select auth.uid()) and private.is_household_member(household_id));
create policy notification_preferences_insert
on public.notification_preferences for insert to authenticated
with check (user_id = (select auth.uid()) and private.is_household_member(household_id));
create policy notification_preferences_update
on public.notification_preferences for update to authenticated
using (user_id = (select auth.uid()) and private.is_household_member(household_id))
with check (user_id = (select auth.uid()) and private.is_household_member(household_id));
create policy notification_preferences_delete
on public.notification_preferences for delete to authenticated
using (user_id = (select auth.uid()) and private.is_household_member(household_id));

create policy device_tokens_select
on public.device_tokens for select to authenticated
using (user_id = (select auth.uid()) and private.is_household_member(household_id));
create policy device_tokens_insert
on public.device_tokens for insert to authenticated
with check (user_id = (select auth.uid()) and private.is_household_member(household_id));
create policy device_tokens_update
on public.device_tokens for update to authenticated
using (user_id = (select auth.uid()) and private.is_household_member(household_id))
with check (user_id = (select auth.uid()) and private.is_household_member(household_id));
create policy device_tokens_delete
on public.device_tokens for delete to authenticated
using (user_id = (select auth.uid()) and private.is_household_member(household_id));

create policy household_entitlements_select
on public.household_entitlements for select to authenticated
using (private.is_household_member(household_id));

create policy household_usage_monthly_select
on public.household_usage_monthly for select to authenticated
using (private.is_household_member(household_id));

revoke all on public.source_attachments from authenticated;
grant select on public.source_attachments to authenticated;
revoke all on public.household_invites from authenticated;
grant select on public.household_invites to authenticated;
revoke all on public.activity_log from authenticated;
grant select on public.activity_log to authenticated;
grant select, insert, update, delete on public.notification_preferences to authenticated;
grant select, insert, update, delete on public.device_tokens to authenticated;
grant select on public.household_entitlements to authenticated;
grant select on public.household_usage_monthly to authenticated;

revoke execute on function public.create_household_invite(uuid, text, integer) from public, anon;
revoke execute on function public.accept_household_invite(text, text) from public, anon;
revoke execute on function public.revoke_household_invite(uuid) from public, anon;
revoke execute on function public.create_source_item(text, text, text) from public, anon;
revoke execute on function public.finalize_source_upload(uuid, text, text, text, bigint, text) from public, anon;
revoke execute on function public.retry_source_processing(uuid, text) from public, anon;
revoke execute on function public.set_source_archived(uuid, boolean) from public, anon;

grant execute on function public.create_household_invite(uuid, text, integer) to authenticated;
grant execute on function public.accept_household_invite(text, text) to authenticated;
grant execute on function public.revoke_household_invite(uuid) to authenticated;
grant execute on function public.create_source_item(text, text, text) to authenticated;
grant execute on function public.finalize_source_upload(uuid, text, text, text, bigint, text) to authenticated;
grant execute on function public.retry_source_processing(uuid, text) to authenticated;
grant execute on function public.set_source_archived(uuid, boolean) to authenticated;

-- -----------------------------------------------------------------------------
-- Private Storage bucket and household-path RLS.
-- Path: households/<household-id>/sources/<source-id>/<filename>
-- -----------------------------------------------------------------------------

insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values (
    'family-sources',
    'family-sources',
    false,
    26214400,
    array[
        'image/jpeg', 'image/png', 'image/heic', 'image/heif',
        'application/pdf', 'text/plain',
        'audio/m4a', 'audio/mp4', 'audio/x-m4a', 'audio/mpeg'
    ]::text[]
)
on conflict (id) do update
set public = false,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists family_sources_select on storage.objects;
drop policy if exists family_sources_insert on storage.objects;
drop policy if exists family_sources_update on storage.objects;
drop policy if exists family_sources_delete on storage.objects;

create policy family_sources_select
on storage.objects for select to authenticated
using (
    bucket_id = 'family-sources'
    and private.is_household_member(private.storage_path_household_id(name))
);

create policy family_sources_insert
on storage.objects for insert to authenticated
with check (
    bucket_id = 'family-sources'
    and private.can_manage_household(private.storage_path_household_id(name))
);

create policy family_sources_update
on storage.objects for update to authenticated
using (
    bucket_id = 'family-sources'
    and private.can_manage_household(private.storage_path_household_id(name))
)
with check (
    bucket_id = 'family-sources'
    and private.can_manage_household(private.storage_path_household_id(name))
);

create policy family_sources_delete
on storage.objects for delete to authenticated
using (
    bucket_id = 'family-sources'
    and private.can_manage_household(private.storage_path_household_id(name))
);

-- -----------------------------------------------------------------------------
-- Realtime publication. Normal fetch remains authoritative; realtime only nudges
-- clients to refresh through the RLS-protected repository.
-- -----------------------------------------------------------------------------

do $$
declare
    v_table text;
begin
    foreach v_table in array array[
        'household_members', 'source_items', 'action_proposals',
        'plan_items', 'plan_item_assignees', 'reminders', 'activity_log'
    ] loop
        if not exists (
            select 1
            from pg_publication_tables
            where pubname = 'supabase_realtime'
              and schemaname = 'public'
              and tablename = v_table
        ) then
            execute format('alter publication supabase_realtime add table public.%I', v_table);
        end if;
    end loop;
end $$;

alter table public.household_members replica identity full;
alter table public.source_items replica identity full;
alter table public.action_proposals replica identity full;
alter table public.plan_items replica identity full;
alter table public.plan_item_assignees replica identity full;
alter table public.reminders replica identity full;
alter table public.activity_log replica identity full;

commit;
