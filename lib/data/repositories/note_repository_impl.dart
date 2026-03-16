/// Concrete [NoteRepository] implementation backed by encrypted SQLite.
///
/// SECURITY: Every query uses parameterized statements (the `?` syntax
/// in sqlite3 prepared statements). No user input is ever concatenated
/// into SQL strings. This eliminates SQL injection as an attack vector.
library;

import 'package:sqlite3/sqlite3.dart' as sql;

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../../data/datasource/database_helper.dart';
import '../../data/models/note_model.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';

class NoteRepositoryImpl implements NoteRepository {
  final DatabaseHelper _dbHelper;

  NoteRepositoryImpl(this._dbHelper);

  sql.Database get _db => _dbHelper.database;

  @override
  Future<List<Note>> getAllNotes() async {
    try {
      // SECURITY: No user input in this query — pure static SQL.
      final results = _db.select('''
        SELECT * FROM ${AppConstants.notesTable}
        ORDER BY is_pinned DESC, updated_at DESC
      ''');

      return results.map((row) => NoteModel.fromMap(_rowToMap(row))).toList();
    } catch (e) {
      throw DatabaseException(
        'Failed to load notes.',
        debugMessage: 'getAllNotes error: ${e.runtimeType}',
      );
    }
  }

  @override
  Future<Note?> getNoteById(int id) async {
    try {
      // SECURITY: Parameterized query — [id] is bound, not concatenated.
      final results = _db.select(
        'SELECT * FROM ${AppConstants.notesTable} WHERE id = ?',
        [id],
      );

      if (results.isEmpty) return null;
      return NoteModel.fromMap(_rowToMap(results.first));
    } catch (e) {
      throw DatabaseException(
        'Failed to load the note.',
        debugMessage: 'getNoteById error: ${e.runtimeType}',
      );
    }
  }

  @override
  Future<List<Note>> searchNotes(String query) async {
    try {
      // SECURITY: Search term is parameterized with LIKE wildcards
      // applied in Dart, not through string concatenation in SQL.
      final searchPattern = '%$query%';
      final results = _db.select(
        '''
        SELECT * FROM ${AppConstants.notesTable}
        WHERE title LIKE ? OR content LIKE ? OR category LIKE ?
        ORDER BY is_pinned DESC, updated_at DESC
        ''',
        [searchPattern, searchPattern, searchPattern],
      );

      return results.map((row) => NoteModel.fromMap(_rowToMap(row))).toList();
    } catch (e) {
      throw DatabaseException(
        'Search failed. Please try again.',
        debugMessage: 'searchNotes error: ${e.runtimeType}',
      );
    }
  }

  @override
  Future<Note> createNote(Note note) async {
    try {
      final now = DateTime.now().toUtc();
      final noteToInsert = note.copyWith(
        createdAt: now,
        updatedAt: now,
      );

      final map = NoteModel.toMap(noteToInsert);

      // SECURITY: Fully parameterized INSERT — all values are bound.
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
      return noteToInsert.copyWith(id: id);
    } catch (e) {
      throw DatabaseException(
        'Failed to save the note.',
        debugMessage: 'createNote error: ${e.runtimeType}',
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
      final updatedNote = note.copyWith(updatedAt: now);
      final map = NoteModel.toMap(updatedNote);

      // SECURITY: Fully parameterized UPDATE.
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

      return updatedNote;
    } catch (e) {
      throw DatabaseException(
        'Failed to update the note.',
        debugMessage: 'updateNote error: ${e.runtimeType}',
      );
    }
  }

  @override
  Future<void> deleteNote(int id) async {
    try {
      // SECURITY: Parameterized DELETE. Combined with PRAGMA
      // secure_delete = ON, the data is overwritten with zeros.
      _db.execute(
        'DELETE FROM ${AppConstants.notesTable} WHERE id = ?',
        [id],
      );
    } catch (e) {
      throw DatabaseException(
        'Failed to delete the note.',
        debugMessage: 'deleteNote error: ${e.runtimeType}',
      );
    }
  }

  @override
  Future<Note> togglePin(int id) async {
    try {
      // SECURITY: Parameterized query for toggling pin state.
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
      if (note == null) {
        throw const NotFoundException('Note not found.');
      }
      return note;
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException(
        'Failed to update pin status.',
        debugMessage: 'togglePin error: ${e.runtimeType}',
      );
    }
  }

  /// Converts a [sql.Row] to a standard [Map<String, dynamic>].
  Map<String, dynamic> _rowToMap(sql.Row row) {
    final map = <String, dynamic>{};
    for (final key in row.keys) {
      map[key] = row[key];
    }
    return map;
  }
}
