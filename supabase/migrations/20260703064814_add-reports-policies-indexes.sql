-- Migration: Add reports table, improved RLS policies, and performance indexes
-- This enhances the core schema for The Gathering app.
-- Builds on 001 (profiles) and 002 (events + rsvps).
-- Assumes PostGIS is enabled.

-- 1. Reports table for user reports and moderation (supports standards enforcement)
create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid references auth.users not null,
  reported_user_id uuid references auth.users,
  event_id uuid references public.events,
  reason text not null check (char_length(reason) > 0),
  details text,
  status text default 'pending' check (status in ('pending', 'reviewed', 'resolved', 'dismissed')),
  created_at timestamptz default now()
);

alter table public.reports enable row level security;

-- Users can create reports
create policy "Users can create reports"
  on public.reports for insert
  with check (auth.uid() = reporter_id);

-- Users can view their own submitted reports
create policy "Users can view own reports"
  on public.reports for select
  using (auth.uid() = reporter_id);

-- TODO: Add admin/service role policies for reviewing reports in future PRs

-- 2. Improved RLS Policies

-- Events: Restrict view to verified members only (for active events)
drop policy if exists "Anyone verified can view active events" on public.events;

create policy "Verified members can view active events"
  on public.events for select
  using (
    status = 'active' and
    exists (
      select 1 from public.profiles 
      where id = auth.uid() and is_verified_member = true
    )
  );

-- Profiles: 
-- - Own profile full access (select + update already partial)
-- - Verified members can discover other verified members' basic info (for hosts, attendees, etc.)

drop policy if exists "Users can view own profile" on public.profiles;

create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Verified members can view basic info of other verified members"
  on public.profiles for select
  using (
    is_verified_member = true and
    exists (
      select 1 from public.profiles p 
      where p.id = auth.uid() and p.is_verified_member = true
    )
  );

-- Update policy remains for own profile

-- RSVPs: Allow event hosts to see who RSVPed their events
create policy "Hosts can view RSVPs for their events"
  on public.rsvps for select
  using (
    exists (
      select 1 from public.events e 
      where e.id = event_id and e.host_id = auth.uid()
    )
  );

-- Existing "Users can manage own RSVPs" policy is retained for insert/update/delete.

-- 3. Performance indexes for common queries (events list, geo, tags, RSVPs)

create index if not exists idx_events_start_time 
  on public.events (start_time);

create index if not exists idx_events_tags 
  on public.events using gin (tags);

create index if not exists idx_events_location 
  on public.events using gist (location);

create index if not exists idx_events_host_id 
  on public.events (host_id);

create index if not exists idx_events_status 
  on public.events (status);

create index if not exists idx_rsvps_event_id 
  on public.rsvps (event_id);

create index if not exists idx_rsvps_user_id 
  on public.rsvps (user_id);

comment on table public.reports is 'User-submitted reports for moderation and violation of community standards.';
comment on column public.events.tags is 'Array of interest tags (Spiritual, Social, Physical, Intellectual, etc.)';
