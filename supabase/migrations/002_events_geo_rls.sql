-- PR3+ stub: Events table with geo + basic RLS for The Gathering
-- Run after 001 in Supabase SQL editor.
-- Includes 4-area tags, minimal recurring support, location privacy tiers.

create extension if not exists postgis;

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  host_id uuid references auth.users not null,
  title text not null,
  description text,
  start_time timestamptz not null,
  end_time timestamptz,
  address text,
  location geography(Point, 4326),  -- for PostGIS radius queries
  location_type text default 'public_venue', -- public_venue | approx_neighborhood | meetinghouse_vicinity | private
  location_privacy text default 'post_rsvp', -- controls visibility of exact address
  tags text[], -- 4 areas + Fellowship/Service etc.
  is_recurring boolean default false,
  recurrence_note text, -- e.g. "Weekly on Tuesdays" for MVP
  max_attendees integer,
  cost numeric,
  visibility text default 'verified_members',
  status text default 'active',
  created_at timestamptz default now()
);

alter table public.events enable row level security;

-- Basic policies (expand in later PRs)
create policy "Anyone verified can view active events"
  on public.events for select
  using (status = 'active');

create policy "Hosts can manage their events"
  on public.events for all
  using (auth.uid() = host_id);

-- RSVPs table stub
create table if not exists public.rsvps (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  event_id uuid references public.events not null,
  status text default 'going', -- going | maybe | no
  note text,
  created_at timestamptz default now(),
  unique (user_id, event_id)
);

alter table public.rsvps enable row level security;

create policy "Users can manage own RSVPs" on public.rsvps for all using (auth.uid() = user_id);

-- TODO(PR7): reports table, moderation, keyword enforcement at app layer + DB constraints

comment on column public.events.tags is 'Tags map to 4 areas: Spiritual, Social, Physical, Intellectual + Fellowship/Service';
comment on column public.events.location_privacy is 'Tiered visibility per design doc: public_venue, approx, post_rsvp, etc.';
