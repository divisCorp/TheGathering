# Supabase Configuration for The Gathering

## Setup Steps (PR1)
1. Create a new Supabase project at https://supabase.com
2. Copy the Project URL and anon public key into a `.env` file at project root (see .env.example)
3. Enable Phone auth in Authentication > Providers
4. Run the migration: `supabase/migrations/001_init_users_rls.sql` in the SQL Editor
5. Create a Storage bucket named `avatars` (public or with policies)
6. Add these RLS/storage policies:

## Storage Policies (avatars)
```sql
-- Allow authenticated users to upload their own avatar
create policy "Users can upload own avatar"
on storage.objects for insert
to authenticated
with check ( bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text );

-- Similar for update/select as needed.
```

## Environment Variables
Add to .env (never commit):
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=eyJhbGci...

## Future (PR3+)
- Enable PostGIS extension for geo queries
- Add events table with geography(Point, 4326)
- Realtime for RSVPs

## Verification Queue (PR1 stub)
New users get `verification_status = 'pending_review'`.
Full admin review queue implemented in PR7.
