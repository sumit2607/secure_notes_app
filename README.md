# Secure Notes - Flutter Windows Assignment

A production-style, secure desktop application for managing private notes. Built with Flutter, this app demonstrates best practices in local data security, clean architecture, and Windows desktop UX.

## 🚀 Key Features

- **Encrypted Local Storage**: All notes are stored in a SQLite database encrypted with AES-256 (via SQLCipher).
- **Master-Detail Layout**: Optimized for Windows desktop with a responsive sidebar and detail panel.
- **Fast Search**: Instant, parameterized search across note titles, content, and categories.
- **Pinned Notes**: Keep important information at the top of your list.
- **Modern Material 3 UI**: Clean, professional design with system-aware dark mode support.
- **Input Validation**: Strict length limits and sanitization to prevent data integrity issues.

## 🛡️ Security Implementation

This application follows a "Security by Design" approach for local data:

1. **SQLCipher Encryption**: The database is never stored in plain text. It uses SQLCipher with AES-256-CBC encryption.
2. **Secure Key Management**:
   - The 256-bit encryption key is generated using the OS's cryptographically secure random number generator (CSPRNG).
   - The key is **never hardcoded**.
   - It is stored using `flutter_secure_storage`, which utilizes the **Windows Credential Manager (DPAPI)** to isolate the secret to the current user account.
3. **Defense Against SQL Injection**: Every single database query uses **parameterized statements**. No raw string concatenation is used for user data.
4. **Data Remnant Protection**: The database is configured with `PRAGMA secure_delete = ON`, which overwrites deleted content with zeros to prevent data recovery from free pages.
5. **Secure App Directories**: The database file is stored in `%APPDATA%`, following platform conventions for non-public user data.
6. **No Sensitive Logging**: Debug logging is automatically suppressed in release mode, and sensitive data (like note content or keys) is never logged in any mode.

## 🏗️ Architecture

The project follows a **Clean Architecture** pattern to ensure maintainability and testability:

- **Core**: Constants, cross-cutting security configs, and custom error types.
- **Domain**: Pure business logic, entities, and repository interfaces.
- **Data**: Implementation of repositories, models for serialization, and the encrypted database helper.
- **Presentation**: UI widgets, pages, and the state management layer (Provider).
- **Services**: Platform abstractions for secure storage and key management.

## 🛠️ Tech Stack

- **Flutter**: Platform-agnostic UI framework.
- **Sqlite3 / SQLCipher**: High-performance, encrypted local storage.
- **Provider**: Lightweight and efficient state management.
- **Flutter Secure Storage**: Hardware-backed / OS-level secret management.

## ⚠️ Trade-offs & Limitations

- **Process Memory**: While data is encrypted on disk, it is decrypted in memory during the app's execution. A sophisticated attacker with administrative access and memory dump capabilities could potentially extract note content.
- **Single User Focus**: The current version assumes a single encryption key per Windows user account.
- **No Remote Backup**: Data is local-only. Loss of the machine or the Windows user profile (without backups) results in data loss.

## 🏃 How to Run on Windows

1. Ensure you have the [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) installed.
2. Clone this repository.
3. Run `flutter pub get` to fetch dependencies.
4. Run the app:
   ```bash
   flutter run -d windows
   ```

---
*Developed as a technical assignment focused on Flutter Desktop and Security.*
