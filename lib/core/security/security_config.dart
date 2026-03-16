/// Security configuration and SQLite PRAGMA settings.
///
/// SECURITY: These PRAGMAs harden the database against common attack
/// vectors and improve data safety:
///
/// - `foreign_keys = ON`: Enforces referential integrity.
/// - `secure_delete = ON`: Overwrites deleted data with zeros instead
///   of just marking pages as free, reducing data remnant exposure.
/// - `auto_vacuum = INCREMENTAL`: Reclaims space, reducing stale data.
library;

class SecurityConfig {
  SecurityConfig._();

  /// SQL PRAGMAs applied after the encryption key, in order.
  ///
  /// SECURITY: These are applied after PRAGMA key so that the database
  /// is already unlocked when they execute.
  static const List<String> securePragmas = [
    'PRAGMA foreign_keys = ON;',
    'PRAGMA secure_delete = ON;',
    'PRAGMA auto_vacuum = INCREMENTAL;',
  ];

  /// Quick integrity check query.
  /// Returns 'ok' if the database is not corrupted.
  static const String integrityCheck = "PRAGMA quick_check;";

  /// Verifies that the database was opened with the correct key.
  /// If the key is wrong, this query will throw an exception.
  static const String keyVerification =
      'SELECT count(*) FROM sqlite_master;';
}
