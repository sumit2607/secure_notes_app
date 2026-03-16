import 'package:sqlite3/sqlite3.dart' as sql;
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/security/encryption_service.dart';
import '../../core/security/secure_logger.dart';
import '../../data/datasource/database_helper.dart';
import '../../data/models/note_model.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';

/// Concrete [NoteRepository] implementation backed by encrypted SQLite
/// and field-level AES-GCM encryption.
///
/// SECURITY:
/// 1. Entire DB is encrypted at rest (SQLCipher).
/// 2. Sensitive fields (title, content) are individually encrypted (AES-GCM).
/// 3. Parameterized queries prevent SQL injection.
class NoteRepositoryImpl implements NoteRepository {
  final DatabaseHelper _dbHelper;
  final EncryptionService _encryption;

  NoteRepositoryImpl(this._dbHelper, this._encryption);

  sql.Database get _db => _dbHelper.database;

  @override
  Future<List<Note>> getAllNotes() async {
    try {
      final results = _db.select('''
        SELECT * FROM ${AppConstants.notesTable}
        ORDER BY is_pinned DESC, updated_at DESC
      ''');

      final notes = <Note>[];
      for (final row in results) {
        notes.add(await _decryptNote(NoteModel.fromMap(_rowToMap(row))));
      }
      return notes;
    } catch (e) {
      SecureLogger.error('REPO', 'Failed to load notes', e);
      throw DatabaseException(
        'Failed to load notes.',
        debugMessage: 'getAllNotes error: $e',
      );
    }
  }

  @override
  Future<Note?> getNoteById(int id) async {
    try {
      final results = _db.select(
        'SELECT * FROM ${AppConstants.notesTable} WHERE id = ?',
        [id],
      );

      if (results.isEmpty) return null;
      return await _decryptNote(NoteModel.fromMap(_rowToMap(results.first)));
    } catch (e) {
      SecureLogger.error('REPO', 'Failed to load note $id', e);
      throw DatabaseException(
        'Failed to load the note.',
        debugMessage: 'getNoteById error: $e',
      );
    }
  }

  @override
  Future<List<Note>> searchNotes(String query) async {
    if (query.isEmpty) return getAllNotes();
    
    try {
      // SECURITY: Because fields are encrypted, we cannot use SQL LIKE.
      // We load and decrypt notes, then filter in memory.
      // For a desktop app with < 10,000 notes, this is extremely fast.
      final allNotes = await getAllNotes();
      final lowerQuery = query.toLowerCase();
      
      return allNotes.where((note) {
        return note.title.toLowerCase().contains(lowerQuery) ||
               note.content.toLowerCase().contains(lowerQuery) ||
               (note.category?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    } catch (e) {
      SecureLogger.error('REPO', 'Search failed', e);
      throw DatabaseException(
        'Search failed. Please try again.',
        debugMessage: 'searchNotes error: $e',
      );
    }
  }

  @override
  Future<Note> createNote(Note note) async {
    try {
      final now = DateTime.now().toUtc();
      final encryptedNote = await _encryptNote(note.copyWith(
        createdAt: now,
        updatedAt: now,
      ));

      final map = NoteModel.toMap(encryptedNote);

      _db.execute(
        '''
        INSERT INTO ${AppConstants.notesTable}
          (title, content, category, is_pinned, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?)
        ''',
        [
          map['title'],
          map['content'],
          map['category'],
          map['is_pinned'],
          map['created_at'],
          map['updated_at'],
        ],
      );

      final id = _db.lastInsertRowId;
      return note.copyWith(id: id, createdAt: now, updatedAt: now);
    } catch (e) {
      SecureLogger.error('REPO', 'Failed to create note', e);
      throw DatabaseException(
        'Failed to save the note.',
        debugMessage: 'createNote error: $e',
      );
    }
  }

  @override
  Future<Note> updateNote(Note note) async {
    if (note.id == null) {
      throw const ValidationException('Cannot update a note without an ID.');
    }

    try {
      final now = DateTime.now().toUtc();
      final encryptedNote = await _encryptNote(note.copyWith(updatedAt: now));
      final map = NoteModel.toMap(encryptedNote);

      _db.execute(
        '''
        UPDATE ${AppConstants.notesTable}
        SET title = ?, content = ?, category = ?, is_pinned = ?, updated_at = ?
        WHERE id = ?
        ''',
        [
          map['title'],
          map['content'],
          map['category'],
          map['is_pinned'],
          map['updated_at'],
          note.id,
        ],
      );

      return note.copyWith(updatedAt: now);
    } catch (e) {
      SecureLogger.error('REPO', 'Failed to update note', e);
      throw DatabaseException(
        'Failed to update the note.',
        debugMessage: 'updateNote error: $e',
      );
    }
  }

  @override
  Future<void> deleteNote(int id) async {
    try {
      _db.execute(
        'DELETE FROM ${AppConstants.notesTable} WHERE id = ?',
        [id],
      );
    } catch (e) {
      SecureLogger.error('REPO', 'Failed to delete note', e);
      throw DatabaseException(
        'Failed to delete the note.',
        debugMessage: 'deleteNote error: $e',
      );
    }
  }

  @override
  Future<Note> togglePin(int id) async {
    try {
      _db.execute(
        '''
        UPDATE ${AppConstants.notesTable}
        SET is_pinned = CASE WHEN is_pinned = 1 THEN 0 ELSE 1 END,
            updated_at = ?
        WHERE id = ?
        ''',
        [DateTime.now().toUtc().toIso8601String(), id],
      );

      final note = await getNoteById(id);
      if (note == null) throw const NotFoundException('Note not found.');
      return note;
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to update pin status.');
    }
  }

  /// Performs migration of plain-text notes to encrypted versions.
  /// 
  /// SECURITY: Once a note is migrated, the plain-text version is gone.
  Future<void> migrateLegacyNotes() async {
    try {
      final results = _db.select('SELECT * FROM ${AppConstants.notesTable}');
      int migratedCount = 0;

      for (final row in results) {
        final title = row['title'] as String;
        final content = row['content'] as String;

        // If either field is not encrypted, migrate the whole record.
        if (!title.startsWith('encv1:') || !content.startsWith('encv1:')) {
          final note = NoteModel.fromMap(_rowToMap(row));
          await updateNote(note); // updateNote handles encryption
          migratedCount++;
        }
      }

      if (migratedCount > 0) {
        SecureLogger.security('Successfully migrated $migratedCount legacy notes to encrypted format');
      }
    } catch (e) {
      SecureLogger.error('MIGRATION', 'Failed to migrate notes', e);
      // We don't throw here to avoid blocking app startup, but we log the error.
    }
  }

  // ── Helper Methods ───────────────────────────────────────────

  Future<Note> _encryptNote(Note note) async {
    return note.copyWith(
      title: await _encryption.encrypt(note.title),
      content: await _encryption.encrypt(note.content),
    );
  }

  Future<Note> _decryptNote(Note note) async {
    return note.copyWith(
      title: await _encryption.decrypt(note.title),
      content: await _encryption.decrypt(note.content),
    );
  }

  Map<String, dynamic> _rowToMap(sql.Row row) {
    final map = <String, dynamic>{};
    for (final key in row.keys) {
      map[key] = row[key];
    }
    return map;
  }
}
