# Classlly: Your Ultimate Academic Command Center

**Classlly** is a high-performance, native iOS application built with SwiftUI and SwiftData, designed to centralize and simplify every aspect of university life. From real-time schedule tracking to proactive exam alerts and GPA simulation, Classlly transforms how students manage their academic journey.

---

## 📱 Visual Experience

Classlly features two distinct, adaptive design languages tailored to your study mood:

* **Standard Mode**: A clean, professional, and academic focus interface.
* **Rainbow Mode**: An immersive, dark-themed experience featuring ambient radial glows that match your next class and glassmorphism elements.

---

## ✨ Key Features

### 1. The Dynamic Dashboard

* **Semester Progress**: A circular tracker showing the current week and semester completion percentage.
* **Up Next Hero**: A real-time countdown to your next class, including room numbers and professor details.
* **Exam Radar**: A high-priority carousel that highlights upcoming exams and quizzes with "URGENT" urgency badges.
* **Smart Action Belt**: Quick-entry buttons for adding tasks, logging grades, marking attendance, and "What If?" simulations.

### 2. Intelligent Schedule Manager

* **Automated Week Logic**: Automatically identifies "Even" vs. "Odd" teaching weeks.
* **Daily Log**: Detailed blocks for Courses and Seminars with integrated classroom locations and teacher info.
* **Week Strip**: Fluid navigation between days and weeks to keep your schedule glanceable.

### 3. Academic Portfolio

* **Schedule Scanner**: Powered by OCR, scan physical or digital syllabuses to import your entire schedule instantly.
* **Grade Analytics**: Log grades with specific weights to see real-time GPA calculations for every subject.
* **Attendance Tracking**: Monitor your presence rate per subject to ensure you stay above academic requirements.

### 4. Focused Productivity

* **Built-in Study Timer**: A native Pomodoro-style timer with dedicated "Focus," "Short Break," and "Long Break" modes.
* **Reminders-Style Tasks**: A robust task manager for homework and projects, including priority levels and flagging.
* **"What If?" Calculator**: Simulate future grades to understand exactly what you need on your next exam to hit your target GPA.

---

## 🛠 Tech Stack

* **UI Framework**: SwiftUI (Swift 6 Ready).
* **Data Persistence**: SwiftData for local, high-speed storage.
* **Architecture**: MVVM with centralized managers for Theme, Calendar, and Auth.
* **Concurrency**: Combine and Swift Concurrency (Tasks/Actors).
* **Intelligence**: Vision Framework for schedule scanning and OCR.
* **Notifications**: UserNotifications for study timers and academic alerts.

---

## 📂 Project Structure

```text
Classlly/
├── App/                # App entry point & global configuration
├── Core/
│   ├── Design Systems/ # AppTheme, Colors, and Shared Components
│   ├── Services/       # Timer, Scanner, and Auth Managers
│   └── Utilities/      # Data managers and image pickers
├── Models/             # SwiftData schemas (Subject, Task, Grade)
└── Features/           # Core app modules
    ├── Dashboard/      # Home, More, and Tab navigation
    ├── Calendar/       # Schedule and week logic views
    ├── Subjects/       # Portfolio and detail views
    └── Tasks/          # Task management and entry

```

---

## 🚀 Getting Started

1. **Clone the Repository**:
```bash
git clone https://github.com/dariusrobu/classlly.git

```


2. **Open in Xcode**: Open `Classlly.xcodeproj`.
3. **App Group Configuration**: Ensure your Developer Team is selected in the Target settings to enable the Shared Model Container.
4. **Run**: Hit `Cmd + R` to run on a simulator or physical iOS device.

---

## 🎨 Theme Customization

Classlly allows you to choose from several primary accents that adapt across both Standard and Rainbow modes:

* **Classic Blue** | **Sunset Orange** | **Mint Green** | **Royal Purple**

---

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details.
