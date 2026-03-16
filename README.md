# Secure Notes - Flutter Desktop Assignment

A production-style, secure desktop application for managing private notes. Built with Flutter, this app demonstrates best practices in local data security, clean architecture, and modern desktop UX (Windows/macOS).

## 🚀 Key Features

- **Multi-Layer Encryption**: Data is encrypted both at the database level and the individual field level.
- **Biometric & PIN Lock**: Native support for Windows Hello / TouchID and a secure fallback PIN.
- **Inactivity Auto-Lock**: Automatically secures your data after 5 minutes of idleness.
- **Fast Search**: Instant in-memory search across encrypted note titles and content.
- **Modern Material 3 UI**: Clean design with master-detail layout optimized for desktop.
- **Release Hardening**: Built-in protection against reverse engineering and memory leaks.

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
4. **Defense Against SQL Injection**: Every database query uses **parameterized statements**.
5. **Data Remnant Protection**: Database uses `PRAGMA secure_delete = ON` to zero-out deleted content on disk.
6. **Inactivity Auto-Lock**: The application automatically locks sensitive data after 5 minutes of inactivity.
7. **Secure Migration**: An automated background utility safely encrypts any legacy plain-text notes found during first launch.
8. **Secure Logging**: A custom `SecureLogger` replaces standard print statements, ensuring sensitive data never reaches console/system logs.
9. **Reverse Engineering Protections (Anti-Reversing)**:
   - **Code Obfuscation**: Scrambles class/method names in release builds using `flutter build --obfuscate`.
   - **Metadata Stripping**: Removes debug symbols from the final binary using `--split-debug-info`.

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
