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

## Next after beta smoke passes
1. Sentry crash reporting  
2. Report event/user + light moderation  
3. PR5: ICS export + notifications foundation  
4. Realtime RSVPs  
5. TestFlight / Play internal track  

## Design fidelity
Follows `the-gathering-design-doc.md` (4 areas, coarse location, standards, independent branding).
