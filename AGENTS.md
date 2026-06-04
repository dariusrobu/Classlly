# AGENTS.md - Classlly Development Guide

## Project Overview

Classlly is a Flutter-based student note-taking application with canvas drawing, audio sync, and student dashboard. Uses Provider for state management, Hive for local persistence, and Supabase for cloud sync.

---

## Build & Development Commands

### Flutter App
```bash
flutter run                        # Run on connected device/emulator
flutter run -d <device_id>         # Run on specific device
flutter run --web                  # Run as web app

flutter build apk --debug           # Debug APK
flutter build apk --release        # Release APK
flutter build ios                  # iOS build
flutter build web                  # Web build
```

### Code Quality
```bash
flutter analyze                    # Run static analysis (linting)
flutter analyze --fix              # Fix auto-fixable issues
flutter format .                   # Format code with dart format
dart fix --apply .                # Apply Dart fixes (migrations, deprecations)
```

### Testing
```bash
flutter test                       # Run all tests
flutter test test/file_name.dart   # Run single test file
flutter test test/file_name.dart --name "test name"  # Run specific test by name
flutter test --reporter compact    # Compact output format
flutter test integration_test/     # Run integration tests
flutter drive -t integration_test/app_test.dart  # Run integration on device
```

### Code Generation
```bash
dart run build_runner build --delete-conflicting-outputs  # Generate Hive adapters
flutter gen-l10n                   # Generate localizations
flutter pub run build_runner build --delete-conflicting-outputs
```

### Backend Server (Node.js)
```bash
cd classlly-server
npm start                          # Start API server
node api/calendars.js              # Direct run
```

---

## Code Style Guidelines

### Lint Rules (analysis_options.yaml)
```yaml
include: package:flutter_lints/flutter.yaml
linter:
  rules:
    avoid_print: false             # Printing allowed for debugging
    prefer_single_quotes: true     # Use single quotes
    prefer_const_constructors: true
    prefer_const_declarations: true
```

### Naming Conventions
| Type | Convention | Example |
|------|------------|---------|
| Files | snake_case | `note_provider.dart`, `auth_screen.dart` |
| Classes | PascalCase | `NoteProvider`, `CanvasWidget` |
| Constants | camelCase with k | `kDefaultStrokeWidth` |
| Private members | underscore prefix | `_privateMethod` |
| Enums | PascalCase values | `PenType.monoline` |

### Imports
- Use package imports for external packages
- Use relative imports for local files
- Order: dart: > package: > relative
- Sort alphabetically within groups

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
```

### Types & Annotations
- Always specify return types for methods
- Use `final` by default, `var` only when type is obvious
- Hive models MUST use `@HiveType(typeId: N)` and `@HiveField(N)` annotations
- Always run `build_runner` after modifying Hive models

### State Management (Provider)
- Use `ChangeNotifierProvider` for view models
- Expose state via getters, not direct ChangeNotifier access
- `context.watch<T>()` for reactive UI
- `context.read<T>()` for one-time reads

### Error Handling
- Use try-catch with specific exception types
- Provide user feedback via SnackBar/dialog
- `avoid_print` is disabled - use print for debugging
- Always handle async with loading states

---

## Project Structure

```
lib/
├── core/
│   ├── constants/     # App constants, supabase_config.dart
│   ├── theme/         # app_theme.dart (Material 3), theme_provider.dart
│   ├── services/      # NotificationService, CloudProvider, CloudStorageService
│   ├── utils/         # Utility functions
│   └── widgets/      # Shared widgets (initialization_screen.dart)
├── data/
│   ├── models/        # Hive models (Note, Stroke, Course, Task, StudentProfile)
│   └── repositories/  # Data access (NotesRepository, AuthRepository)
├── features/
│   ├── canvas/        # Drawing engine, gestures, tool dock, providers
│   ├── library/       # Dashboard, courses, tasks, calendar, providers
│   ├── audio/         # Recording and playback, providers
│   └── auth/          # Authentication, onboarding
├── l10n/              # Generated localizations from ARB
└── main.dart          # Entry point

test/                   # Unit and widget tests
integration_test/       # Integration tests
classlly-server/        # Node.js backend API
```

---

## Development Conventions

### Hive Models
```dart
@HiveType(typeId: 0)
class Note extends HiveObject {
  @HiveField(0)
  String id;
  // ... fields
}
```
Always run `build_runner build --delete-conflicting-outputs` after model changes.

### Localization
- All user-facing strings MUST be in `lib/l10n/app_en.arb`
- Access via `AppLocalizations.of(context)`
- Never hardcode strings in UI

### Theming
- Define colors/text styles in `lib/core/theme/app_theme.dart`
- Use Material 3 design principles
- Support dark/light themes via `ThemeProvider`

### Database Sync
- Use debounced auto-saving for cloud sync
- Implement offline-first with Hive
- Handle sync conflicts gracefully

---

## Testing Conventions

### Unit Tests
- Test providers/business logic in isolation
- Use `mocktail` for mocking dependencies
- Follow AAA pattern: Arrange, Act, Assert
- Test file naming: `<feature>_test.dart`

### Widget Tests
- Use `flutter_test` framework
- Provide required dependencies via Provider
- Test one widget per file

### Integration Tests
- Place in `integration_test/` directory
- Run with `flutter drive -t integration_test/app_test.dart`

---

## Git Conventions

- Conventional commits: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`
- Keep commits atomic and focused
- Run `flutter analyze` before committing
- Test on target platform before submitting

---

## Common Pitfalls

1. **Hive Adapters Not Generated** - Run `build_runner` after model changes
2. **Missing Localization** - Add strings to ARB files, never hardcode
3. **Provider Not Wrapped** - Ensure widgets have required providers in tree
4. **Memory Leaks** - Dispose controllers/streams in provider `dispose()`
5. **Build Failures** - Run `flutter pub get` after pulling changes
