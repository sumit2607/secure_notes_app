/// Secure storage service — abstraction over platform key-value storage.
///
/// SECURITY: On Windows, [FlutterSecureStorage] uses the Windows
/// Credential Manager (backed by DPAPI), which ties stored secrets
/// to the current Windows user account. This means:
///
/// - The encryption key is protected by the user's Windows login.
/// - Other user accounts on the same machine cannot read it.
/// - It is NOT protected against malware running as the same user.
///
/// This wrapper isolates the storage dependency so it can be swapped
/// or mocked during testing without changing calling code.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  // SECURITY: Use encrypted shared preferences on Android,
  // Keychain on iOS/macOS, and Credential Manager on Windows.
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              wOptions: WindowsOptions(),
              mOptions: const MacOsOptions(
                accountName: 'secure_notes_app',
              ),
            );

  /// Reads a value from secure storage.
  /// Returns `null` if the key does not exist.
  Future<String?> read(String key) async {
    return _storage.read(key: key);
  }

  /// Writes a value to secure storage.
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Deletes a value from secure storage.
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// Checks whether a key exists in secure storage.
  Future<bool> containsKey(String key) async {
    return _storage.containsKey(key: key);
  }
}
