-- Albania mentioned: database setup. Paste all of this into Supabase > SQL Editor > Run.

create table if not exists public.mentions (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  title text not null check (char_length(title) between 1 and 150),
  kind text not null check (kind in ('Film','Song','Interview','Other')),
  release_year text check (release_year is null or char_length(release_year) <= 4),
  who text check (who is null or char_length(who) <= 150),
  line text not null check (char_length(line) between 1 and 1500),
  link text check (link is null or (char_length(link) <= 500 and link ~* '^https?://')),
  video_time text check (video_time is null or char_length(video_time) <= 12),
  shot_url text check (shot_url is null or (char_length(shot_url) <= 500 and shot_url ~* '^https://')),
  approved boolean not null default false
);

alter table public.mentions enable row level security;

-- Visitors can read only approved mentions.
create policy "Public reads approved" on public.mentions
  for select to anon, authenticated using (approved = true);

-- Visitors can send new mentions, but only as "not approved yet".
create policy "Public submits pending" on public.mentions
  for insert to anon, authenticated with check (approved = false);

-- You (a signed-in user) can see, approve, and delete everything.
create policy "Admin reads all" on public.mentions
  for select to authenticated using (true);
create policy "Admin updates" on public.mentions
  for update to authenticated using (true) with check (true);
create policy "Admin deletes" on public.mentions
  for delete to authenticated using (true);

-- Storage for screenshots (public to view, small JPEGs only).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('screenshots', 'screenshots', true, 1048576, array['image/jpeg'])
on conflict (id) do nothing;

create policy "Public uploads screenshots" on storage.objects
  for insert to anon, authenticated with check (bucket_id = 'screenshots');
create policy "Admin deletes screenshots" on storage.objects
  for delete to authenticated using (bucket_id = 'screenshots');
