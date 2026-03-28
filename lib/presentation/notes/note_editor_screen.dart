import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/note_model.dart';
import '../../providers/note_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../widgets/app_snackbar.dart';

class NoteEditorScreen extends StatefulWidget {
  final NoteModel? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  String _selectedColor = 'yellow';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController =
        TextEditingController(text: widget.note?.content ?? '');
    _selectedColor = widget.note?.color ?? 'yellow';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (_contentController.text.isEmpty) {
      AppSnackbar.showError(context, 'Note cannot be empty');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        AppSnackbar.showError(context, 'Not authenticated');
        return;
      }

      final noteProvider = context.read<NoteProvider>();

      if (widget.note == null) {
        // Create new note
        await noteProvider.createNote(
          userId: uid,
          title: _titleController.text.isEmpty ? null : _titleController.text,
          content: _contentController.text,
          color: _selectedColor,
        );
        AppSnackbar.showSuccess(context, 'Note created successfully');
      } else {
        // Update existing note
        await noteProvider.updateNote(
          userId: uid,
          noteId: widget.note!.id,
          title: _titleController.text.isEmpty ? null : _titleController.text,
          content: _contentController.text,
          color: _selectedColor,
        );
        AppSnackbar.showSuccess(context, 'Note updated successfully');
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      AppSnackbar.showError(context, 'Failed to save note: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            onPressed: _isSaving ? null : _saveNote,
          ),
        ],
      ),
      body: Container(
        color: _getBackgroundColor(_selectedColor),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              children: [
                // Title
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Note title (optional)',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    border: InputBorder.none,
                    fillColor: Colors.transparent,
                  ),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSizes.p8),
                // Content
                TextField(
                  controller: _contentController,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: 'Start typing...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    border: InputBorder.none,
                    fillColor: Colors.transparent,
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSizes.p32),
                // Color selector
                _buildColorSelector(),
                const SizedBox(height: AppSizes.p16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(String color) {
    switch (color) {
      case 'yellow':
        return Colors.yellow.shade50;
      case 'blue':
        return Colors.blue.shade50;
      case 'red':
        return Colors.red.shade50;
      case 'green':
        return Colors.green.shade50;
      case 'purple':
        return Colors.purple.shade50;
      default:
        return Colors.white;
    }
  }

  Widget _buildColorSelector() {
    const colors = ['yellow', 'blue', 'red', 'green', 'purple'];
    final colorMap = {
      'yellow': Colors.yellow,
      'blue': Colors.blue,
      'red': Colors.red,
      'green': Colors.green,
      'purple': Colors.purple,
    };

    return Row(
      children: [
        const Text('Color: '),
        const SizedBox(width: AppSizes.p12),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: colors.map((color) {
                final isSelected = _selectedColor == color;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorMap[color],
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected
                            ? Border.all(
                                color: Colors.black,
                                width: 3,
                              )
                            : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
