# Classlly

A premium, minimalist note-taking application designed for students. Classlly integrates freehand drawing, typed text, and synchronized audio recording to provide a comprehensive study experience.

## Key Features

*   **Canvas:** Advanced drawing engine with pressure sensitivity and multiple pen types.
*   **Audio Sync:** Synchronized audio recording that links directly to your notes and strokes.
*   **Dashboard:** A student-focused hub for course management, tasks, and academic performance analytics.
*   **Cloud Sync:** Real-time synchronization via Supabase with offline-first local persistence using Hive.
*   **Multi-Platform:** Supports Mobile (iOS/Android) and Desktop (Windows/Linux/macOS).

## Getting Started

To run this project locally:

1.  **Prerequisites:** Flutter SDK and Dart SDK installed.
2.  **Clone the repo:** `git clone <repository-url>`
3.  **Install dependencies:** `flutter pub get`
4.  **Run build runner:** `dart run build_runner build --delete-conflicting-outputs` (to generate Hive adapters)
5.  **Run the app:** `flutter run`

## Tech Stack

*   **Framework:** Flutter
*   **State Management:** Provider
*   **Database:** Hive (Local) & Supabase (Cloud)
*   **Audio:** Record & Just Audio
*   **Styling:** Material Design 3