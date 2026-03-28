import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/task_provider.dart';
import '../../core/constants/app_colors.dart';
import '../home/widgets/task_card_widget.dart';
import '../home/sheets/edit_task_sheet.dart';
import 'widgets/search_filter_sheet.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SearchFilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by title or description...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          taskProvider.setFilterQuery('');
                        },
                      )
                    : null,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => taskProvider.setFilterQuery(v),
            ),
          ),
          if (taskProvider.filterCategory != 'all' ||
              taskProvider.filterPriority != 'all' ||
              taskProvider.filterStatus != 'all')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (taskProvider.filterCategory != 'all')
                      _buildFilterChip(
                          'Category: ${taskProvider.filterCategory}',
                          () => taskProvider.setFilterCategory('all')),
                    if (taskProvider.filterPriority != 'all')
                      _buildFilterChip(
                          'Priority: ${taskProvider.filterPriority}',
                          () => taskProvider.setFilterPriority('all')),
                    if (taskProvider.filterStatus != 'all')
                      _buildFilterChip('Status: ${taskProvider.filterStatus}',
                          () => taskProvider.setFilterStatus('all')),
                  ],
                ),
              ),
            ),
          Expanded(
            child: taskProvider.filteredTasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text('No tasks matching your search',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: taskProvider.filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = taskProvider.filteredTasks[index];
                      return TaskCardWidget(
                        task: task,
                        onTap: () => context.push('/task/${task.id}'),
                        onEdit: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => EditTaskSheet(task: task),
                        ),
                        onDelete: () => taskProvider.deleteTask(task),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDeleted) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 10)),
        onDeleted: onDeleted,
        deleteIcon: const Icon(Icons.close, size: 12),
        backgroundColor: AppColors.primary.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
