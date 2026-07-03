-- PR1: Initial users table + RLS for The Gathering
-- IMPORTANT: Run this in your Supabase SQL editor after project creation.
-- This matches the design doc requirements.

create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  display_name text,
  age_range text,
  bio text,
  interests text[],
  city text,                     -- Coarse only - NO precise lat/lon
  ward text,                     -- Optional, self-reported
  stake text,
  is_verified_member boolean default false,
  avatar_url text,
  phone_verified boolean default false,
  verification_status text default 'pending_review',
  created_at timestamptz default now()
);

-- Enable RLS
alter table public.profiles enable row level security;

-- Policies (basic for PR1)
create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- Optional public view of limited fields (for attendee lists later)
-- create policy "Limited public profile info" ...

-- Trigger to auto-create profile on signup (recommended)
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, display_name, created_at)
  values (new.id, new.raw_user_meta_data->>'display_name', now());
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- TODO(PR3+): Add events, rsvps, reports tables with geo + RLS
-- PostGIS extension: enable in Supabase dashboard or `create extension postgis;`
comment on table public.profiles is 'User profiles for The Gathering. Location is coarse only per privacy requirements.';
