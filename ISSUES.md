# Classlly Application Issues Report

## 1. Static Analysis Issues (Linting & Code Quality)
*   **[VERIFIED] Unused Parameter:** `_GlassCard` in `course_detail_screen.dart` uses the `padding` parameter correctly.
*   **[FIXED] String Quotes & Cleanup:** Standardized single quotes and removed all unused imports/variables identified by static analysis.
*   **Hardcoded Values:** Multiple instances of hardcoded strings (e.g., "Welcome back...", "Recent Notes"). 
    *   *Status:* Ongoing improvement.

## 2. Outdated Dependencies
Run `flutter pub outdated` to see the full list. Key packages updated:
*   **Direct:**
    *   [x] `google_fonts`: 7.0.2 -> 8.0.0
    *   [x] `google_sign_in`: 6.3.0 -> 7.2.0
    *   [ ] `timezone`: 0.10.1 -> 0.11.0 (Blocked by `flutter_local_notifications`)
*   **Dev:** [ ] `build_runner` (2.4.13 -> 2.10.5) (Blocked by `hive_generator` / `build` conflict)
*   **Discontinued:** `build_resolvers` and `build_runner_core` are discontinued.

## 3. Technical Debt (TODOs & FIXMEs)
*   **Android Build:** [FIXED] Application ID set to `com.robudarius.classlly`, package moved, and release signing configured via `key.properties`.
*   **Desktop Build:** [FIXED] Updated Windows and Linux `CMakeLists.txt` and runner files to use the correct project name (`classlly`) and application ID.
*   **Documentation:** [IMPROVED] Updated `README.md` with accurate project description and branding.
*   **Data Models:** [FIXED] Robust JSON parsing implemented with `JsonUtils`. All models now have consistent `fromJson`/`toJson`.
*   **Canvas Logic:** [FIXED] Audio duration/timestamp sync logic reviewed and improved. Tapping items now seeks to correct audio timestamp.
*   **Type Casting:** [IMPROVED] Type safety improved via `JsonUtils`, reducing manual `toDouble()` calls.

## 4. Architecture & Performance
*   **`NotesRepository`:** [IMPROVED] Added safe adapter registration to prevent crashes on hot restart.
*   **`LibraryProvider`:** [FIXED] Refactored into specialized providers (`ProfileProvider`, `TaskProvider`, `CourseProvider`, `NotesProvider`).
*   **UI Performance:** [IMPROVED] Dashboard optimized via cached statistics in `Course` model and specialized providers.
*   **Data Consistency:** [FIXED] Grade averages and attendance rates are now cached in the `Course` model and updated atomically when data changes.

## 5. Testing
*   **Coverage:** [IMPROVED] Unit tests added for `CourseProvider`, `TaskProvider`, and `ProfileProvider`.
*   **Recommendation:** Continue adding widget tests for key screens and more unit tests for repository logic. Providers refactored for DI to support easier testing.