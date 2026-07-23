-- Beta moderation: any signed-in member can review reports and soft-hide events.
-- Tighten later with a real admin role (PR7).

-- View all reports (beta)
drop policy if exists "Authenticated can view all reports beta" on public.reports;
create policy "Authenticated can view all reports beta"
  on public.reports for select
  to authenticated
  using (true);

-- Update status (pending → reviewed/resolved/dismissed)
drop policy if exists "Authenticated can update reports beta" on public.reports;
create policy "Authenticated can update reports beta"
  on public.reports for update
  to authenticated
  using (true)
  with check (true);

-- Anyone authenticated can soft-cancel any event in beta (moderation hide)
-- Prefer dedicated status update; hosts already have manage policy for own.
drop policy if exists "Authenticated can moderate event status beta" on public.events;
create policy "Authenticated can moderate event status beta"
  on public.events for update
  to authenticated
  using (true)
  with check (true);
