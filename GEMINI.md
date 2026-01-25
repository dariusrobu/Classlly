# Classlly Project Context

## Project Overview
**Classlly** (formerly Notelly) is a premium, minimalist note-taking application designed for students. It runs on Flutter (Mobile, Tablet, Web) and integrates freehand drawing, typed text, and synchronized audio recording.

### Key Features
*   **Canvas:** Advanced drawing engine using `perfect-freehand` with pressure sensitivity. Supports multiple pen types (Monoline, Fountain, Watercolor, etc.), shapes, images, and PDF snippets.
*   **Audio Sync:** Records audio while taking notes; tapping a note/stroke jumps the audio playback to that specific moment.
*   **Dashboard:** A student-focused hub with course management, task Kanban boards, calendar, and performance analytics (GPA/Credits).
*   **Sync & Storage:** Real-time cloud sync via Supabase (PostgreSQL JSONB) and local offline-first persistence using Hive.
*   **Widgets & Notifications:** Home screen widgets (Up Next, Course Tracker) and intelligent notifications (Daily Agenda, Deadlines, Lectures).
*   **Export:** Vector-based PDF generation.

## Architecture & Tech Stack
*   **Framework:** Flutter
*   **State Management:** `provider` (ChangeNotifier)
*   **Local Database:** `hive` (NoSQL)
*   **Backend:** `supabase_flutter`
*   **Audio:** `record` and `just_audio`
*   **PDF:** `pdf` and `pdfx` packages
*   **Widgets:** `home_widget` for iOS/Android integration

### Directory Structure
*   `lib/main.dart`: Entry point and background callback registration.
*   `lib/core/`: Shared resources (constants, theme, services, utils).
    *   `services/`: `NotificationService`, `WidgetService`, `SupabaseCloudService`.
*   `lib/data/`: Data layer.
    *   `models/`: Hive types and JSON serialization (`Note`, `Stroke`, `Course`, `Task`, `StudentProfile`).
    *   `repositories/`: Data access logic (`NotesRepository`, `AuthRepository`).
*   `lib/features/`: Feature-specific code.
    *   `canvas/`: Drawing logic, gestures, tool dock, and PDF snippet insertion.
    *   `library/`: Main dashboard, course detail, tasks, calendar, and archive.
    *   `audio/`: Recording and playback state.
    *   `auth/`: Authentication, onboarding, and profile setup.

## Building and Running

### Prerequisites
*   Flutter SDK (^3.10.7)
*   Dart SDK

### Common Commands
*   **Run App:** `flutter run`
*   **Analyze Code:** `flutter analyze`
*   **Run Tests:** `flutter test`
*   **Generate Code (Hive Adapters):**
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```
*   **Localizations:**
    ```bash
    flutter gen-l10n
    ```

## Development Conventions
*   **State Management:** Use `ChangeNotifierProvider` for view models.
*   **Styling:** Defined in `lib/core/theme/app_theme.dart`. Use Material 3 principles.
*   **Localization:** All UI strings must be in `lib/l10n/app_en.arb`.
*   **Persistence:** Models requiring Hive must have `@HiveType` and a generated adapter.

## Current Status
*   **Active Development:** Phase 22 (Refining PDF Snippets & Collaboration).
*   **Completed:** Academic Stats (Reactive Profile, GPA/Credits), Home Screen Widgets (iOS/Android), Dashboard Localization, Backend Account Deletion.
*   **Known Issues:** Shape recognition is enabled (auto-snap) but requires "press-and-hold" refinement.
*   **Next Steps:** Implement advanced PDF cropping for snippets, real-time presence for collaboration (Supabase Presence), and complete Android release signing setup.