/// Centralized application constants.
///
/// SECURITY: Length limits prevent resource exhaustion and potential
/// buffer-related issues. Database constants are isolated here to
/// avoid scattering magic strings across the codebase.
library;

class AppConstants {
  AppConstants._();

  // ── App Info ──────────────────────────────────────────────
  static const String appName = 'Secure Notes';
  static const String appVersion = '1.0.0';

  // ── Database ─────────────────────────────────────────────
  static const String databaseName = 'secure_notes.db';
  static const int databaseVersion = 1;
  static const String notesTable = 'notes';

  // ── Input Limits ─────────────────────────────────────────
  /// Maximum length for note titles (characters).
  static const int maxTitleLength = 200;

  /// Maximum length for note content (characters).
  static const int maxContentLength = 50000;

  /// Maximum length for category labels (characters).
  static const int maxCategoryLength = 50;

  // ── Security ─────────────────────────────────────────────
  /// Alias used in secure storage for the database encryption key.
  static const String encryptionKeyAlias = 'secure_notes_db_encryption_key';

  /// Length of the generated encryption key in bytes (256 bits).
  static const int encryptionKeyLengthBytes = 32;

  // ── UI ───────────────────────────────────────────────────
  static const double sidebarWidth = 340.0;
  static const double minWindowWidth = 800.0;
  static const double minWindowHeight = 600.0;

  // ── Predefined Categories ────────────────────────────────
  static const List<String> defaultCategories = [
    'Personal',
    'Work',
    'Ideas',
    'Important',
    'Other',
  ];
}
