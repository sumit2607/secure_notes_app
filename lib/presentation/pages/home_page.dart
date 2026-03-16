/// Home page — master-detail layout for the Secure Notes app.
///
/// Left panel: Search bar + scrollable list of notes.
/// Right panel: Note detail view, editor, or empty state.
///
/// The layout is responsive: when the window is narrow, the sidebar
/// adjusts gracefully. This follows Windows desktop UI conventions.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../controllers/note_controller.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/note_list_tile.dart';
import 'note_detail_panel.dart';
import 'note_editor_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final controller = context.watch<NoteController>();

    if (isMobile) {
      final showDetail = controller.selectedNote != null || controller.isEditing;

      return PopScope(
        canPop: !showDetail,
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          if (didPop) return;
          if (controller.isEditing) {
            controller.cancelEditing();
          } else {
            controller.selectNote(null);
          }
        },
        child: Scaffold(
          body: SafeArea(
            child: showDetail
                ? Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: BackButton(
                            onPressed: () {
                              if (controller.isEditing) {
                                controller.cancelEditing();
                              } else {
                                controller.selectNote(null);
                              }
                            },
                          ),
                        ),
                      ),
                      const Expanded(child: _DetailPanel()),
                    ],
                  )
                : const _NoteListPanel(isMobile: true),
          ),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          // ── Left Panel (Sidebar) ─────────────────────────
          const _NoteListPanel(isMobile: false),

          // Divider
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.3),
          ),

          // ── Right Panel (Detail / Editor) ────────────────
          const Expanded(child: _DetailPanel()),
        ],
      ),
    );
  }
}

/// Left sidebar: app header, search, and notes list.
class _NoteListPanel extends StatelessWidget {
  final bool isMobile;
  const _NoteListPanel({this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = context.watch<NoteController>();

    Widget content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── App Header ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 20,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConstants.appName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${controller.notes.length} ${controller.notes.length == 1 ? 'note' : 'notes'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                // New note button
                IconButton.filled(
                  onPressed: () => controller.startCreating(),
                  icon: const Icon(Icons.add, size: 20),
                  tooltip: 'New Note',
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),

          // ── Search Bar ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: TextField(
              onChanged: (value) => controller.search(value),
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: Icon(
                  Icons.search,
                  size: 20,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                suffixIcon: controller.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => controller.clearSearch(),
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),

          const SizedBox(height: 4),

          // ── Notes List ─────────────────────────────────────
          Expanded(
            child: _buildNotesList(context, controller),
          ),

          // ── Footer ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 14,
                  color: colorScheme.primary.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  'Encrypted Storage',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

    if (isMobile) {
      return content;
    }

    return SizedBox(
      width: AppConstants.sidebarWidth,
      child: content,
    );
  }

  Widget _buildNotesList(BuildContext context, NoteController controller) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!controller.hasNotes && controller.searchQuery.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.note_add_outlined,
        title: 'No notes yet',
        subtitle: 'Create your first secure note to get started.',
        onAction: () => controller.startCreating(),
        actionLabel: 'Create Note',
      );
    }

    final notes = controller.notes;

    if (notes.isEmpty && controller.searchQuery.isNotEmpty) {
      return EmptyStateWidget(
        icon: Icons.search_off,
        title: 'No results',
        subtitle: 'No notes match "${controller.searchQuery}".',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return NoteListTile(
          note: note,
          isSelected: controller.selectedNote?.id == note.id,
          onTap: () => controller.selectNote(note),
        );
      },
    );
  }
}

/// Right panel: shows detail, editor, or empty state.
class _DetailPanel extends StatelessWidget {
  const _DetailPanel();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NoteController>();

    // Editing mode (new or existing note)
    if (controller.isEditing) {
      return NoteEditorPanel(
        key: ValueKey(controller.selectedNote?.id ?? 'new'),
        note: controller.selectedNote,
      );
    }

    // Viewing a selected note
    if (controller.selectedNote != null) {
      final note = controller.selectedNote!;
      return NoteDetailPanel(
        key: ValueKey(note.id),
        note: note,
        onEdit: () => controller.startEditing(),
        onDelete: () async {
          final confirmed = await DeleteConfirmationDialog.show(
            context,
            note.title,
          );
          if (confirmed && note.id != null) {
            final success = await controller.deleteNote(note.id!);
            if (success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Note deleted'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        },
        onTogglePin: () => controller.togglePin(note),
      );
    }

    // No note selected — empty state
    return EmptyStateWidget(
      icon: Icons.article_outlined,
      title: 'Select a note',
      subtitle: 'Choose a note from the list to view its contents, '
          'or create a new one.',
      onAction: () => controller.startCreating(),
      actionLabel: 'New Note',
    );
  }
}
