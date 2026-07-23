-- =============================================================================
-- The Gathering — Beta setup (run once in Supabase Dashboard → SQL Editor)
-- Project: dhryaddmqbbgekezskpl
-- Safe to re-run: uses IF NOT EXISTS / DROP POLICY IF EXISTS patterns where possible.
-- =============================================================================

-- 0) Extensions
create extension if not exists postgis;

-- 1) Profiles: allow users to insert/upsert their own row + limited public read
-- (needed for signup ensureProfileExists + attendee display names)
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'profiles' and policyname = 'Users can insert own profile'
  ) then
    create policy "Users can insert own profile"
      on public.profiles for insert
      to authenticated
      with check (auth.uid() = id);
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'profiles' and policyname = 'Authenticated can view basic profiles'
  ) then
    create policy "Authenticated can view basic profiles"
      on public.profiles for select
      to authenticated
      using (true);
  end if;
end $$;

-- 2) Avatars storage bucket (public read for profile photos)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'avatars',
  'avatars',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
on conflict (id) do update set public = true;

-- Storage policies (drop + recreate for idempotency)
drop policy if exists "Users can upload own avatar" on storage.objects;
drop policy if exists "Users can update own avatar" on storage.objects;
drop policy if exists "Users can delete own avatar" on storage.objects;
drop policy if exists "Public can view avatars" on storage.objects;

create policy "Users can upload own avatar"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Users can update own avatar"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Users can delete own avatar"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Public can view avatars"
  on storage.objects for select to public
  using (bucket_id = 'avatars');

-- 3) nearby_events with explicit lat/lon for the Flutter client
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
security invoker
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

-- 4) Helper: set geography from lat/lon (used by client fallback if needed)
create or replace function public.set_event_location(
  event_id uuid,
  lat double precision,
  lon double precision
)
returns void
language plpgsql
security invoker
as $$
begin
  update public.events
  set location = st_setsrid(st_makepoint(lon, lat), 4326)::geography
  where id = event_id
    and host_id = auth.uid();
end;
$$;

grant execute on function public.set_event_location(uuid, double precision, double precision)
  to authenticated;

-- =============================================================================
-- AUTH SETTINGS (Dashboard, not SQL — do these for beta):
-- 1. Authentication → Providers → Email → turn OFF "Confirm email" for easier testing
--    (or leave on and check spam for confirmation links)
-- 2. Authentication → URL Configuration:
--    Site URL: https://diviscorp.github.io/TheGathering/
--    Redirect URLs: https://diviscorp.github.io/TheGathering/**
-- 3. Optional: enable Phone provider when ready for SMS OTP
-- =============================================================================
