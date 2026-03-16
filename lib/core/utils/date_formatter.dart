/// Date formatting utilities for consistent display across the app.
library;

import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _fullFormat = DateFormat('MMM d, yyyy · h:mm a');
  static final DateFormat _dateOnly = DateFormat('MMM d, yyyy');
  static final DateFormat _timeOnly = DateFormat('h:mm a');

  /// Formats a DateTime for full display (e.g., "Mar 15, 2026 · 2:30 PM").
  static String full(DateTime date) => _fullFormat.format(date.toLocal());

  /// Formats a DateTime showing only the date (e.g., "Mar 15, 2026").
  static String dateOnly(DateTime date) => _dateOnly.format(date.toLocal());

  /// Formats a DateTime showing only the time (e.g., "2:30 PM").
  static String timeOnly(DateTime date) => _timeOnly.format(date.toLocal());

  /// Returns a human-friendly relative time string.
  static String relative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) {
      final m = difference.inMinutes;
      return '$m ${m == 1 ? 'minute' : 'minutes'} ago';
    }
    if (difference.inHours < 24) {
      final h = difference.inHours;
      return '$h ${h == 1 ? 'hour' : 'hours'} ago';
    }
    if (difference.inDays < 7) {
      final d = difference.inDays;
      return '$d ${d == 1 ? 'day' : 'days'} ago';
    }

    return _dateOnly.format(date.toLocal());
  }
}
