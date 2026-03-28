import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../providers/task_provider.dart';
import '../../core/constants/app_sizes.dart';
import '../../presentation/widgets/skeleton_loader.dart';
import '../home/widgets/task_card_widget.dart';
import '../widgets/app_dialog.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        context.read<TaskProvider>().startListening(uid);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final starredTasks = taskProvider.starredTasks
        .where((t) =>
            _searchController.text.isEmpty ||
            t.title
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()) ||
            t.description
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Starred Tasks'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search starred tasks...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),
          // Starred tasks list
          Expanded(
            child: taskProvider.isLoading
                ? _buildShimmerLoading()
                : starredTasks.isEmpty
                    ? _buildEmptyState()
                    : _buildTasksList(starredTasks, taskProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList(List<dynamic> tasks, TaskProvider taskProvider) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.p16),
      itemCount: tasks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return GestureDetector(
          onLongPress: () => _showEditTask(task),
          child: TaskCardWidget(
            task: task,
            onTap: () => context.push('/task/${task.id}'),
            onEdit: () => _showEditTask(task),
            onDelete: () async {
              final confirm = await AppDialog.confirm(
                context,
                'Delete Task',
                'Are you sure you want to delete this task?',
              );
              if (confirm == true) {
                taskProvider.deleteTask(task);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_outline, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No starred tasks yet',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Star your important tasks to see them here',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.p16),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => const ShimmerTaskCard(),
    );
  }

  void _showEditTask(task) {
    // Will implement edit functionality for tasks
  }
}
