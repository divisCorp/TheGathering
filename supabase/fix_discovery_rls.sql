-- URGENT: Multi-user discovery was broken when only host policies apply.
-- Run this entire script in Supabase SQL Editor once.
-- Effect: any signed-in (and anon) client can read active events; nearby_events
-- runs as security definer so map/list work for all beta testers.

-- 1) Open select on active events
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

-- Keep host full management for own rows
drop policy if exists "Hosts can manage their events" on public.events;
create policy "Hosts can manage their events"
  on public.events for all
  to authenticated
  using (auth.uid() = host_id)
  with check (auth.uid() = host_id);

-- 2) nearby_events as security definer (bypasses RLS; still filters status=active)
drop function if exists public.nearby_events(
  double precision, double precision, double precision, text, integer, integer, timestamptz, timestamptz
);
drop function if exists public.nearby_events(
  double precision, double precision, double precision, text, integer, integer
);

create or replace function public.nearby_events(
  lat double precision,
  lon double precision,
  radius_miles double precision default 15,
  search text default null,
  lim integer default 20,
  off integer default 0,
  start_date timestamptz default null,
  end_date timestamptz default null
)
returns table (
  id uuid,
  host_id uuid,
  title text,
  description text,
  start_time timestamptz,
  end_time timestamptz,
  address text,
  location geography,
  location_type text,
  location_privacy text,
  tags text[],
  is_recurring boolean,
  recurrence_note text,
  max_attendees integer,
  cost numeric,
  visibility text,
  status text,
  created_at timestamptz,
  lat double precision,
  lon double precision
)
language sql
stable
security definer
set search_path = public
as $$
  select
    e.id,
    e.host_id,
    e.title,
    e.description,
    e.start_time,
    e.end_time,
    e.address,
    e.location,
    e.location_type,
    e.location_privacy,
    e.tags,
    e.is_recurring,
    e.recurrence_note,
    e.max_attendees,
    e.cost,
    e.visibility,
    e.status,
    e.created_at,
    st_y(e.location::geometry) as lat,
    st_x(e.location::geometry) as lon
  from public.events e
  where e.status = 'active'
    and e.location is not null
    and (search is null or e.title ilike '%' || search || '%')
    and st_dwithin(
      e.location,
      st_setsrid(st_makepoint(lon, lat), 4326)::geography,
      radius_miles * 1609.34
    )
    and (start_date is null or e.start_time >= start_date)
    and (end_date is null or e.start_time <= end_date)
  order by e.start_time asc
  limit lim
  offset off;
$$;

grant execute on function public.nearby_events(
  double precision, double precision, double precision, text, integer, integer, timestamptz, timestamptz
) to authenticated, anon;

-- 3) RSVP visibility for attendee lists
drop policy if exists "Authenticated can view event RSVPs" on public.rsvps;
create policy "Authenticated can view event RSVPs"
  on public.rsvps for select
  to authenticated
  using (true);

-- Verify with (as any role):
-- select count(*) from events where status = 'active';
