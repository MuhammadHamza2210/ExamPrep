# Connecting ExamPrep to Supabase (multi-user backend)

Do these 4 steps, then send me the **Project URL** and **anon key** and I'll wire
the app to it and test.

## 1. Create a project
1. Go to https://supabase.com → sign in → **New project**.
2. Name it `examprep`, pick a region close to Pakistan (e.g. **Singapore**),
   set a database password (save it), and create.

## 2. Create the tables
1. In the project, open **SQL Editor → New query**.
2. Paste the entire contents of [`supabase/schema.sql`](supabase/schema.sql) and
   click **Run**. You should see "Success".

## 3. Turn on email login
1. **Authentication → Providers → Email**: make sure it's enabled.
2. For easy testing, **Authentication → Sign In / Providers → Email** →
   turn **"Confirm email" OFF** (so signups work instantly without a
   confirmation email). You can turn it back on later.

## 4. Copy your keys
1. **Project Settings → API**.
2. Copy the **Project URL** (looks like `https://abcd1234.supabase.co`).
3. Copy the **anon public** key (a long `eyJ...` string — this one is safe to
   put in a client app; it only works together with the Row Level Security
   rules the schema set up).

## 5. Send them to me
Paste them here like:

```
URL:  https://xxxx.supabase.co
anon: eyJhbGciOi...
```

Then I'll:
- add the `supabase_flutter` package,
- store the keys in `lib/data/supabase_config.dart`,
- swap the local repository for a Supabase-backed one (keeping Hive as an
  offline cache),
- and verify signup / note upload / topic votes sync across devices.
