/// Delete confirmation dialog.
///
/// Shows a modal dialog asking the user to confirm note deletion.
/// Returns `true` if the user confirms, `false` otherwise.
library;

import 'package:flutter/material.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final String noteTitle;

  const DeleteConfirmationDialog({
    super.key,
    required this.noteTitle,
  });

  /// Shows the dialog and returns `true` if deletion is confirmed.
  static Future<bool> show(BuildContext context, String noteTitle) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteConfirmationDialog(noteTitle: noteTitle),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.delete_outline,
          color: colorScheme.onErrorContainer,
          size: 28,
        ),
      ),
      title: const Text('Delete Note'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Are you sure you want to delete this note?',
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              noteTitle,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This action cannot be undone.',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.error.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
