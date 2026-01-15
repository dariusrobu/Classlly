# Classlly - Project Context & Handover

## 🚀 Vision
**Classlly** is a premium, minimalist note-taking app for students. It combines freehand drawing, typed text, synchronized audio replay, and real-time cloud sync.

## 🛠 Tech Stack
- **Framework:** Flutter (Mobile/Tablet/Web focus).
- **State Management:** Provider (ChangeNotifier).
- **Local Persistence:** Hive (NoSQL) with custom adapters.
- **Cloud Sync:** Supabase (PostgreSQL JSONB) with real-time stream subscriptions.
- **Ink Algorithm:** `perfect-freehand` for smooth, pressure-sensitive strokes.
- **Exports:** Vector-based PDF generation via `pdf` and `printing` packages.

## 📁 Key Directories
- `lib/data/models/`: `Note`, `Stroke`, `TextBlock`, `ImageBlock`, `Notebook`.
- `lib/features/canvas/`: The core drawing engine, gestures, and premium tool dock.
- `lib/features/library/`: Dashboard, Course Detail, Tasks, Calendar, and Archive views.
- `lib/features/audio/`: Audio recording and synchronized playback logic.

## ✅ Completed Features
1. **Premium Canvas:**
   - **Unified Tool Dock:** Pen (with sub-menu), Brush, Highlighter, Eraser, Select, Text, Image.
   - **Advanced Pens:** Monoline, Fountain, Reed, Watercolor, Pencil, Marker.
   - **Templates:** Dot Grid, Squared, Lined, Cornell, Blank (in Sidebar).
   - **Manipulation:** Select, Drag-to-move, and Corner-handle Resizing for ink and images.
   - **History:** Full 50-step Undo/Redo stack.
2. **Student Dashboard:**
   - **Views:** Active Courses Grid, Kanban Task Board, Full-page Calendar, Grayscale Archive.
   - **Course Detail:** Performance charts (Grade goal, Trends, Attendance) and Resource management.
   - **Sync:** Debounced auto-save to Hive + Supabase Sync (2s debounce).
3. **Note Replay:**
   - **Audio Sync:** Every stroke and text block is timestamped.
   - **Note Replay Jump:** Tapping a note in "Select" mode jumps the audio to its creation time.

## 🚧 Current Status & Known Issues
- **Shape Recognition:** Currently disabled (previously biased towards circles). Needs a more robust fit-scoring algorithm before re-enabling.
- **InteractiveViewer:** Boundary margins set to 500. Hand tool handles panning.
- **Image Support:** Uses Base64 encoding for local storage in this prototype.

## 📋 Next Steps (Phase 21+)
1. **Academic Stats Logic:** Wire the "Total Notes" and "Study Hours" in the profile to actual database counts.
2. **PDF Snippet Insertion:** Add the ability to drop interactive PDF highlights onto the canvas.
3. **Collaboration:** Implement the "Avatar Stack" functionality for real-time shared notes.
4. **Settings Persistence:** Ensure "Interface Theme" and "Accent Color" choices persist across sessions.

## 📦 Git Repository
- **Initialized:** Local repo initialized on 2026-01-15.
- **Branch:** `main`
- **User:** Robu Darius (robu.i.darius@gmail.com)
