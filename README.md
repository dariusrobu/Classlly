# Classlly 🚀

**Classlly** (formerly Notelly) is a premium, minimalist note-taking application specifically engineered for students. It bridges the gap between freehand creativity and structured academic organization, integrating advanced drawing tools, synchronized audio recording, and a comprehensive student dashboard.

---

## ✨ Key Features

### 🎨 Premium Canvas
- **Advanced Ink Engine:** Smooth, pressure-sensitive strokes powered by `perfect-freehand`.
- **Unified Tool Dock:** Quick access to Monoline, Fountain, Reed, Watercolor pens, Brushes, Highlighters, and Erasers.
- **Intelligent Gestures:** Lasso selection for moving/resizing and "Scribble-to-Erase" support.
- **Rich Media:** Insert and manipulate images or interactive PDF snippets directly on the canvas.
- **Smart Templates:** Choose from Dot Grid, Squared, Lined, Cornell, or Blank page layouts.
- **Multi-Page Support:** Vertical infinite-feeling page layout with sidebar previews.

### 🎙️ Audio Sync & Replay
- **Timestamped Notes:** Every stroke and text block is synchronized with the audio timeline.
- **Note Replay Jump:** Simply tap a note or stroke in "Select" mode to jump the audio playback to the exact moment it was created.

### 📅 Student Dashboard
- **Performance Overview:** Real-time visualization of your academic health, including GPA trends and attendance rates.
- **Academic Calendar:** Manage teaching periods, exam sessions, holidays, and weekly schedules.
- **Kanban Task Board:** Track assignments and deadlines with priority-based organization.
- **Active Courses:** A grid-based view of your current classes with quick access to course-specific notes and stats.

### ☁️ Sync & Privacy
- **Real-time Cloud Sync:** Powered by Supabase (PostgreSQL JSONB) with debounced auto-saving.
- **Offline-First:** Local persistence via Hive ensuring your notes are always accessible without an internet connection.
- **Security:** Row Level Security (RLS) ensures your academic data remains private and secure.

---

## 🛠 Tech Stack

- **Framework:** [Flutter](https://flutter.dev/) (Mobile, Tablet, Web, Desktop)
- **State Management:** [Provider](https://pub.dev/packages/provider) (ChangeNotifier)
- **Local Database:** [Hive](https://pub.dev/packages/hive) (NoSQL)
- **Backend/Auth:** [Supabase](https://supabase.com/)
- **Audio:** [record](https://pub.dev/packages/record) & [just_audio](https://pub.dev/packages/just_audio)
- **PDF Engine:** [pdf](https://pub.dev/packages/pdf) & [pdfx](https://pub.dev/packages/pdfx)
- **Charts:** [fl_chart](https://pub.dev/packages/fl_chart)

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (^3.10.7)
- Dart SDK
- A Supabase project (for cloud sync)

### Installation

1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/robudarius/classlly.git
    cd classlly
    ```

2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Generate Code (Hive Adapters):**
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```

4.  **Configure Supabase:**
    Create a `lib/core/constants/supabase_config.dart` file (or update the existing one) with your credentials:
    ```dart
    class SupabaseConfig {
      static const String url = 'YOUR_SUPABASE_URL';
      static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';
    }
    ```

5.  **Run the Application:**
    ```bash
    flutter run
    ```

---

## 📁 Project Structure

```text
lib/
├── core/           # Shared constants, themes, services, and utils
├── data/           # Data layer: Models (Hive/JSON) and Repositories
├── features/       # Feature-based logic and UI
│   ├── audio/      # Audio recording and playback state
│   ├── auth/       # Authentication and Profile screens
│   ├── canvas/     # Drawing engine, gestures, and tool dock
│   ├── library/    # Dashboard, Course management, and Tasks
│   └── text_editor/# Typed note functionality
└── main.dart       # Entry point and provider initialization
```

---

## 🛣 Roadmap

- [ ] **Advanced PDF Cropping:** Precision snippet extraction for the canvas.
- [ ] **Real-time Collaboration:** Presence-based "Avatar Stack" for shared study sessions.
- [ ] **BYOC (Bring Your Own Cloud):** Optional Google Drive and iCloud storage integration.
- [ ] **AI Study Assistant:** Automated summary generation from audio and handwritten notes.

---

## 📱 Production Status

- **iOS:** Ready for TestFlight (Version 2.5.0).
- **Android:** In Development (Configuring release signing).
- **Web/Desktop:** Functional prototype available.

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request or open an issue for feature requests.

## 📄 License

This project is proprietary. Contact [Robu Darius](mailto:robu.i.darius@gmail.com) for licensing inquiries.
