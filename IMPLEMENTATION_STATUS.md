# The Gathering - Implementation Status

**Owner:** Grok (engineering). **Primary tester:** James.

## Live
- Web: https://diviscorp.github.io/TheGathering/
- Supabase: `dhryaddmqbbgekezskpl`
- Version: 0.1.2+3

## Done
- PR1–PR4 core loop (auth, profile, create, discover, RSVP)
- Sign-out + stable GoRouter (Create Account works)
- Report activity, calendar export, soft-cancel
- Copy invite, first-run welcome, upcoming-list fallback
- Auto map-pin on create, sample seed button

## Ops (run once if multi-user discovery empty)
`supabase/fix_discovery_rls.sql` in SQL Editor

## Next
1. Sentry  
2. Moderation inbox for reports  
3. Push notifications  
4. Realtime RSVPs  
5. Store tracks (TestFlight / Play)  
