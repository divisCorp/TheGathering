-- PR4: Nearby events RPC using PostGIS for real geo filtering
-- Call from client: supabase.rpc('nearby_events', { lat: ..., lon: ..., radius_miles: ..., search: ..., lim: ..., off: ... })

create or replace function public.nearby_events(
  lat double precision,
  lon double precision,
  radius_miles double precision default 15,
  search text default null,
  lim integer default 20,
  off integer default 0
)
returns setof public.events
language sql
stable
as $$
  select *
  from public.events
  where status = 'active'
    and (search is null or title ilike '%' || search || '%')
    and st_dwithin(
      location,
      st_setsrid(st_makepoint(lon, lat), 4326)::geography,
      radius_miles * 1609.34  -- convert miles to meters
    )
  order by start_time asc
  limit lim
  offset off;
$$;

-- Grant execute to authenticated (and anon if needed)
grant execute on function public.nearby_events(double precision, double precision, double precision, text, integer, integer) to authenticated, anon;
