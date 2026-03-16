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

1. **Dual-Layer Encryption**: 
   - **At Rest**: The entire database is encrypted using SQLCipher (AES-256-CBC).
   - **In-Database**: Sensitive fields (Title, Content) are individually encrypted using **AES-256-GCM**. This provides defense-in-depth even if the database is partially compromised.
2. **App Lock & Local Auth**:
   - The app supports a startup/resume lock screen.
   - **Biometrics**: Native support for Windows Hello / TouchID / FaceID via the `local_auth` service.
   - **Secure PIN**: Fallback PIN stored in OS secure storage.
3. **Secure Key Management**:
   - Master keys are generated using CSPRNG and stored in Hardware-backed vaults (Windows Credential Manager / macOS Keychain).
   - Keys are never hardcoded or exposed in logs.
4. **Defense Against SQL Injection**: Every single database query uses **parameterized statements**.
5. **Data Remnant Protection**: Database uses `PRAGMA secure_delete = ON` to zero-out deleted content.
6. **Inactivity Auto-Lock**: The application automatically locks sensitive data after 5 minutes of inactivity.
7. **Secure Migration**: An automated background utility safely encrypts any legacy plain-text notes found during first launch.
8. **Secure Logging**: A custom `SecureLogger` replaces standard print statements, ensuring sensitive data never reaches console/system logs.
9. **Reverse Engineering Protections (Anti-Reversing)**:
   - **Code Obfuscation**: Scrambles class/method names in release builds.
   - **Metadata Stripping**: Removes debug symbols from the final binary.

## 🛠️ Build for Release (Anti-Reversing)

To build the application with active obfuscation and metadata stripping, use the following commands:

**macOS:**
```bash
flutter build macos --obfuscate --split-debug-info=./debug_info
```

**Windows:**
```bash
flutter build windows --obfuscate --split-debug-info=./debug_info
```

*The `--obfuscate` flag scrambles the code names, and `--split-debug-info` extracts the debugging symbols into a separate folder so they aren't shipped within the application binary.*

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

## 🔐 Backup & Recovery
- **No Backdoors**: Because all data is encrypted with keys stored in your system's hardware vault, if you lose access to your OS account or forget your master PIN, your data is **cryptographically unrecoverable**.
- **Secure Backups**: To backup your notes, copy the `secure_notes.db` file from `%APPDATA%` (Windows) or `~/Library/Application Support` (macOS). 
- **Restoring**: Paste the file back into the same directory. Note that you may need your original OS account or PIN to decrypt the content.

## 🕵️ Threat Model
- **Mitigated: Casual File Theft**: An attacker stealing the `.db` file cannot read the contents without the per-user OS-vault key.
- **Mitigated: Plain-text DB Exposure**: Even if the DB is unlocked, sensitive fields are garbage (AES-GCM ciphertext).
- **Mitigated: Forensics recovery**: `secure_delete` ensures data is physically overwritten on the disk when deleted.
- **Limitation: Compromised OS**: If an attacker has a keylogger or administrative memory dump access, no client-side encryption can fully protect live data.

## 🛠️ Security Verification Checklist
- [ ] **App Lock**: Verify that the app asks for biometrics/PIN on startup.
- [ ] **Inactivity**: Wait 5 minutes; verify the app locks automatically.
- [ ] **Logging**: Run in release mode; verify no sensitive logs appear in system console.
- [ ] **Encryption**: Open the database file in a hex editor; verify all note content is non-readable.
- [ ] **Migration**: Add a plain-text note manually to a test DB; verify the app encrypts it on the next launch.

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
