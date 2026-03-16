/// Abstract repository interface for note operations.
///
/// This abstraction decouples the domain/presentation layers from
/// the data layer, making it easy to swap implementations (e.g.,
/// for testing or migrating storage backends).
library;

import '../entities/note.dart';

abstract class NoteRepository {
  /// Retrieves all notes, ordered by pinned status then updated time.
  Future<List<Note>> getAllNotes();

  /// Retrieves a single note by its [id].
  /// Returns `null` if not found.
  Future<Note?> getNoteById(int id);

  /// Searches notes by [query] matching title or content.
  Future<List<Note>> searchNotes(String query);

  /// Creates a new note and returns it with the assigned ID.
  Future<Note> createNote(Note note);

  /// Updates an existing note. Returns the updated note.
  Future<Note> updateNote(Note note);

  /// Deletes a note by its [id].
  Future<void> deleteNote(int id);

  /// Toggles the pinned state of a note.
  Future<Note> togglePin(int id);
}
