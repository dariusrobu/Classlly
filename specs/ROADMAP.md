# Classlly Implementation Roadmap (Working Order)

This roadmap is prioritized for execution: **Models -> CRUD Actions -> UI Wiring -> Advanced Features**.

---

## Phase 1: Foundation (Data Models) [COMPLETED]
*Goal: Define the schema for all missing data.*
- [X] **Create `Course` Model:**
    - Fields: `id`, `title`, `professor`, `schedule` (e.g., "Mon 10am"), `location`, `color` (int), `semester`.
- [X] **Create `Grade` Model:**
    - Fields: `id`, `courseId`, `title`, `score` (e.g., 95), `maxScore` (100), `weight`, `date`.
- [X] **Create `Attendance` Model:**
    - Fields: `id`, `courseId`, `date`, `status` (Present/Absent).
- [X] **Create `Folder` Model:**
    - Fields: `id`, `title`, `parentId`, `type` (Notebook/Resource).
- [X] **Update `Task` Model:**
    - Add `courseId` to link tasks to specific courses.
- [X] **Notification Model:** (Implied in system features, or simple local notifications)

## Phase 2: Core Data Management (CRUD Screens) [COMPLETED]
*Goal: Allow users to create and edit data so the app isn't empty.*
- [X] **Add/Edit Course Screen:**
    - Form with Color Picker, Schedule inputs, and Professor info.
- [X] **Add/Edit Task Screen:**
    - Modal with Date Picker, Course Selector (Dropdown), and Priority toggle.
- [ ] **Add/Edit Grade Screen:** (Next up for Course Detail interactivity)
    - Simple input form for scores.
- [ ] **Global Edit/Delete Logic:**
    - Implement context menus (long-press/3-dots) on existing cards to trigger Edit/Delete.

## Phase 3: Dashboard & Navigation Wiring [COMPLETED]
*Goal: Replace hardcoded widgets with real data streams.*
- [X] **Active Courses Grid:**
    - Connect to `Hive.box<Course>`. Use `ValueListenableBuilder`.
- [X] **Grade Overview Chart:**
    - Wired to `Grade` box.
- [X] **Attendance Chart:**
    - Wired to `Attendance` box.
- [X] **Upcoming Deadlines:**
    - Already wired to Tasks.
- [X] **Sort & Filter:**
    - Search Bar functional for Notes and Courses.
- [X] **Page Titles:**
    - Dashboard header updated.

## Phase 4: App Entry & Authentication (Critical Next Step)
*Goal: Secure the app.*
- [ ] **Fix App Entry:**
    - Update `main.dart` to check `Supabase.auth.currentUser`.
    - Route to `OnboardingScreen` (new) or `AuthScreen` if not logged in.
- [ ] **Create `OnboardingScreen`:**
    - PageView with "Welcome", "Features", "Get Started".
- [ ] **Profile Setup Wizard:**
    - New screen after Signup: Set Name, Major.

## Phase 5: Advanced Views (Course Detail & Calendar)
*Goal: Make the deep navigation screens fully interactive.*
- [ ] **Course Detail Screen:**
    - **Dynamic Header:** Show real Course Title, Prof, Color.
    - **Resources:** Implement folder browser for links/PDFs.
- [ ] **Calendar Screen:**
    - **Event Markers:** Show dots for Tasks/Schedule on the calendar widget.
    - **Day View:** Show list of events when a date is clicked.

## Phase 6: System Features & Polish
*Goal: Enhance usability and connectivity.*
- [ ] **Notifications System:**
    - Implement Notification Center (bell icon logic).
- [X] **Settings Wiring:**
    - Theme toggles functional.
- [ ] **Enhanced Search:**
    - Index Tasks and Folders in the global search bar.
- [ ] **Folders:**
    - Implement Folder creation and nesting for Notebooks.

## Phase 7: Canvas & Polish
*Goal: Final touches and premium features.*
- [ ] **PDF Support:** Implement `pdf_render` for background layers.
- [ ] **Premium:** Implement Subscription logic/gate.
- [ ] **Accessibility:** High Contrast Mode.