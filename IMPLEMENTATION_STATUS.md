# The Gathering — Implementation Status

**Owner:** Grok (engineering). **Tester:** James (only when needed).

## Live
- https://diviscorp.github.io/TheGathering/
- Supabase: `dhryaddmqbbgekezskpl`
- Version: **0.2.0+** (shipping continuously)

## Working product surface
- Auth (email signup/sign-in, sign-out, optional phone, attestation)
- Profile (edit, avatar, interests, feedback, support ID)
- Create / edit / duplicate events (templates, tags, geo pin, standards filter)
- Discover (map, radius presets, filters, search debounce, seed samples, prefs)
- RSVP with capacity checks (client + service)
- My Activities (host counts, past hosted, invites)
- Reports inbox + hide activity
- Calendar: Google, Outlook, ICS open/copy
- Terms / privacy / standards (beta copy)

## Ops SQL (run once in Supabase if gaps appear)
- `supabase/beta_setup.sql`
- `supabase/fix_discovery_rls.sql` — multi-user event visibility
- `supabase/moderation_beta.sql` — reports inbox policies
- `supabase/shipping_rls_beta.sql`

## Next engineering (autonomous)
1. Lightweight error telemetry (Sentry if build-friendly)
2. Push notification foundation (FCM)
3. Realtime RSVP updates when replication enabled
4. Store readiness (icons, splash, store listing drafts)
