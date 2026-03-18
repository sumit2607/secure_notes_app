# Secure Notes - Flutter Desktop Assignment

A production-style, secure desktop application for managing private notes. Built with Flutter, this app demonstrates best practices in local data security, clean architecture, and modern desktop UX (Windows/macOS).

## 🚀 Key Features

- **Multi-Layer Defensive Suite**: Comprehensive security spanning from hardware-backed key storage to memory protection.
- **Enterprise-Grade Encryption**: Combines full-disk SQLCipher encryption with field-level AES-256-GCM.
- **Native OS Integration**: Leverages Windows Hello and macOS Touch ID for seamless, secure access.
- **Privacy-First UX**: Automated features like clipboard clearing and background blurring protect data in real-time.
- **Hardened for Production**: Built-in anti-tamper, anti-debugging, and obfuscation countermeasures.

## 🛡️ Security Implementation

This application implements a robust, multi-layered security architecture designed to protect sensitive data at rest, in use, and in transit:

*   **Encrypted SQLite Database (SQLCipher)**: All notes are stored within an AES-256 encrypted database. This ensures that if the device files are accessed by an unauthorized entity, the raw data remains completely unreadable.
*   **Secure Deletion**: Uses the `secure_delete` PRAGMA to ensure that when a note is deleted, its data is physically wiped from the disk, preventing recovery via forensic tools.
*   **Field-Level Encryption (AES-256-GCM)**: Sensitive note content is encrypted before storage using authenticated encryption. This provides an additional layer of protection even if the database layer itself is compromised.
*   **Hardware-Backed Key Storage**: Encryption keys are never stored in plain text or application files. Instead, they are secured in OS-level hardware vaults:
    *   **Windows**: Windows Credential Manager
    *   **macOS**: Apple Keychain
*   **Biometric Authentication with PIN Fallback**: Only authorized users can access the app using platform-native biometrics (Touch ID / Windows Hello). A secure PIN system provides a reliable fallback.
*   **Auto-Lock Context Awareness**: The application monitors user activity and automatically locks after a period of inactivity or when the app is backgrounded/minimized.
*   **PIN Brute-Force Protection**: Implements progressive lockout delays and rate-limiting to prevent automated PIN-guessing attacks.
*   **Clipboard Auto-Clear**: To prevent sensitive data leakage to other applications, any content copied to the clipboard is automatically cleared after a brief, configurable interval.
*   **Screenshot & Background Blur Protection**: Sensitive content is hidden/blurred when the app loses focus or during screen recording/sharing to prevent accidental exposure.
*   **Memory Protection**: Decrypted data is kept in memory only for the minimum duration required for display and is cleared immediately after use to mitigate memory-dump attacks.
*   **Tamper Detection & Anti-Debugging**: Real-time checks detect if the application is being modified or if a debugger is attached, blocking execution to prevent exploitation.
*   **Reverse Engineering Protection**: Production builds utilize AOT compilation, symbol obfuscation, and metadata stripping to hinder static and dynamic analysis.
*   **Secure Logging Protocol**: A sanitized logging system ensures that sensitive information, such as note content or encryption keys, is never recorded.
*   **CSPRNG Randomness**: All cryptographic operations (IV generation, key derivation) use OS-level cryptographically secure pseudo-random number generators.
*   **Sandboxed Local Storage**: Application data is strictly confined to OS-secured, user-specific directories to prevent cross-app data access.
*   **Emergency Data Wipe**: In the event of repeated unauthorized access attempts, the app can securely purge all sensitive keys and local data.

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

### 🛡️ Integrity & Anti-Debugging
- **Real-Time Protection**: The application uses the `IntegrityService` to monitor the environment for security threats.
- **Anti-Debugging (Windows)**: Uses the Win32 API `IsDebuggerPresent` from `kernel32.dll` to detect if a debugger is attached. If detected, the application will log the event and terminate immediately to prevent reverse engineering.
- **Secure Startup**: The check is performed at the very beginning of the `main()` function to ensure the environment is safe before any sensitive data is loaded.

## 🏗️ Architecture

The project follows a **Clean Architecture** pattern to ensure maintainability:

- **Core**: Security primitives (AES-GCM), custom loggers, and error handlers.
- **Domain**: Pure business logic, note entities, and repository interfaces.
- **Data**: SQLCipher implementation, secure note models, and field-encryption logic.
- **Presentation**: UI widgets, state controllers, and the Security Gate (Lock Screen).
- **Services**: Platform abstractions (Keychain/Credential Manager, Biometrics, Integrity).

## 🧰 Development & Troubleshooting (Windows)

### SQLCipher DLL Loading
The `sqlcipher_flutter_libs` package on Windows bundles the encrypted SQLite engine as `sqlite3.dll`. Ensure that the `_configureSqlCipher` function in `lib/main.dart` is configured to load the correct library:

```dart
} else if (Platform.isWindows) {
  open.overrideFor(OperatingSystem.windows, () => DynamicLibrary.open('sqlite3.dll'));
}
```

## 📦 Windows Installer (Inno Setup)

To build a production-ready, system-wide installer on Windows:

1.  **Build Release Binaries**:
    ```powershell
    flutter build windows --release
    ```
2.  **Run Inno Setup**:
    - Download and install [Inno Setup 6+](https://jrsoftware.org/isdl.php).
    - Open `windows/installer.iss` in Inno Setup.
    - Click **Compile (F9)**.
3.  **Output**: The installer will be generated at `windows/SecureNotesInstaller.exe`.

### 🛡️ Why Admin-Only Install but Usable by All?
-   **System Integrity**: Installing in `C:/Program Files` requires Admin rights. This prevents non-admin users from modifying the application binaries (the `.exe` and `.dll` files), protecting the app against local tampering.
-   **System-Wide Use**: Once installed by an Admin, the app icon is added to the Start Menu for all users on the machine. Any user can launch the app, but they cannot delete or modify the core app files.

### 🔐 Security Architecture & Data Isolation
-   **Binary Protection**: Binaries are stored in a read-only area for standard users.
-   **Per-User Data Isolation**: Even though the app is shared, each Windows user has their own private `%LOCALAPPDATA%` folder.
    -   User A's database is at `C:/Users/UserA/AppData/Local/com.securenotes/data/secure_notes.db`.
    -   User B's database is entirely separate at `C:/Users/UserB/AppData/Local/com.securenotes/data/secure_notes.db`.
-   **Encryption Boundary**: One user cannot access another user's encrypted database because they are isolated by OS-level file permissions and secured with individual hardware-vault keys.

### 🧪 Testing Multi-User Behavior
1.  Install the app as **Administrator**.
2.  Log in as **User A**, create a note, and set a PIN.
3.  Switch User/Logout and log in as **User B**.
4.  Open the app; verify it asks for a *new* setup or is currently empty.
5.  Verify **User B** cannot see **User A's** notes.
6.  Navigate to User A's `AppData` folder as User B; verify access is denied by Windows.
