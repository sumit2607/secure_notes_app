/// Input validation utilities.
///
/// SECURITY: All user input passes through these validators before
/// reaching the database layer. This provides defense-in-depth
/// against oversized inputs and ensures data integrity.
library;

import '../constants/app_constants.dart';
import '../errors/app_exceptions.dart';

class InputValidator {
  InputValidator._();

  /// Validates and sanitizes a note title.
  ///
  /// - Must not be empty or whitespace-only.
  /// - Must not exceed [AppConstants.maxTitleLength] characters.
  /// - Leading/trailing whitespace is trimmed.
  static String validateTitle(String? title) {
    if (title == null || title.trim().isEmpty) {
      throw const ValidationException('Title cannot be empty.');
    }

    final trimmed = title.trim();

    if (trimmed.length > AppConstants.maxTitleLength) {
      throw ValidationException(
        'Title must be ${AppConstants.maxTitleLength} characters or fewer.',
      );
    }

    return trimmed;
  }

  /// Validates and sanitizes note content.
  ///
  /// - Must not be empty or whitespace-only.
  /// - Must not exceed [AppConstants.maxContentLength] characters.
  /// - Leading/trailing whitespace is trimmed.
  static String validateContent(String? content) {
    if (content == null || content.trim().isEmpty) {
      throw const ValidationException('Content cannot be empty.');
    }

    final trimmed = content.trim();

    if (trimmed.length > AppConstants.maxContentLength) {
      throw ValidationException(
        'Content must be ${AppConstants.maxContentLength} characters or fewer.',
      );
    }

    return trimmed;
  }

  /// Validates and sanitizes an optional category.
  ///
  /// Returns `null` if the input is null or whitespace-only.
  /// Otherwise trims and validates length.
  static String? validateCategory(String? category) {
    if (category == null || category.trim().isEmpty) {
      return null;
    }

    final trimmed = category.trim();

    if (trimmed.length > AppConstants.maxCategoryLength) {
      throw ValidationException(
        'Category must be ${AppConstants.maxCategoryLength} characters or fewer.',
      );
    }

    return trimmed;
  }
}
