-- Fix RLS infinite recursion on profiles
-- Run via supabase db query

-- Security definer function to check verified without recursion
create or replace function public.is_verified_user()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from profiles where id = auth.uid() and is_verified_member = true
  );
$$;

-- Fix profiles select policy
drop policy if exists "Verified members can view basic info of other verified members" on public.profiles;

create policy "Verified members can view basic info of other verified members"
  on public.profiles for select
  using ( public.is_verified_user() );

-- Fix events select policy to use the function
drop policy if exists "Verified members can view active events" on public.events;

create policy "Verified members can view active events"
  on public.events for select
  using (
    status = 'active' and public.is_verified_user()
  );
