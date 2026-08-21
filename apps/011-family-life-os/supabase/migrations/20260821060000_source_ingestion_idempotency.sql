-- Family Life OS / candidate #011
-- Durable offline ingestion: idempotent source creation, account/household binding,
-- and a processing lease that prevents a lost network response from starting a
-- second Edge extraction while the first one is still running.

begin;

alter table public.source_items
    add column if not exists client_request_id uuid;

create unique index if not exists source_items_household_client_request_uidx
    on public.source_items(household_id, client_request_id)
    where client_request_id is not null;

-- Replace the three-argument function with a backward-compatible five-argument
-- signature. Existing callers still get the historical processing/uploading state.
-- Durable queued callers get a neutral queued/uploading state and let the Edge
-- function claim processing when it actually starts.
drop function if exists public.create_source_item(text, text, text);

create function public.create_source_item(
    p_source_type text,
    p_title text,
    p_original_text text default null,
    p_client_request_id uuid default null,
    p_household_id uuid default null
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
       and (p_household_id is null or hm.household_id = p_household_id)
     order by case hm.role when 'owner' then 0 else 1 end, hm.created_at
     limit 1;

    if v_household_id is null or v_member_id is null then
        raise exception 'Active adult household member not found';
    end if;
    if not private.can_manage_household(v_household_id) then
        raise exception 'Insufficient household permission';
    end if;

    if p_client_request_id is not null then
        select s.id into v_source_id
          from public.source_items s
         where s.household_id = v_household_id
           and s.client_request_id = p_client_request_id
         limit 1;
    end if;

    if v_source_id is null then
        begin
            insert into public.source_items as s (
                household_id,
                created_by_member_id,
                source_type,
                display_title,
                original_text,
                processing_status,
                processing_attempts,
                last_processing_started_at,
                client_request_id
            ) values (
                v_household_id,
                v_member_id,
                p_source_type,
                trim(p_title),
                p_original_text,
                case
                    when p_client_request_id is not null and p_source_type = 'text' then 'queued'
                    when p_source_type = 'text' then 'processing'
                    else 'uploading'
                end,
                case
                    when p_client_request_id is not null then 0
                    when p_source_type = 'text' then 1
                    else 0
                end,
                case
                    when p_client_request_id is null and p_source_type = 'text' then now()
                    else null
                end,
                p_client_request_id
            )
            returning s.id into v_source_id;
        exception
            when unique_violation then
                if p_client_request_id is null then raise; end if;
                select s.id into v_source_id
                  from public.source_items s
                 where s.household_id = v_household_id
                   and s.client_request_id = p_client_request_id
                 limit 1;
                if v_source_id is null then raise; end if;
        end;
    end if;

    source_item_id := v_source_id;
    household_id := v_household_id;
    member_id := v_member_id;
    return next;
end;
$$;

revoke execute on function public.create_source_item(text, text, text, uuid, uuid) from public, anon;
grant execute on function public.create_source_item(text, text, text, uuid, uuid) to authenticated;

-- Durable uploads need storage/provenance finalized before the Edge function runs,
-- but must not be marked processing until that function actually starts. The new
-- boolean defaults false so the existing six-argument client remains compatible.
drop function if exists public.finalize_source_upload(uuid, text, text, text, bigint, text);

create function public.finalize_source_upload(
    p_source_item_id uuid,
    p_storage_path text,
    p_file_name text,
    p_content_type text,
    p_size_bytes bigint,
    p_extracted_text text default null,
    p_defer_processing boolean default false
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

    update public.source_items s
       set storage_path = p_storage_path,
           file_name = nullif(trim(p_file_name), ''),
           content_type = nullif(trim(p_content_type), ''),
           size_bytes = p_size_bytes,
           extracted_text = nullif(p_extracted_text, ''),
           processing_status = case when p_defer_processing then 'queued' else 'processing' end,
           processing_error_code = null,
           processing_attempts = s.processing_attempts + case when p_defer_processing then 0 else 1 end,
           last_processing_started_at = case when p_defer_processing then null else now() end
     where s.id = p_source_item_id
       and s.household_id = v_household_id;

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

revoke execute on function public.finalize_source_upload(uuid, text, text, text, bigint, text, boolean) from public, anon;
grant execute on function public.finalize_source_upload(uuid, text, text, text, bigint, text, boolean) to authenticated;

commit;
