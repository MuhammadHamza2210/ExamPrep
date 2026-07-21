<div align="center">

# 📚 ExamPrep

### Crowd-sourced notes & exam-topic predictor for Pakistani university students

*Share notes, discover which topics are most likely to appear in your exam, and build a smart last-minute study plan — so you prepare what actually matters, fast.*

![Flutter](https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.12-0175C2?logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase&logoColor=white)
![Riverpod](https://img.shields.io/badge/State-Riverpod-4A42D6)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Desktop-lightgrey)

</div>

---

## ✨ Overview

Two problems every student faces before exams:

1. **"I don't have good notes."** — ExamPrep is a shared hub where students upload notes per course, chapter and exam type. The best-rated notes rise to the top.
2. **"I'm out of time — what do I even study?"** — After each paper, students tag which topics actually appeared. The app aggregates those votes into a **likelihood score** per topic, so you can prioritise the highest-probability topics first.

It's **crowd-sourced** (every student's votes count), **cloud-synced** (your account follows you across devices), and **offline-friendly** (works without a connection, syncs when it's back).

---

## 🚀 Features

### 📖 Notes Sharing Hub
- Browse a real hierarchy: **University → Department → Semester → Course**
- Upload notes as **PDF / image files** or **plain text**
- **1–5 star ratings** — highest-rated notes surface first
- Exam-type tags: **Quiz / Midterm / Final**
- Global search across universities, courses and topics

### 📈 Important-Topics Predictor
- Students vote **"this came in my exam"** after their paper
- The app computes a **frequency / likelihood score** per topic (pure aggregation — no ML)
- **"Study these first"** view sorted by likelihood, with an animated **radar chart**
- Students can **add their own important topics** so future students know what matters
- **Vote once** per student (changing your vote updates it, not stacks it)

### 🗓️ Smart Study Plan
- Set your **exam date** → get a **countdown** + a topic list **ordered by likelihood**
- Tick topics off as you study; a progress bar tracks how ready you are
- Plans **sync to your account** and show on the Home screen

### 🏫 Real, Semester-Wise Curricula
- Standard **8-semester** HEC-aligned course lists for CS, SE, EE, BBA, Economics & Maths
- **Bahria University Karachi** modelled on the real official roadmaps:
  **Computer Science, Software Engineering, Information Technology, Robotics & Intelligent Systems, and Psychology**
- **Campus-specific** departments (e.g. pick *Islamabad / Lahore / Karachi*)
- Can't find a subject or department? **Add it yourself** — it's shared with everyone

### 👤 Accounts & Sync
- Email/password auth via **Supabase**
- Profile: university, **campus**, degree program, semester (editable anytime)
- **My Uploads** & **My Downloads** history
- Pull-to-refresh, auto-sync on launch, graceful offline handling

### 🎨 Premium UI/UX
- Soft **glassmorphism** cards, ambient gradient backgrounds
- **Light & dark mode**, Poppins + Inter typography (Google Fonts)
- Micro-animations (`flutter_animate`), Hero transitions, shimmer skeletons, haptics
- Custom animated bottom navigation

---

## 🛠️ Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter (Dart) |
| State management | `flutter_riverpod` |
| Navigation | `go_router` (with auth/onboarding redirect guards) |
| Backend | **Supabase** — Postgres, Auth, Storage, Row-Level Security + triggers |
| Offline cache | `hive` / `hive_flutter` |
| Charts | `fl_chart` (animated radar & bars) |
| Animations | `flutter_animate` |
| Files | `file_picker`, `open_file`, `url_launcher` |
| Fonts | `google_fonts` |

---

## 🏗️ Architecture

```
Flutter UI (Riverpod)
        │
   AppData (single immutable snapshot)
     ┌──┴─────────────────────────┐
     │                            │
 LocalStorage (Hive)      SupabaseRepository
 • offline cache          • auth + profiles
 • study plan state       • shared notes + ratings
 • downloads              • crowd-sourced topics + votes
                          • custom courses / departments
```

- **Catalog** (universities, departments, courses) is **generated on-device** from curriculum templates — fast and offline.
- **User-generated content** (notes, topics, votes, custom subjects) lives in **Supabase** and is cached in Hive for offline use.
- Aggregate columns (`rating_sum`, `times_appeared`, …) are kept correct by **database triggers** that apply deltas, so seed baselines are preserved and every user counts once.

---

## 📦 Getting Started

### Prerequisites
- Flutter **3.44+** (Dart 3.12+) — check with `flutter doctor`
- A free **Supabase** project ([supabase.com](https://supabase.com))

### 1. Clone & install
```bash
git clone https://github.com/MuhammadHamza2210/ExamPrep.git
cd ExamPrep
flutter pub get
```

### 2. Set up the backend
In your Supabase project's **SQL Editor**, run these files in order:

| File | What it does |
|---|---|
| `supabase/schema.sql` | Core tables (profiles, notes, topics), RLS, storage bucket |
| `supabase/seed_data.sql` | Loads demo notes & topics |
| `supabase/phase2.sql` | Per-user ratings/votes, shared custom courses/departments, cloud study plans |

Then: **Authentication → Sign In / Providers → Email → turn "Confirm email" OFF** (for instant signups during testing).

### 3. Add your credentials
Put your **Project URL** and **anon key** (Project Settings → API) in
`lib/data/supabase_config.dart`:
```dart
static const String url = 'https://YOUR-PROJECT.supabase.co';
static const String anonKey = 'YOUR-ANON-KEY';
```
> The anon key is safe to ship in a client app — it only grants what the Row-Level-Security rules allow. **Never** commit the `service_role` key.

### 4. Run
```bash
flutter run                 # phone / emulator
flutter run -d windows      # desktop preview
```

---

## 📁 Project Structure

```
lib/
  app/            router.dart, theme.dart
  core/           icons, utils, shared widgets (glass card, buttons…)
  data/           app_data, local_storage, supabase_repo, curriculum
  models/         university, department, course, note, topic, study_plan, app_user
  features/
    onboarding/ · auth/ · shell/ · home/
    browser/    (universities → departments → semesters → courses)
    course/ · notes/ · topics/ · study_plan/ · profile/ · search/
assets/data/      seed.json  (catalog + demo content)
supabase/         schema.sql · seed_data.sql · phase2.sql
```

---

## 🗺️ Roadmap

- [ ] Reputation / gamification (points, badges, leaderboard)
- [ ] Push notifications for upcoming exams
- [ ] AI study tools (summarise a PDF, generate a quiz from notes)
- [ ] Comments / discussion per course
- [ ] Report / flag low-quality content

---

## 🤝 Contributing

Issues and PRs are welcome. Please run `flutter analyze` before submitting.

## 👤 Author

**Muhammad Hamza** — [@MuhammadHamza2210](https://github.com/MuhammadHamza2210)

<div align="center">
<sub>Built with Flutter 💙 for students across Pakistan.</sub>
</div>
