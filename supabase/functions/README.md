# Supabase Edge Functions

These are example Edge Functions for The Gathering app.

## Banned Words Check
- Checks event title/description for prohibited content.
- Call from client before creating event, or as a DB trigger/hook.

## Verification Queue
- Queues new users for manual review.
- Call from auth hook or after signup.

### Deploy
```bash
supabase functions deploy banned-words-check
supabase functions deploy verification-queue
```

Set secrets in Supabase Dashboard for SERVICE_ROLE_KEY if needed.

Use with `SUPABASE_SERVICE_ROLE_KEY` for privileged operations.
```

For crash reporting skeleton. Add sentry_flutter.