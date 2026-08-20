-- Family Life OS / candidate #011
-- Complete-v1 production hardening: covering indexes for foreign keys flagged by
-- the hosted Supabase performance advisor.

create index if not exists activity_log_actor_member_idx
  on public.activity_log(actor_member_id)
  where actor_member_id is not null;

create index if not exists activity_log_actor_user_idx
  on public.activity_log(actor_user_id)
  where actor_user_id is not null;

create index if not exists household_invites_accepted_user_idx
  on public.household_invites(accepted_by_user_id)
  where accepted_by_user_id is not null;

create index if not exists household_invites_created_member_idx
  on public.household_invites(created_by_member_id);

create index if not exists notification_preferences_user_idx
  on public.notification_preferences(user_id);
