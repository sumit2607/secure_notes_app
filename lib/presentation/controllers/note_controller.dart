/// Note controller — state management via [ChangeNotifier].
///
/// Manages the list of notes, selection, search, and CRUD operations.
/// All errors are caught and exposed via [errorMessage] for the UI
/// to display safely. Note contents are never logged.
library;

import 'package:flutter/foundation.dart';

import '../../core/errors/app_exceptions.dart';
import '../../core/utils/input_validator.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';

class NoteController extends ChangeNotifier {
  final NoteRepository _repository;

  NoteController(this._repository) {
    loadNotes();
  }

  // ── State ──────────────────────────────────────────────────
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  Note? _selectedNote;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;
  bool _isEditing = false;

  // ── Getters ────────────────────────────────────────────────
  List<Note> get notes =>
      _searchQuery.isEmpty ? _notes : _filteredNotes;
  Note? get selectedNote => _selectedNote;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEditing => _isEditing;
  bool get hasNotes => _notes.isNotEmpty;

  // ── CRUD Operations ────────────────────────────────────────

  /// Loads all notes from the repository.
  Future<void> loadNotes() async {
    _setLoading(true);
    _clearError();

    try {
      _notes = await _repository.getAllNotes();
      _applySearch();

      // Refresh selected note if it still exists
      if (_selectedNote != null) {
        _selectedNote = _notes
            .where((n) => n.id == _selectedNote!.id)
            .firstOrNull;
      }
    } on AppException catch (e) {
      _errorMessage = e.userMessage;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred.';
    } finally {
      _setLoading(false);
    }
  }

  /// Creates a new note after validating input.
  Future<bool> createNote({
    required String title,
    required String content,
    String? category,
  }) async {
    _clearError();

    try {
      // SECURITY: Validate and sanitize all user input before persistence.
      final validTitle = InputValidator.validateTitle(title);
      final validContent = InputValidator.validateContent(content);
      final validCategory = InputValidator.validateCategory(category);

      final note = Note(
        title: validTitle,
        content: validContent,
        category: validCategory,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await _repository.createNote(note);
      _notes.insert(0, created);
      _selectedNote = created;
      _applySearch();
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.userMessage;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to create note.';
      notifyListeners();
      return false;
    }
  }

  /// Updates an existing note after validating input.
  Future<bool> updateNote({
    required Note note,
    required String title,
    required String content,
    String? category,
    bool? isPinned,
  }) async {
    _clearError();

    try {
      final validTitle = InputValidator.validateTitle(title);
      final validContent = InputValidator.validateContent(content);
      final validCategory = InputValidator.validateCategory(category);

      final updatedNote = note.copyWith(
        title: validTitle,
        content: validContent,
        category: validCategory,
        isPinned: isPinned,
      );

      final result = await _repository.updateNote(updatedNote);

      final index = _notes.indexWhere((n) => n.id == result.id);
      if (index != -1) {
        _notes[index] = result;
      }

      _selectedNote = result;
      _isEditing = false;
      _applySearch();
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.userMessage;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update note.';
      notifyListeners();
      return false;
    }
  }

  /// Deletes a note by ID with no confirmation (UI handles confirmation).
  Future<bool> deleteNote(int id) async {
    _clearError();

    try {
      await _repository.deleteNote(id);
      _notes.removeWhere((n) => n.id == id);

      if (_selectedNote?.id == id) {
        _selectedNote = null;
        _isEditing = false;
      }

      _applySearch();
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.userMessage;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to delete note.';
      notifyListeners();
      return false;
    }
  }

  /// Toggles the pinned status of a note.
  Future<void> togglePin(Note note) async {
    if (note.id == null) return;
    _clearError();

    try {
      final updated = await _repository.togglePin(note.id!);

      final index = _notes.indexWhere((n) => n.id == updated.id);
      if (index != -1) {
        _notes[index] = updated;
      }

      if (_selectedNote?.id == updated.id) {
        _selectedNote = updated;
      }

      // Re-sort: pinned notes first
      _notes.sort((a, b) {
        if (a.isPinned != b.isPinned) {
          return a.isPinned ? -1 : 1;
        }
        return b.updatedAt.compareTo(a.updatedAt);
      });

      _applySearch();
      notifyListeners();
    } on AppException catch (e) {
      _errorMessage = e.userMessage;
      notifyListeners();
    }
  }

  // ── Selection & Navigation ──────────────────────────────────

  /// Selects a note for viewing in the detail panel.
  void selectNote(Note? note) {
    _selectedNote = note;
    _isEditing = false;
    _clearError();
    notifyListeners();
  }

  /// Starts editing the currently selected note.
  void startEditing() {
    if (_selectedNote != null) {
      _isEditing = true;
      notifyListeners();
    }
  }

  /// Starts creating a new note (enters editing mode with no selection).
  void startCreating() {
    _selectedNote = null;
    _isEditing = true;
    _clearError();
    notifyListeners();
  }

  /// Cancels the current editing operation.
  void cancelEditing() {
    _isEditing = false;
    notifyListeners();
  }

  // ── Search ──────────────────────────────────────────────────

  /// Updates the search query and filters notes.
  void search(String query) {
    _searchQuery = query.trim();
    _applySearch();
    notifyListeners();
  }

  /// Clears the search query.
  void clearSearch() {
    _searchQuery = '';
    _filteredNotes = [];
    notifyListeners();
  }

  // ── Error Management ────────────────────────────────────────

  /// Clears any displayed error message.
  void dismissError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── Private Helpers ─────────────────────────────────────────

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredNotes = [];
      return;
    }

    final lowerQuery = _searchQuery.toLowerCase();
    _filteredNotes = _notes.where((note) {
      return note.title.toLowerCase().contains(lowerQuery) ||
          note.content.toLowerCase().contains(lowerQuery) ||
          (note.category?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
