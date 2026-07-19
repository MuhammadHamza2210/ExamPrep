-- ExamPrep — Phase 2 migration. Run AFTER schema.sql. Safe to re-run.
-- Adds: per-user ratings/votes (count once), shared custom courses/departments,
-- and cloud-synced study plans. Aggregate columns on notes/topics are kept in
-- sync by triggers that apply deltas (so seed baselines are preserved).

-- ---- Per-user note ratings --------------------------------------------------
create table if not exists note_ratings (
  note_id uuid references notes(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  stars   int  not null check (stars between 1 and 5),
  primary key (note_id, user_id)
);
alter table note_ratings enable row level security;
drop policy if exists read_note_ratings on note_ratings;
drop policy if exists own_note_ratings  on note_ratings;
create policy read_note_ratings on note_ratings for select to authenticated using (true);
create policy own_note_ratings  on note_ratings for all    to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

create or replace function trg_note_ratings() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    update notes set rating_sum = rating_sum + new.stars, rating_count = rating_count + 1 where id = new.note_id;
  elsif tg_op = 'UPDATE' then
    update notes set rating_sum = rating_sum + new.stars - old.stars where id = new.note_id;
  elsif tg_op = 'DELETE' then
    update notes set rating_sum = rating_sum - old.stars, rating_count = rating_count - 1 where id = old.note_id;
  end if;
  return null;
end; $$;
drop trigger if exists note_ratings_aiud on note_ratings;
create trigger note_ratings_aiud after insert or update or delete on note_ratings
  for each row execute function trg_note_ratings();

-- ---- Per-user topic votes ---------------------------------------------------
create table if not exists topic_votes (
  topic_id uuid references topics(id) on delete cascade,
  user_id  uuid references auth.users(id) on delete cascade,
  appeared boolean not null,
  primary key (topic_id, user_id)
);
alter table topic_votes enable row level security;
drop policy if exists read_topic_votes on topic_votes;
drop policy if exists own_topic_votes  on topic_votes;
create policy read_topic_votes on topic_votes for select to authenticated using (true);
create policy own_topic_votes  on topic_votes for all    to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

create or replace function trg_topic_votes() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    update topics set times_appeared = times_appeared + (case when new.appeared then 1 else 0 end),
                      total_votes = total_votes + 1 where id = new.topic_id;
  elsif tg_op = 'UPDATE' then
    update topics set times_appeared = times_appeared
                      + (case when new.appeared then 1 else 0 end)
                      - (case when old.appeared then 1 else 0 end) where id = new.topic_id;
  elsif tg_op = 'DELETE' then
    update topics set times_appeared = times_appeared - (case when old.appeared then 1 else 0 end),
                      total_votes = total_votes - 1 where id = old.topic_id;
  end if;
  return null;
end; $$;
drop trigger if exists topic_votes_aiud on topic_votes;
create trigger topic_votes_aiud after insert or update or delete on topic_votes
  for each row execute function trg_topic_votes();

-- ---- Shared student-added subjects & departments ----------------------------
create table if not exists custom_courses (
  id            text primary key,
  department_id text not null,
  university_id text not null,
  name          text not null,
  code          text not null default 'CUSTOM',
  semester      int  not null default 1,
  created_by    uuid references auth.users(id) on delete set null,
  created_at    timestamptz not null default now()
);
alter table custom_courses enable row level security;
drop policy if exists read_ccourses on custom_courses;
drop policy if exists own_ccourses  on custom_courses;
create policy read_ccourses on custom_courses for select to authenticated using (true);
create policy own_ccourses  on custom_courses for all    to authenticated using (created_by = auth.uid()) with check (created_by = auth.uid());

create table if not exists custom_departments (
  id            text primary key,
  university_id text not null,
  name          text not null,
  program       text not null default 'custom',
  campus        text not null default '',
  created_by    uuid references auth.users(id) on delete set null,
  created_at    timestamptz not null default now()
);
alter table custom_departments enable row level security;
drop policy if exists read_cdepts on custom_departments;
drop policy if exists own_cdepts  on custom_departments;
create policy read_cdepts on custom_departments for select to authenticated using (true);
create policy own_cdepts  on custom_departments for all    to authenticated using (created_by = auth.uid()) with check (created_by = auth.uid());

-- ---- Cloud-synced study plans (private per user) ----------------------------
create table if not exists study_plans (
  user_id   uuid references auth.users(id) on delete cascade,
  course_id text not null,
  exam_date date not null,
  checked   jsonb not null default '[]',
  primary key (user_id, course_id)
);
alter table study_plans enable row level security;
drop policy if exists own_study_plans on study_plans;
create policy own_study_plans on study_plans for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
