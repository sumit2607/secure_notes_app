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

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  // SECURITY: Use encrypted shared preferences on Android,
  // Keychain on iOS/macOS, and Credential Manager on Windows.
  final FlutterSecureStorage _storage;
  
  // FALLBACK: Used on macOS when Keychain access fails (e.g., Code: -34018)
  final Map<String, String> _memoryFallback = {};

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              wOptions: WindowsOptions(),
              mOptions: MacOsOptions(
                accountName: 'secure_notes_app',
              ),
            );

  /// Reads a value from secure storage.
  /// Returns `null` if the key does not exist.
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      if (Platform.isMacOS && kDebugMode) {
        debugPrint('SecureStorage read failed (likely -34018), using fallback: $e');
        return _memoryFallback[key];
      }
      rethrow;
    }
  }

  /// Writes a value to secure storage.
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      if (Platform.isMacOS && kDebugMode) {
        debugPrint('SecureStorage write failed (likely -34018), using fallback: $e');
        _memoryFallback[key] = value;
        return;
      }
      rethrow;
    }
  }

  /// Deletes a value from secure storage.
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      if (Platform.isMacOS && kDebugMode) {
        _memoryFallback.remove(key);
        return;
      }
      rethrow;
    }
  }

  /// Checks whether a key exists in secure storage.
  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      if (Platform.isMacOS && kDebugMode) {
        return _memoryFallback.containsKey(key);
      }
      rethrow;
    }
  }
}
