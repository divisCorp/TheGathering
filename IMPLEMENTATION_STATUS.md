# The Gathering - Implementation Status

**Owner:** Grok (engineering). **Primary tester:** James.

## Completed (code)
- **PR1**: Bootstrap + auth (email/pass + phone OTP when enabled + attestation)
- **PR2**: Profiles + 4-area interests + avatar upload (soft-required in beta)
- **PR3**: Event creation wizard + EventsService
- **PR4**: Discovery map, PostGIS nearby, filters, pagination, RSVP, My Activities
- **Beta readiness (2026-07-22)**:
  - Auth UX for email-confirm / phone-off worlds
  - In-app **Load sample activities** seed
  - `supabase/beta_setup.sql` (RLS, avatars bucket, geo helpers)
  - Web-safe profile avatar preview
  - Empty Discover states
  - `BETA_TEST.md` tester script

## Live
- Web: https://diviscorp.github.io/TheGathering/
- Supabase project: `dhryaddmqbbgekezskpl`

## Blockers for other people testing (ops)
1. Run `supabase/beta_setup.sql` in SQL Editor
2. Auth URL config + prefer Confirm Email OFF for beta
3. Smoke test: signup → profile → seed → RSVP → create

## Shipped recently
- Report activity (reason + details → `reports` table)
- Add to calendar (Google Calendar + copy ICS)
- Soft-cancel hosted events (`status = cancelled`)
- Event detail polish (standards banner, host menu)
- `supabase/shipping_rls_beta.sql` (auth can view active events + reports policies)

## Next
1. Sentry crash reporting  
2. Simple moderation view / email of new reports  
3. Push notifications foundation  
4. Realtime RSVPs  
5. TestFlight / Play internal track  

## Design fidelity
Follows `the-gathering-design-doc.md` (4 areas, coarse location, standards, independent branding).
