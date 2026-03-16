/// Custom exception types for the application.
///
/// SECURITY: These exceptions provide safe, user-facing messages
/// without leaking internal details (DB paths, keys, SQL errors).
/// Internal details are kept in [debugMessage] for development only.
library;

/// Base exception for all application errors.
class AppException implements Exception {
  /// Safe message suitable for display to the user.
  final String userMessage;

  /// Internal message for debugging (never shown to users in release).
  final String? debugMessage;

  const AppException(this.userMessage, {this.debugMessage});

  @override
  String toString() => 'AppException: $userMessage';
}

/// Thrown when database operations fail.
class DatabaseException extends AppException {
  const DatabaseException(
    super.userMessage, {
    super.debugMessage,
  });
}

/// Thrown when the encryption key cannot be retrieved or created.
class KeyManagementException extends AppException {
  const KeyManagementException(
    super.userMessage, {
    super.debugMessage,
  });
}

/// Thrown when input validation fails.
class ValidationException extends AppException {
  const ValidationException(
    super.userMessage, {
    super.debugMessage,
  });
}

/// Thrown when a requested note is not found.
class NotFoundException extends AppException {
  const NotFoundException(
    super.userMessage, {
    super.debugMessage,
  });
}
