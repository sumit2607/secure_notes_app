/// Note model — handles serialization between domain entities and
/// SQLite row maps.
///
/// SECURITY: Dates are stored as ISO-8601 strings (not Unix timestamps)
/// for readability and safe parsing. No sensitive data transformations
/// happen here — encryption is handled at the database layer.
library;

import '../../domain/entities/note.dart';

class NoteModel {
  NoteModel._();

  /// Converts a SQLite row [Map] to a [Note] entity.
  static Note fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int,
      title: map['title'] as String,
      content: map['content'] as String,
      category: map['category'] as String?,
      isPinned: (map['is_pinned'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Converts a [Note] entity to a SQLite-compatible [Map].
  ///
  /// Note: [id] is excluded when null (for INSERT with AUTOINCREMENT).
  static Map<String, dynamic> toMap(Note note) {
    final map = <String, dynamic>{
      'title': note.title,
      'content': note.content,
      'category': note.category,
      'is_pinned': note.isPinned ? 1 : 0,
      'created_at': note.createdAt.toUtc().toIso8601String(),
      'updated_at': note.updatedAt.toUtc().toIso8601String(),
    };

    if (note.id != null) {
      map['id'] = note.id;
    }

    return map;
  }
}
