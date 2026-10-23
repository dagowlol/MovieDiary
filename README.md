# Movie Diary 🎬

A personal movie tracking mobile application built using Flutter and Dart for our PRM393 university course. Movie Diary allows users to record films they have watched, maintain a watchlist of planned movies, log reviews and ratings, and view personal movie statistics with offline-first SQLite persistence.

---

## 🛠️ Technology Stack

- **Framework:** [Flutter](https://flutter.dev/) (v3.13.2+)
- **Language:** [Dart](https://dart.dev/) (v3.13.2+)
- **Local Storage / Database:** SQLite (via `sqflite` & `path` packages)
- **UI Framework:** Material 3 Design
- **Architecture:** Feature-based modular structure

---

## 🚀 Setup & Run Instructions

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed and added to your system `PATH`.
- An IDE with Flutter plugins: **VS Code** or **Android Studio**.
- An Android Emulator, iOS Simulator, or connected physical device with USB debugging enabled.

### Quick Start Commands

1. **Navigate to the Flutter project folder:**
   ```bash
   cd MovieDiary/movie
   ```

2. **Get dependencies:**
   ```bash
   flutter pub get
   ```

3. **Check code health (Static Analysis):**
   ```bash
   flutter analyze
   ```

4. **Launch the application:**
   ```bash
   flutter run
   ```

5. **Run test suite:**
   ```bash
   flutter test
   ```

---

## 👥 Team Members & Responsibilities

| Member | Assigned Focus Area |
| :--- | :--- |
| **Long** | Movie Library UI, Movie Cards, Search bar, and Category/Genre Filters |
| **Doan** | `Movie` Model, SQLite Database (`DatabaseHelper`), and Add/Edit Movie Form |
| **Tai** | Movie Detail screen, Watchlist screen, Statistics screen, and Integration Testing |

---

## 📖 Team Development Guide

All members must read and follow [TEAM_GUIDE.md](TEAM_GUIDE.md) before starting implementation. It contains:
- Folder and file descriptions.
- Beginner-friendly coding conventions.
- Shared `Movie` model schema and SQLite method signatures.
- 7-day development roadmap.
- Git branching and collaboration workflow.
- Pre-submission CRUD verification checklist.
