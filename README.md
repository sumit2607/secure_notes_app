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

1. **Disk Encryption & Hardening**: 
   - **SQLCipher (AES-256-CBC)**: Full database encryption with `secure_delete` enabled.
   - **Enhanced Hardening**: Configured with `256,000 KDF iterations`, `HMAC-SHA512`, and `PBKDF2-HMAC-SHA512` for extreme resistance against brute-force attacks.
2. **Field-Level Encryption**:
   - **AES-256-GCM**: Sensitive fields are double-encrypted with unique IVs for every record.
   - **Decryption-on-Demand**: Notes are only decrypted in memory when actively opened.
3. **Secure Key Management**:
   - Keys are stored in Hardware-backed OS vaults (Windows Credential Manager / Apple Keychain).
   - **macOS Dev Resilience**: Includes an in-memory fallback and self-healing logic for development sessions.
4. **Advanced Access Control**:
   - **Biometric & PIN**: Hardware-backed auth (TouchID/Windows Hello) with secure PIN fallback.
   - **Auto-Lock**: Automatic lock after 5 minutes of inactivity or when the app is backgrounded/minimized.
5. **Brute-Force & Emergency Protection**:
   - **Rate Limiting**: Failed attempts trigger progressive lockouts (30s, 5m, 1h).
   - **Emergency Wipe**: Critical data and keys are wiped after 10 consecutive failed attempts.
6. **Physical & Visual Privacy**:
   - **Screen Masking**: Contents are automatically blurred when the app loses focus or is backgrounded.
   - **Clipboard Protection**: Automatically clears the system clipboard 30 seconds after copying.
7. **Integrity & Anti-Tamper**:
   - **Startup Checks**: Verifies binary integrity and detects debugger attachments.
   - **Reverse Engineering Defense**: Native AOT compilation with symbol obfuscation and metadata stripping.
8. **Secure Infrastructure**:
   - **Secure Logging**: Sanitized logging ensures no keys or content ever reach the console.
   - **Sandbox Storage**: Strictly follows platform-specific app-support directory rules.

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
