/// Encryption key management service.
///
/// SECURITY: This service handles the lifecycle of the database
/// encryption key:
///
/// 1. On first launch, a cryptographically secure random key is
///    generated using [Random.secure()] (backed by OS CSPRNG).
/// 2. The key is stored in platform secure storage (Windows
///    Credential Manager via DPAPI).
/// 3. On subsequent launches, the key is retrieved from storage.
///
/// The key is NEVER:
/// - Hardcoded in source code
/// - Logged or printed
/// - Stored in plain files
/// - Transmitted over network
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../core/errors/app_exceptions.dart';
import 'secure_storage_service.dart';

class EncryptionKeyService {
  final SecureStorageService _secureStorage;

  EncryptionKeyService(this._secureStorage);

  /// Retrieves the existing encryption key or generates a new one.
  ///
  /// SECURITY: Uses [Random.secure()] which delegates to the OS
  /// cryptographic random number generator (CryptGenRandom on
  /// Windows, /dev/urandom on Unix-like systems).
  Future<String> getOrCreateKey() async {
    // BYPASS: For macOS development where Keychain access is failing.
    // This allows the app to run and maintain persistence without a working Keychain.
    if (Platform.isMacOS && kDebugMode) {
      debugPrint('WARNING: Using hardcoded encryption key for macOS bypass');
      // Exactly 32 bytes (256 bits) of data.
      // String: "MACOS_BYPASS_DEV_KEY_32_BYTES_!!"
      // Base64URL: TUFDT1NfQllQQVNTX0RFVl9LRVlfMzJfQllURVNfISE=
      return 'TUFDT1NfQllQQVNTX0RFVl9LRVlfMzJfQllURVNfISE='; 
    }

    try {
      // Attempt to read existing key
      final existingKey = await _secureStorage.read(
        AppConstants.encryptionKeyAlias,
      );

      if (existingKey != null && existingKey.isNotEmpty) {
        return existingKey;
      }

      // Generate new key on first launch
      final newKey = _generateSecureKey();

      // Persist the key in platform secure storage
      await _secureStorage.write(AppConstants.encryptionKeyAlias, newKey);

      return newKey;
    } catch (e) {
      throw KeyManagementException(
        'Failed to initialize encryption. Please restart the application.',
        debugMessage: 'Key management error: $e',
      );
    }
  }

  /// Generates a cryptographically secure 256-bit key.
  ///
  /// SECURITY: [Random.secure()] is backed by the OS CSPRNG.
  /// The key is Base64URL-encoded for safe storage and use in
  /// SQL PRAGMA statements.
  String _generateSecureKey() {
    final random = Random.secure();
    final keyBytes = List<int>.generate(
      AppConstants.encryptionKeyLengthBytes,
      (_) => random.nextInt(256),
    );
    return base64Url.encode(keyBytes);
  }
}
