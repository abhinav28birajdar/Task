import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/note_model.dart';
import '../../../providers/note_provider.dart';
import '../../../core/constants/app_colors.dart';

class NoteCard extends StatelessWidget {
  final NoteModel note;
  final String userId;
  final bool isListView;

  const NoteCard({
    Key? key,
    required this.note,
    required this.userId,
    this.isListView = false,
  }) : super(key: key);

  Color _getColorFromString(String colorString) {
    switch (colorString) {
      case 'yellow':
        return Colors.yellow.shade100;
      case 'blue':
        return Colors.blue.shade100;
      case 'red':
        return Colors.red.shade100;
      case 'green':
        return Colors.green.shade100;
      case 'purple':
        return Colors.purple.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/note-detail/${note.id}', extra: note),
      child: Card(
        color: _getColorFromString(note.color),
        child: isListView ? _buildListViewCard() : _buildGridViewCard(),
      ),
    );
  }

  Widget _buildGridViewCard() {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              if (note.title != null && note.title!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    note.title!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              // Content
              Expanded(
                child: Text(
                  note.content,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                  ),
                  maxLines: 8,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Tags and date
              const SizedBox(height: 8),
              Row(
                children: [
                  if (note.tags.isNotEmpty)
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        children: note.tags.take(2).map((tag) {
                          return Chip(
                            label: Text(
                              tag,
                              style: const TextStyle(fontSize: 10),
                            ),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    ),
                  Text(
                    _formatDate(note.updatedAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Pin and menu
        Positioned(
          top: 8,
          right: 8,
          child: _buildActionMenu(),
        ),
      ],
    );
  }

  Widget _buildListViewCard() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (note.title != null && note.title!.isNotEmpty)
                  Text(
                    note.title!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  note.content,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(note.updatedAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (note.isPinned)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.push_pin, size: 16, color: Colors.grey),
            ),
          _buildActionMenu(),
        ],
      ),
    );
  }

  Widget _buildActionMenu() {
    return Consumer<NoteProvider>(
      builder: (context, noteProvider, _) => PopupMenuButton(
        itemBuilder: (context) => [
          if (!note.isPinned)
            PopupMenuItem(
              child: const Text('Pin'),
              onTap: () =>
                  noteProvider.togglePin(userId, note.id, note.isPinned),
            ),
          if (note.isPinned)
            PopupMenuItem(
              child: const Text('Unpin'),
              onTap: () =>
                  noteProvider.togglePin(userId, note.id, note.isPinned),
            ),
          if (!note.isArchived)
            PopupMenuItem(
              child: const Text('Archive'),
              onTap: () =>
                  noteProvider.toggleArchive(userId, note.id, note.isArchived),
            ),
          if (note.isArchived)
            PopupMenuItem(
              child: const Text('Unarchive'),
              onTap: () =>
                  noteProvider.toggleArchive(userId, note.id, note.isArchived),
            ),
          PopupMenuItem(
            child: const Text('Delete'),
            onTap: () => noteProvider.deleteNote(userId, note.id),
          ),
        ],
        child: const Icon(Icons.more_vert, size: 18),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (now.difference(date).inDays < 7) {
      return '${now.difference(date).inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
