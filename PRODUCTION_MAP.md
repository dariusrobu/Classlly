# Classlly Application Analysis

## 1. Core Architecture

- **Framework**: Flutter (Multi-platform: iOS, Android, Web, macOS)
- **State Management**: `provider` + `hive` (Local-first persistence)
- **Backend**: Supabase (PostgreSQL, Auth, Storage)
- **Offline-First**: Uses Hive for local caching and Supabase for cloud sync

## 2. Authentication

- **Methods**:
  - Email/Password (Supabase Auth)
  - Google Sign-In (Native SDKs for Android/iOS, OAuth for Web)
  - Apple Sign-In (iOS/macOS/Web)
  - Guest Mode (Offline access)
- **Features**:
  - Profile Setup (Avatar, Display Name)
  - Account Deletion (GDPR compliance)

## 3. Dashboard (Library)

- **Overview**:
  - Academic Performance Stats (GPA, Credits)
  - "Today's Schedule" widget
  - Quick Actions
- **Course Management**:
  - Create/Edit Courses (Color coding, Subject icon)
  - Track Credits & GPA per course
- **Task Management**:
  - Kanban-style or List view
  - Due Dates & Priority
- **Calendar**:
  - Weekly/Monthly views
  - Course schedule integration

## 4. Note-Taking & Canvas

- **Engine**: `perfect-freehand` based drawing engine
- **Tools**:
  - Multiple pen types (Monoline, Fountain, Marker)
  - Shape recognition (Rect, Circle, Line)
  - Infinite Canvas (conceptual)
  - PDF Import & Annotation (`pdfx`)
  - Image insertion
- **Organization**:
  - Notebooks & Folders
  - Rich Text Editor (`flutter_quill`) support

## 5. Audio Recording (Planned)

- **Status**: Currently removed/not implemented.
- **Planned Features**:
  - Sync audio with note strokes
  - Tap-to-seek playback
  - Cloud storage integration

## 6. Settings & Customization

- **Theme**: Dark/Light mode support
- **Profile**: Update user details
- **Data**: Cloud Sync status & controls

## 7. Platform Specifics

- **iOS**: Apple Sign-In integration
- **Android**: Google Sign-In native integration
- **Web**: OAuth flows for social login, Responsive layout
- **macOS**: Desktop layout support
