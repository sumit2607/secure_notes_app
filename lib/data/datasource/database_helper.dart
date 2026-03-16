/// Encrypted SQLite database helper.
///
/// SECURITY DESIGN:
/// ─────────────────
/// 1. Database encryption via SQLCipher (AES-256-CBC by default).
/// 2. Encryption key is retrieved from [EncryptionKeyService] — never
///    hardcoded or logged.
/// 3. PRAGMA key is set as the FIRST operation after opening.
/// 4. Additional security PRAGMAs (foreign_keys, secure_delete) are
///    applied immediately after key verification.
/// 5. The database file lives in the platform's app-support directory,
///    not in a user-visible location.
/// 6. Integrity check on open via quick_check PRAGMA.
/// 7. Schema versioning via user_version PRAGMA for safe migrations.
///
/// All queries in this class and in [NoteRepositoryImpl] use
/// parameterized statements — no string concatenation for SQL values.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/security/security_config.dart';
import '../../services/encryption_key_service.dart';

class DatabaseHelper {
  final sql.Database _db;

  DatabaseHelper._(this._db);

  /// Provides direct access to the underlying database.
  /// Used by [NoteRepositoryImpl] for parameterized queries.
  sql.Database get database => _db;

  /// Initializes the encrypted database.
  ///
  /// This is an async factory because key retrieval and path resolution
  /// are asynchronous, but the actual SQLite operations are synchronous
  /// (FFI-based).
  static Future<DatabaseHelper> initialize(
    EncryptionKeyService keyService,
  ) async {
    try {
      final dbPath = await _getDatabasePath();
      final key = await keyService.getOrCreateKey();

      final db = sql.sqlite3.open(dbPath);

      // ── Step 1: Apply encryption key ─────────────────────────
      // SECURITY: PRAGMA key MUST be the first statement after open.
      // SQLCipher does not support parameterized PRAGMAs, so we
      // escape the key defensively. The key is internally generated
      // (never from user input) but we still escape single quotes.
      final escapedKey = key.replaceAll("'", "''");
      db.execute("PRAGMA key = '$escapedKey';");

      // ── Step 2: Verify key correctness ───────────────────────
      // SECURITY: If the key is wrong or the DB is corrupted, this
      // query will throw a SqliteException.
      try {
        db.execute(SecurityConfig.keyVerification);
      } catch (e) {
        db.dispose();
        throw const DatabaseException(
          'Unable to open the secure database. '
          'The encryption key may be invalid or the database may be corrupted.',
          debugMessage: 'Key verification failed on sqlite_master query.',
        );
      }

      // ── Step 3: Apply security PRAGMAs ───────────────────────
      for (final pragma in SecurityConfig.securePragmas) {
        db.execute(pragma);
      }

      // ── Step 4: Run integrity check ──────────────────────────
      // SECURITY: Detects corruption early. In production, a
      // corrupted database could indicate tampering.
      try {
        final result = db.select(SecurityConfig.integrityCheck);
        if (result.isNotEmpty && result.first.values.first != 'ok') {
          debugPrint('[SECURITY] Database integrity check returned warnings.');
        }
      } catch (e) {
        // Non-fatal: log but continue. Database may still be usable.
        debugPrint('[SECURITY] Integrity check could not complete.');
      }

      // ── Step 5: Create / migrate schema ──────────────────────
      _runMigrations(db);

      return DatabaseHelper._(db);
    } on DatabaseException {
      rethrow;
    } on KeyManagementException {
      rethrow;
    } catch (e) {
      throw DatabaseException(
        'Failed to initialize the database. Please restart the application.',
        debugMessage: 'DB init error: ${e.runtimeType}',
      );
    }
  }

  /// Resolves the database file path inside the platform's
  /// application-support directory.
  ///
  /// SECURITY: Uses [getApplicationSupportDirectory] which resolves to:
  /// - Windows: %APPDATA%\com.securenotes\secure_notes_app
  /// - macOS:   ~/Library/Application Support/com.securenotes.secureNotesApp
  /// These are per-user directories, not world-readable.
  static Future<String> _getDatabasePath() async {
    final appDir = await getApplicationSupportDirectory();
    final dbDir = Directory('${appDir.path}/data');

    if (!dbDir.existsSync()) {
      dbDir.createSync(recursive: true);
    }

    return '${dbDir.path}/${AppConstants.databaseName}';
  }

  /// Runs schema migrations based on the user_version PRAGMA.
  ///
  /// Migration strategy:
  /// - user_version 0 → fresh database, create all tables.
  /// - user_version < current → run incremental migrations.
  /// - user_version == current → no action needed.
  static void _runMigrations(sql.Database db) {
    final currentVersion =
        db.select('PRAGMA user_version;').first.values.first as int;

    if (currentVersion < 1) {
      _migrateToV1(db);
    }

    // Future migrations would go here:
    // if (currentVersion < 2) _migrateToV2(db);
  }

  /// Version 1 schema: creates the notes table.
  static void _migrateToV1(sql.Database db) {
    db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.notesTable} (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        title      TEXT    NOT NULL,
        content    TEXT    NOT NULL,
        category   TEXT,
        is_pinned  INTEGER NOT NULL DEFAULT 0,
        created_at TEXT    NOT NULL,
        updated_at TEXT    NOT NULL
      );
    ''');

    // Create index for search performance
    db.execute('''
      CREATE INDEX IF NOT EXISTS idx_notes_updated_at
      ON ${AppConstants.notesTable} (updated_at DESC);
    ''');

    db.execute('PRAGMA user_version = ${AppConstants.databaseVersion};');
  }

  /// Closes the database connection.
  void close() {
    _db.dispose();
  }
}
