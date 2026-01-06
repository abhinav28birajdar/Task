import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../providers/hybrid_task_provider.dart';
import '../providers/hybrid_category_provider.dart';
import '../models/todo.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String _query = '';
  List<String> _recentSearches = [];
  bool _showFilters = false;

  // Filters
  Set<int> _selectedPriorities = {};
  Set<String> _selectedCategories = {};
  bool _includeCompleted = true;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList('recent_searches') ?? [];
    setState(() {
      _recentSearches = searches;
    });
  }

  Future<void> _saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.take(10).toList();
    }
    await prefs.setStringList('recent_searches', _recentSearches);
  }

  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    setState(() {
      _recentSearches = [];
    });
  }

  void _search(String query) {
    setState(() {
      _query = query;
    });
    if (query.trim().isNotEmpty) {
      _saveRecentSearch(query);
    }
  }

  List<Todo> _getSearchResults(HybridTaskProvider taskProvider) {
    if (_query.isEmpty &&
        _selectedPriorities.isEmpty &&
        _selectedCategories.isEmpty &&
        _startDate == null &&
        _endDate == null) {
      return [];
    }

    var results = taskProvider.allTodos.toList();

    // Apply text search
    if (_query.isNotEmpty) {
      final lowerQuery = _query.toLowerCase();
      results = results.where((task) {
        return task.title.toLowerCase().contains(lowerQuery) ||
            (task.description?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    }

    // Apply completion filter
    if (!_includeCompleted) {
      results = results.where((task) => !task.isCompleted).toList();
    }

    // Apply priority filter
    if (_selectedPriorities.isNotEmpty) {
      results = results
          .where((task) => _selectedPriorities.contains(task.priority))
          .toList();
    }

    // Apply category filter
    if (_selectedCategories.isNotEmpty) {
      results = results
          .where((task) =>
              task.categoryId != null &&
              _selectedCategories.contains(task.categoryId))
          .toList();
    }

    // Apply date filter
    if (_startDate != null) {
      results = results
          .where((task) =>
              task.dueDate != null && task.dueDate!.isAfter(_startDate!))
          .toList();
    }
    if (_endDate != null) {
      results = results
          .where((task) =>
              task.dueDate != null &&
              task.dueDate!.isBefore(_endDate!.add(const Duration(days: 1))))
          .toList();
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: _buildSearchBar(theme),
        titleSpacing: 0,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            icon: Stack(
              children: [
                const Icon(Icons.tune_rounded),
                if (_hasActiveFilters())
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Consumer2<HybridTaskProvider, HybridCategoryProvider>(
        builder: (context, taskProvider, categoryProvider, child) {
          final results = _getSearchResults(taskProvider);

          return Column(
            children: [
              // Filters Panel
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _showFilters ? null : 0,
                child: _showFilters
                    ? _buildFiltersPanel(theme, categoryProvider)
                    : null,
              ),

              // Content
              Expanded(
                child: _query.isEmpty && !_hasActiveFilters()
                    ? _buildRecentSearches(theme)
                    : results.isEmpty
                        ? _buildNoResults(theme)
                        : _buildSearchResults(
                            theme, results, taskProvider, categoryProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        onChanged: _search,
        onSubmitted: _search,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Search tasks...',
          hintStyle: TextStyle(
            color: theme.textTheme.bodySmall?.color,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: theme.textTheme.bodySmall?.color,
          ),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _query = '';
                    });
                  },
                  icon: const Icon(Icons.close_rounded, size: 20),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFiltersPanel(
      ThemeData theme, HybridCategoryProvider categoryProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Include Completed
          Row(
            children: [
              const Text('Include Completed'),
              const Spacer(),
              Switch(
                value: _includeCompleted,
                onChanged: (value) {
                  setState(() {
                    _includeCompleted = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Priority
          const Text(
            'Priority',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildPriorityChip(1, 'Urgent', const Color(0xFFEF4444)),
              _buildPriorityChip(2, 'High', const Color(0xFFF59E0B)),
              _buildPriorityChip(3, 'Medium', const Color(0xFFEAB308)),
              _buildPriorityChip(4, 'Low', const Color(0xFF22C55E)),
            ],
          ),
          const SizedBox(height: 12),

          // Categories
          if (categoryProvider.allCategories.isNotEmpty) ...[
            const Text(
              'Categories',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categoryProvider.allCategories.map((category) {
                final isSelected = _selectedCategories.contains(category.id);
                final color = Color(
                  int.parse(category.color.replaceAll('#', '0xFF')),
                );
                return FilterChip(
                  label: Text(category.name),
                  selected: isSelected,
                  selectedColor: color.withOpacity(0.2),
                  checkmarkColor: color,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategories.add(category.id);
                      } else {
                        _selectedCategories.remove(category.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Date Range
          const Text(
            'Due Date Range',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _startDate = date);
                    }
                  },
                  child: Text(
                    _startDate != null
                        ? DateFormat.MMMd().format(_startDate!)
                        : 'From',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _endDate = date);
                    }
                  },
                  child: Text(
                    _endDate != null
                        ? DateFormat.MMMd().format(_endDate!)
                        : 'To',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(int priority, String label, Color color) {
    final isSelected = _selectedPriorities.contains(priority);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedPriorities.add(priority);
          } else {
            _selectedPriorities.remove(priority);
          }
        });
      },
    );
  }

  Widget _buildRecentSearches(ThemeData theme) {
    if (_recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 80,
              color: theme.primaryColor.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Search for tasks',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search by title or description',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Searches',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            TextButton(
              onPressed: _clearRecentSearches,
              child: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...ListTile.divideTiles(
          context: context,
          tiles: _recentSearches.map((search) => ListTile(
                onTap: () {
                  _searchController.text = search;
                  _search(search);
                },
                leading: const Icon(Icons.history_rounded, size: 20),
                title: Text(search),
                trailing: IconButton(
                  onPressed: () {
                    setState(() {
                      _recentSearches.remove(search);
                    });
                    SharedPreferences.getInstance().then((prefs) {
                      prefs.setStringList('recent_searches', _recentSearches);
                    });
                  },
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
                contentPadding: EdgeInsets.zero,
              )),
        ),
      ],
    );
  }

  Widget _buildNoResults(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 80,
            color: theme.primaryColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try different keywords or filters',
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(
    ThemeData theme,
    List<Todo> results,
    HybridTaskProvider taskProvider,
    HybridCategoryProvider categoryProvider,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${results.length} result${results.length == 1 ? '' : 's'}',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        final task = results[index - 1];
        final category = task.categoryId != null
            ? categoryProvider.allCategories.cast<dynamic>().firstWhere(
                  (c) => c.id == task.categoryId,
                  orElse: () => null,
                )
            : null;

        return _buildSearchResultCard(
          context,
          task,
          category,
          taskProvider,
        );
      },
    );
  }

  Widget _buildSearchResultCard(
    BuildContext context,
    Todo task,
    dynamic category,
    HybridTaskProvider taskProvider,
  ) {
    final theme = Theme.of(context);
    final priorityColor = _getPriorityColor(task.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.5),
        ),
      ),
      child: ListTile(
        onTap: () {
          // Navigate to task detail
          Navigator.pop(context, task);
        },
        leading: GestureDetector(
          onTap: () {
            taskProvider.toggleTodoCompletion(task);
          },
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: task.isCompleted
                  ? priorityColor
                  : priorityColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: priorityColor,
                width: 2,
              ),
            ),
            child: task.isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted
                ? theme.textTheme.bodyMedium?.color?.withOpacity(0.5)
                : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                _highlightMatch(task.description!, _query),
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodySmall?.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                if (category != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Color(
                        int.parse(category.color.replaceAll('#', '0xFF')) &
                            0xFFFFFFFF,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(
                          int.parse(category.color.replaceAll('#', '0xFF')),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (task.dueDate != null) ...[
                  Icon(
                    Icons.schedule_rounded,
                    size: 12,
                    color: _isOverdue(task)
                        ? Colors.red
                        : theme.textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat.MMMd().format(task.dueDate!),
                    style: TextStyle(
                      fontSize: 10,
                      color: _isOverdue(task)
                          ? Colors.red
                          : theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: priorityColor,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  String _highlightMatch(String text, String query) {
    if (query.isEmpty) return text;
    // For now, just return the text. In a real app, you might use
    // RichText to highlight matching portions.
    return text;
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return const Color(0xFFEF4444);
      case 2:
        return const Color(0xFFF59E0B);
      case 3:
        return const Color(0xFFEAB308);
      case 4:
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  bool _isOverdue(Todo task) {
    if (task.dueDate == null || task.isCompleted) return false;
    return task.dueDate!.isBefore(DateTime.now());
  }

  bool _hasActiveFilters() {
    return _selectedPriorities.isNotEmpty ||
        _selectedCategories.isNotEmpty ||
        _startDate != null ||
        _endDate != null ||
        !_includeCompleted;
  }

  void _clearFilters() {
    setState(() {
      _selectedPriorities.clear();
      _selectedCategories.clear();
      _startDate = null;
      _endDate = null;
      _includeCompleted = true;
    });
  }
}
