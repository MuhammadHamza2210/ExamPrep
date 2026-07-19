-- ExamPrep — Supabase schema (v2). Safe to re-run.
-- SQL Editor → New query → paste ALL of this → Run.
-- Catalog (universities/departments/courses) stays generated in the app;
-- only shared notes + crowd-sourced topics live here.

-- Clean up any earlier version -------------------------------------------------
drop table if exists note_ratings cascade;
drop table if exists topic_votes cascade;
drop table if exists notes cascade;
drop table if exists topics cascade;
drop table if exists custom_courses cascade;
drop table if exists custom_departments cascade;

-- Profiles (1:1 with auth.users) ----------------------------------------------
create table if not exists profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  name          text not null default '',
  university_id text not null default '',
  campus        text not null default '',
  degree        text not null default '',
  semester      int  not null default 1,
  created_at    timestamptz not null default now()
);

-- Shared notes (aggregate rating columns) -------------------------------------
create table notes (
  id            uuid primary key default gen_random_uuid(),
  course_id     text not null,
  uploader_id   uuid references auth.users(id) on delete set null,
  uploader_name text not null default '',
  title         text not null,
  chapter       text not null default '',
  exam_type     text not null default 'finalExam',
  file_url      text not null default '',
  file_ext      text not null default '',
  text_body     text not null default '',
  rating_sum    numeric not null default 0,
  rating_count  int not null default 0,
  created_at    timestamptz not null default now()
);
create index notes_course_idx on notes(course_id);

-- Crowd-sourced important topics (aggregate vote columns) ---------------------
create table topics (
  id             uuid primary key default gen_random_uuid(),
  course_id      text not null,
  name           text not null,
  times_appeared int not null default 0,
  total_votes    int not null default 0,
  created_by     uuid references auth.users(id) on delete set null,
  created_at     timestamptz not null default now()
);
create index topics_course_idx on topics(course_id);

-- Row Level Security ----------------------------------------------------------
alter table profiles enable row level security;
alter table notes    enable row level security;
alter table topics   enable row level security;

drop policy if exists read_profiles on profiles;
drop policy if exists own_profile   on profiles;
create policy read_profiles on profiles for select to authenticated using (true);
create policy own_profile   on profiles for all    to authenticated using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists read_notes   on notes;
drop policy if exists insert_notes on notes;
drop policy if exists own_notes    on notes;
create policy read_notes   on notes for select to authenticated using (true);
create policy insert_notes on notes for insert to authenticated with check (uploader_id = auth.uid());
create policy own_notes    on notes for update to authenticated using (uploader_id = auth.uid());

drop policy if exists read_topics   on topics;
drop policy if exists insert_topics on topics;
create policy read_topics   on topics for select to authenticated using (true);
create policy insert_topics on topics for insert to authenticated with check (created_by = auth.uid());

-- Aggregate update RPCs (security definer so any signed-in user can vote/rate)-
create or replace function rate_note(p_note_id uuid, p_stars int)
returns void language sql security definer set search_path = public as $$
  update notes set rating_sum = rating_sum + p_stars, rating_count = rating_count + 1
  where id = p_note_id;
$$;

create or replace function vote_topic(p_topic_id uuid, p_appeared boolean)
returns void language sql security definer set search_path = public as $$
  update topics
     set times_appeared = times_appeared + (case when p_appeared then 1 else 0 end),
         total_votes    = total_votes + 1
   where id = p_topic_id;
$$;

grant execute on function rate_note(uuid, int)      to authenticated;
grant execute on function vote_topic(uuid, boolean) to authenticated;

-- Storage bucket for note files -----------------------------------------------
insert into storage.buckets (id, name, public)
values ('notes', 'notes', true)
on conflict (id) do nothing;

drop policy if exists notes_read   on storage.objects;
drop policy if exists notes_upload on storage.objects;
create policy notes_read   on storage.objects for select to authenticated using (bucket_id = 'notes');
create policy notes_upload on storage.objects for insert to authenticated with check (bucket_id = 'notes');
