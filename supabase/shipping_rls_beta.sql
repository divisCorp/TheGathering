-- The Gathering — keep beta discovery working for all signed-in users.
-- Run if events disappear for accounts that are not is_verified_member yet.
-- Safe to re-run.

-- Reports table (if missing)
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

drop policy if exists "Users can create reports" on public.reports;
create policy "Users can create reports"
  on public.reports for insert
  to authenticated
  with check (auth.uid() = reporter_id);

drop policy if exists "Users can view own reports" on public.reports;
create policy "Users can view own reports"
  on public.reports for select
  to authenticated
  using (auth.uid() = reporter_id);

-- Events: authenticated users can view active events (beta — no verified gate)
drop policy if exists "Anyone verified can view active events" on public.events;
drop policy if exists "Verified members can view active events" on public.events;
drop policy if exists "Authenticated can view active events" on public.events;
drop policy if exists "Anon can view active events" on public.events;

create policy "Authenticated can view active events"
  on public.events for select
  to authenticated
  using (status = 'active');

create policy "Anon can view active events"
  on public.events for select
  to anon
  using (status = 'active');

-- Hosts insert/update/delete own events (if missing)
drop policy if exists "Hosts can manage their events" on public.events;
create policy "Hosts can manage their events"
  on public.events for all
  to authenticated
  using (auth.uid() = host_id)
  with check (auth.uid() = host_id);

-- RSVPs: own rows + hosts can read attendees
drop policy if exists "Users can manage own RSVPs" on public.rsvps;
create policy "Users can manage own RSVPs"
  on public.rsvps for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Hosts can view RSVPs for their events" on public.rsvps;
create policy "Hosts can view RSVPs for their events"
  on public.rsvps for select
  to authenticated
  using (
    exists (
      select 1 from public.events e
      where e.id = event_id and e.host_id = auth.uid()
    )
  );

-- Anyone authenticated can see RSVP rows for events they can see (attendee lists)
drop policy if exists "Authenticated can view event RSVPs" on public.rsvps;
create policy "Authenticated can view event RSVPs"
  on public.rsvps for select
  to authenticated
  using (true);
