import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/task_provider.dart';

class SearchFilterSheet extends StatelessWidget {
  const SearchFilterSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Filters',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: ['All', 'Work', 'Personal', 'Shopping', 'Health', 'Other']
                .map((cat) {
              final isSelected =
                  taskProvider.filterCategory == cat.toLowerCase();
              return ChoiceChip(
                label: Text(cat),
                selected: isSelected,
                onSelected: (v) =>
                    taskProvider.setFilterCategory(cat.toLowerCase()),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text('Priority', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: ['All', 'Low', 'Medium', 'High'].map((p) {
              final isSelected = taskProvider.filterPriority == p.toLowerCase();
              return ChoiceChip(
                label: Text(p),
                selected: isSelected,
                onSelected: (v) =>
                    taskProvider.setFilterPriority(p.toLowerCase()),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: ['All', 'Completed', 'Pending'].map((s) {
              final isSelected = taskProvider.filterStatus == s.toLowerCase();
              return ChoiceChip(
                label: Text(s),
                selected: isSelected,
                onSelected: (v) =>
                    taskProvider.setFilterStatus(s.toLowerCase()),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply Filters'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              taskProvider.setFilterCategory('all');
              taskProvider.setFilterPriority('all');
              taskProvider.setFilterStatus('all');
              Navigator.pop(context);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
