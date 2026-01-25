# Classlly Project Context

## Project Overview
**Classlly** (formerly Notelly) is a premium, minimalist note-taking application designed for students. It runs on Flutter (Mobile, Tablet, Web) and integrates freehand drawing, typed text, and synchronized audio recording.

### Key Features
*   **Canvas:** Advanced drawing engine using `perfect-freehand` with pressure sensitivity. Supports multiple pen types (Monoline, Fountain, Watercolor, etc.), shapes, and images.
*   **Audio Sync:** Records audio while taking notes; tapping a note/stroke jumps the audio playback to that specific moment.
*   **Dashboard:** A student-focused hub with course management, task Kanban boards, calendar, and performance analytics.
*   **Sync & Storage:** Real-time cloud sync via Supabase (PostgreSQL JSONB) and local offline-first persistence using Hive.
*   **Export:** Vector-based PDF generation.

## Architecture & Tech Stack
*   **Framework:** Flutter
*   **State Management:** `provider` (ChangeNotifier)
*   **Local Database:** `hive` (NoSQL)
*   **Backend:** `supabase_flutter`
*   **Audio:** `record` and `just_audio`
*   **PDF:** `pdf` and `printing` packages

### Directory Structure
*   `lib/main.dart`: Entry point.
*   `lib/core/`: Shared resources (constants, theme, services, utils).
*   `lib/data/`: Data layer.
    *   `models/`: Hive types and JSON serialization (`Note`, `Stroke`, `Notebook`).
    *   `repositories/`: Data access logic (`NotesRepository`, `SupabaseRepository`).
*   `lib/features/`: Feature-specific code.
    *   `canvas/`: Drawing logic, gesture handling, and tool dock.
    *   `library/`: Main dashboard, course lists, and archive.
    *   `audio/`: Recording and playback state.
    *   `auth/`: Authentication screens.

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

## Development Conventions
*   **State Management:** Use `ChangeNotifierProvider` for view models. ephemeral state can stay in `StatefulWidget`.
*   **Styling:** Define colors and text styles in `lib/core/theme/app_theme.dart`.
*   **Persistence:** All models usually require a Hive `TypeAdapter`. Run the build runner after modifying models annotated with `@HiveType`.
*   **Navigation:** (Inferred) Standard Navigator or named routes.

## Current Status
*   **Active Development:** Phase 22 (Refining PDF Snippets & Collaboration).
*   **Known Issues:** Shape recognition is temporarily disabled.
*   **Next Steps:** Implement advanced PDF cropping for snippets, real-time presence for collaboration, and further localization.
