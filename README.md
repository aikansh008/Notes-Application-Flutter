# Notes Application - Flutter

A Flutter-based Notes Application with offline support, authentication, and connectivity-aware syncing. This project allows users to create, view, and manage notes efficiently.

---

## Features

- User Authentication (Login/Signup)
- Offline notes support with SQLite
- Auto-sync notes when internet connectivity is available
- Dark & Light theme support
- Settings screen
- Simple and clean UI

---

## Getting Started

Follow these steps to get the project running on your local machine.

### 1. Clone the Repository

Clone the project from GitHub:

```bash
git clone https://github.com/aikansh008/Notes-Application-Flutter.git


```
cd Notes-Application-Flutter

2. Install Dependencies
   Install all required Flutter packages:
```bash
flutter pub get
```

3. Run the Application

To run the app on your connected device or emulator:
```bash
flutter run --release
```
Note: Running with --release ensures the app runs without debugging enabled.

Project Structure

lib/

features/auth/ → Authentication screens (Login/Signup)

features/notes/ → Notes UI and management

features/offlinesupport/ → SQLite database & sync service

features/setting/ → Settings screen

core/theme/ → App themes and color definitions

main.dart → App entry point

pubspec.yaml → Project dependencies and assets


Dependencies

Key packages used:

flutter → Flutter SDK

connectivity_plus → Check internet connectivity

shared_preferences → Store JWT token and app data

sqflite → SQLite database support

path_provider → Access device paths
