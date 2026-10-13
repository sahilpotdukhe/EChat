-- EChat file storage: chat photos, videos, files and profile pictures.
--
-- Sign-in stays with Firebase. Supabase is set to trust Firebase tokens
-- (config.toml: [auth.third_party.firebase]), so auth.jwt()->>'sub' is the
-- Firebase uid. Paths are <folder>/<uid>/<random>_<name>
-- (see lib/resources/media_storage.dart).

-- Public bucket: files open through their link (the random part of the name
-- keeps links unguessable), like Firebase download links did. 50 MB is the
-- largest single file Supabase's free plan allows.
insert into storage.buckets (id, name, public, file_size_limit)
values ('media', 'media', true, 52428800)
on conflict (id) do update set public = excluded.public, file_size_limit = excluded.file_size_limit;

-- True when the signed-in Firebase user owns this path: the second folder is
-- their uid, the first is one of EChat's folders, and the token really comes
-- from EChat's Firebase project.
create or replace function public.echat_owns_media(object_name text)
returns boolean
language sql
stable
as $$
  select (storage.foldername(object_name))[1] in ('Media', 'thumbnails', 'Users')
     and (storage.foldername(object_name))[2] = (auth.jwt() ->> 'sub')
     and (auth.jwt() ->> 'iss') = 'https://securetoken.google.com/echat-888ef'
$$;

drop policy if exists "echat: upload into own folder" on storage.objects;
create policy "echat: upload into own folder"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'media' and public.echat_owns_media(name));

-- Deleting needs to see the file first.
drop policy if exists "echat: see own files" on storage.objects;
create policy "echat: see own files"
  on storage.objects for select to authenticated
  using (bucket_id = 'media' and public.echat_owns_media(name));

drop policy if exists "echat: delete own files" on storage.objects;
create policy "echat: delete own files"
  on storage.objects for delete to authenticated
  using (bucket_id = 'media' and public.echat_owns_media(name));
