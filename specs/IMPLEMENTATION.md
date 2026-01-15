# IMPLEMENTATION.md - Notelly

## Journal
*   **2026-01-14:** Initial plan created.
*   **2026-01-14:** Completed Phases 1-6: Basic prototype functional (Canvas, Audio, Library).
*   **2026-01-14:** Phase 7: Implemented gesture recognition for Scribble and Lasso. Added Move functionality.
*   **2026-01-14:** Phase 8: Integrated Cloud Sync and Authentication with Supabase.
*   **2026-01-14:** Phase 9: Implemented PDF Export.
*   **2026-01-14:** Phase 10: Added Zoom/Pan, Hand Tool, and Page Borders.
*   **2026-01-14:** Phase 11: Implemented Multi-Page vertical layout.
*   **2026-01-14:** Phase 12: Added Resize handles. (Shape recognition logic updated, still tuning).
*   **2026-01-14:** Phase 14: Ported Modern Dashboard UI from HTML reference. Fully theme-aware.
*   **2026-01-14:** Phase 13: Implemented Real-time Sync and Debounced Auto-save.
*   **2026-01-14:** Phase 15: Implemented Notebooks/Courses organization and Note Renaming.
*   **2026-01-14:** Phase 16: Implemented Highlighter, Color Picker, and Undo/Redo.

## Phase 1: Project Setup & Foundation
- [X] Create Flutter project.
- [X] Add dependencies (Provider, Hive, Supabase, etc.).
- [X] Setup Theme and Directory structure.

## Phase 2: Data Layer (Hive & Models)
- [X] Create Models (Stroke, Note, etc.).
- [X] Generate Hive Adapters.
- [X] Create NotesRepository.

## Phase 3: Core Canvas & Drawing
- [X] Implement DrawingPainter with freehand algorithm.
- [X] Implement GestureDetector for ink input.

## Phase 4: Text Input
- [X] Add Text Tool and TextBlockWidget (moveable).

## Phase 5: Audio Recording & Note Replay
- [X] Implement Recording and Playback sync logic.

## Phase 6: Library & Polish
- [X] Create initial LibraryScreen.

## Phase 7: Smart Ink & Selection
- [X] Implement Scribble to Erase.
- [X] Implement Circle to Lasso.
- [X] Implement Selection Moving.

## Phase 8: Cloud Sync (Supabase)
- [X] Integrate Supabase Auth and Sync.

## Phase 9: PDF Export
- [X] Implement PDF Generation.

## Phase 10: SLC - Usability Core (Zoom & Pan)
- [X] Refactor CanvasScreen for Zoom/Pan.
- [X] Implement "Virtual Bounds" and Page Borders.
- [X] Implement Hand Tool for panning.

## Phase 11: SLC - Page Management
- [X] Implement Multi-Page vertical layout.
- [X] Add "Add Page" functionality.

## Phase 12: SLC - Advanced Manipulation
- [X] Add Resize Handles.
- [ ] **Ongoing:** Improve Shape Recognition (Perfecting Rectangles).

## Phase 13: SLC - Real-time Sync & Polish
- [X] Implement Debounced Auto-Save.
- [X] Subscribe to Supabase Realtime changes.

## Phase 14: Modern Dashboard UI
- [X] Port HTML design to Flutter.
- [X] Ensure full theme support (Light/Dark).

## Phase 15: Organization & Note Management
- [X] Create `Notebook` model.
- [X] Implement "Rename Note" UI.
- [X] Update sidebar to list real Notebooks.
- [X] Filter notes by notebook selection.

## Phase 16: SLC - Essential Tools & Polish
- [X] Implement **Highlighter** tool.
- [X] Implement **Color Picker**.
- [X] Implement **Undo/Redo** functionality.
- [ ] Implement **Note Replay Jump** (Tap note to jump to audio time).
