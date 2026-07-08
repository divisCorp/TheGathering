-- Storage policies for avatars bucket
-- 1. Create bucket 'avatars' in Supabase Dashboard (Storage > New bucket) - make it PUBLIC for simplicity.
-- 2. Run this SQL in SQL Editor.

-- Allow authenticated users to upload their own avatar
create policy "Users can upload own avatar"
on storage.objects for insert
to authenticated
with check ( bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text );

-- Allow authenticated users to update their own avatar
create policy "Users can update own avatar"
on storage.objects for update
to authenticated
using ( bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text );

-- Allow authenticated users to delete their own avatar
create policy "Users can delete own avatar"
on storage.objects for delete
to authenticated
using ( bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text );

-- Allow public read for avatars (so images display)
create policy "Public can view avatars"
on storage.objects for select
to public
using ( bucket_id = 'avatars' );