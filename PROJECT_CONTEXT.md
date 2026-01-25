# Classlly - Project Context & Handover

## 🚀 Vision
**Classlly** is a premium, minimalist note-taking app for students. It combines freehand drawing, typed text, synchronized audio replay, and real-time cloud sync.

## 🛠 Tech Stack
- **Framework:** Flutter (Mobile/Tablet/Web focus).
- **State Management:** Provider (ChangeNotifier).
- **Local Persistence:** Hive (NoSQL) with custom adapters.
- **Cloud Sync:** Supabase (PostgreSQL JSONB) with real-time stream subscriptions.
- **Ink Algorithm:** `perfect-freehand` for smooth, pressure-sensitive strokes.
- **Widgets:** `home_widget` for shared data with iOS/Android.
- **Exports:** Vector-based PDF generation via `pdf` and `printing` packages.

## 📁 Key Directories
- `lib/data/models/`: `Note`, `Stroke`, `Course`, `Task`, `StudentProfile`.
- `lib/features/canvas/`: The core drawing engine, gestures, premium tool dock, and PDF insertion.
- `lib/features/library/`: Dashboard (localized), Course Detail, Tasks, Calendar, and Archive views.
- `lib/features/audio/`: Audio recording and synchronized playback logic.
- `lib/core/services/`: `NotificationService`, `WidgetService`, `SupabaseCloudService`.

## ✅ Completed Features
1. **Premium Canvas:**
   - **Unified Tool Dock:** Full set of advanced pens, highlighters, and resizable image/PDF support.
   - **Intelligent Gestures:** Lasso selection and Scribble-to-erase.
   - **Shape Recognition:** Auto-snap logic for lines, circles, and rectangles.
2. **Student Dashboard:**
   - **Reactive Profile:** Stats (Notes, Courses, Study Hours, GPA, Credits) update in real-time.
   - **Views:** Kanban Task Board, Full-page Calendar, Grayscale Archive.
   - **Course Detail:** Real-time charts for GPA trends and attendance.
3. **Connectivity:**
   - **Sync:** Real-time sync with Supabase and backend account deletion compliance.
   - **Notifications:** Daily Agenda at 8 AM, 24h/1h Task reminders, and 15m Lecture warnings.
   - **Widgets:** Interactive "Up Next" and "Course Tracker" home screen widgets.

## 🚧 Current Status & Known Issues
- **Android Signing:** Awaiting `google-services.json` and production keystore setup.
- **PDF Snippets:** Currently inserts full pages; needs precision cropping logic.
- **Collaboration:** `_AvatarStack` is a UI mock; needs Supabase Presence integration.

## 📋 Next Steps (Phase 22+)
1. **PDF Precision:** Add cropping UI to the PDF insertion flow.
2. **Real-time Collaboration:** Wire Supabase Presence to show active users and sync remote strokes.
3. **Android Launch:** Finalize `google-services.json` and build `.aab`.
4. **Desktop UX:** Optimize window layouts for wide-screen desktop users.

## 📦 Git Repository
- **Last Milestone:** 2026-01-25 (Phase 21 Finalized - SLC MVP Status).
- **Branch:** `main`
- **User:** Robu Darius (robu.i.darius@gmail.com)