begin;

revoke all on schema private from public, anon;
grant usage on schema private to authenticated;

commit;
