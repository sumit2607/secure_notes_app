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

## 🏗️ Architecture

The project follows a **Clean Architecture** pattern to ensure maintainability:

- **Core**: Security primitives (AES-GCM), custom loggers, and error handlers.
- **Domain**: Pure business logic, note entities, and repository interfaces.
- **Data**: SQLCipher implementation, secure note models, and field-encryption logic.
- **Presentation**: UI widgets, state controllers, and the Security Gate (Lock Screen).
- **Services**: Platform abstractions (Keychain/Credential Manager, Biometrics).

## 🔐 Backup & Recovery
- **No Backdoors**: Because all data is encrypted with keys stored in your system's hardware vault, if you lose access to your OS account or forget your master PIN, your data is **cryptographically unrecoverable**.
- **Manual Backups**: You can backup the `secure_notes.db` file from the app support directory. Note that the file remains encrypted and requires the original OS vault to open.

## 🕵️ Threat Model
- **Mitigated: Casual File Theft**: An attacker stealing the `.db` file cannot read contents without the OS-vault key.
- **Mitigated: Plain-text DB Exposure**: Even in an unlocked DB, sensitive fields are stored as AES-GCM ciphertexts.
- **Mitigated: Forensics recovery**: Deleted data is physically overwritten via `secure_delete`.
- **Limitation: Compromised OS**: Administrative access or keyloggers on a host OS can still potentially capture live data.

## 🛠️ Security Verification Checklist
- [ ] **App Lock**: Verify that the app asks for biometrics/PIN on startup once enabled.
- [ ] **Inactivity**: Wait 5 minutes; verify the app locks automatically.
- [ ] **Hex Verification**: Open the `.db` in a hex editor; verify titles/content are gibberish.
- [ ] **Migration**: Check that old plain-text notes are automatically encrypted on launch.

---
*Developed as a technical assignment focused on Flutter Desktop Security.*
