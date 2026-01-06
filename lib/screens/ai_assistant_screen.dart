import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/hybrid_task_provider.dart';
import '../providers/hybrid_category_provider.dart';
import '../models/todo.dart';
import '../services/ai_service.dart';
import 'add_edit_todo_screen.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
      content: "Hello! 👋 I'm your AI task assistant. I can help you:\n\n"
          "• Create tasks from natural language\n"
          "• Analyze your productivity\n"
          "• Suggest what to work on\n"
          "• Break down complex tasks\n"
          "• Plan your day\n\n"
          "How can I help you today?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        content: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });
    _inputController.clear();
    _scrollToBottom();

    // Process the message
    await Future.delayed(const Duration(milliseconds: 500));

    final response = await _processUserInput(text);

    setState(() {
      _messages.add(response);
      _isTyping = false;
    });
    _scrollToBottom();
  }

  Future<ChatMessage> _processUserInput(String input) async {
    final taskProvider =
        Provider.of<HybridTaskProvider>(context, listen: false);
    final categoryProvider =
        Provider.of<HybridCategoryProvider>(context, listen: false);

    final lowerInput = input.toLowerCase();

    // Check for task creation intent
    if (_isTaskCreationIntent(lowerInput)) {
      return _handleTaskCreation(input, taskProvider, categoryProvider);
    }

    // Check for showing tasks
    if (_isShowTasksIntent(lowerInput)) {
      return _handleShowTasks(input, taskProvider);
    }

    // Check for productivity analysis
    if (_isProductivityIntent(lowerInput)) {
      return _handleProductivityAnalysis(taskProvider);
    }

    // Check for what to work on
    if (_isWhatToDoIntent(lowerInput)) {
      return _handleWhatToDo(taskProvider);
    }

    // Check for planning
    if (_isPlanningIntent(lowerInput)) {
      return _handleDayPlanning(taskProvider);
    }

    // Default response
    return ChatMessage(
      content: "I understand you said: \"$input\"\n\n"
          "I can help you with:\n"
          "• Creating tasks (try: \"Remind me to call John tomorrow at 3pm\")\n"
          "• Showing tasks (try: \"Show my overdue tasks\")\n"
          "• Productivity analysis (try: \"Analyze my productivity\")\n"
          "• Planning (try: \"Plan my day\")\n\n"
          "What would you like to do?",
      isUser: false,
      timestamp: DateTime.now(),
    );
  }

  bool _isTaskCreationIntent(String input) {
    final keywords = [
      'remind',
      'add',
      'create',
      'new task',
      'schedule',
      'todo',
      'need to',
      'have to',
      'should',
      'must',
      'don\'t forget'
    ];
    return keywords.any((k) => input.contains(k));
  }

  bool _isShowTasksIntent(String input) {
    final keywords = [
      'show',
      'list',
      'what are',
      'display',
      'get',
      'view',
      'overdue',
      'pending',
      'completed',
      'today\'s tasks'
    ];
    return keywords.any((k) => input.contains(k));
  }

  bool _isProductivityIntent(String input) {
    final keywords = [
      'productivity',
      'analyze',
      'analysis',
      'stats',
      'statistics',
      'how am i doing',
      'performance',
      'progress'
    ];
    return keywords.any((k) => input.contains(k));
  }

  bool _isWhatToDoIntent(String input) {
    final keywords = [
      'what should',
      'what to do',
      'prioritize',
      'work on',
      'focus on',
      'next task',
      'suggest'
    ];
    return keywords.any((k) => input.contains(k));
  }

  bool _isPlanningIntent(String input) {
    final keywords = [
      'plan',
      'organize',
      'schedule my',
      'today',
      'tomorrow',
      'this week',
      'my day'
    ];
    return keywords.any((k) => input.contains(k));
  }

  ChatMessage _handleTaskCreation(
    String input,
    HybridTaskProvider taskProvider,
    HybridCategoryProvider categoryProvider,
  ) {
    // Parse task details from natural language
    final parsedTask = _parseTaskFromInput(input);

    return ChatMessage(
      content: "I'll create a task for you:\n\n"
          "📋 **${parsedTask['title']}**\n"
          "${parsedTask['dueDate'] != null ? '📅 Due: ${parsedTask['dueDate']}\n' : ''}"
          "${parsedTask['priority'] != null ? '🚩 Priority: ${parsedTask['priority']}\n' : ''}"
          "\nWould you like me to add this task?",
      isUser: false,
      timestamp: DateTime.now(),
      action: ChatAction(
        type: ChatActionType.createTask,
        data: parsedTask,
      ),
    );
  }

  Map<String, dynamic> _parseTaskFromInput(String input) {
    String title = input;
    DateTime? dueDate;
    String? priority;

    // Extract date patterns
    final tomorrow = RegExp(r'tomorrow', caseSensitive: false);
    final today = RegExp(r'today', caseSensitive: false);
    final nextWeek = RegExp(r'next week', caseSensitive: false);
    final timePattern =
        RegExp(r'at (\d{1,2})(:\d{2})?\s*(am|pm)?', caseSensitive: false);

    if (tomorrow.hasMatch(input)) {
      dueDate = DateTime.now().add(const Duration(days: 1));
      title = title.replaceAll(tomorrow, '').trim();
    } else if (today.hasMatch(input)) {
      dueDate = DateTime.now();
      title = title.replaceAll(today, '').trim();
    } else if (nextWeek.hasMatch(input)) {
      dueDate = DateTime.now().add(const Duration(days: 7));
      title = title.replaceAll(nextWeek, '').trim();
    }

    // Extract time
    final timeMatch = timePattern.firstMatch(input);
    if (timeMatch != null && dueDate != null) {
      int hour = int.parse(timeMatch.group(1)!);
      final isPM = timeMatch.group(3)?.toLowerCase() == 'pm';
      if (isPM && hour != 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;
      dueDate = DateTime(dueDate.year, dueDate.month, dueDate.day, hour);
      title = title.replaceAll(timePattern, '').trim();
    }

    // Extract priority
    if (input.toLowerCase().contains('urgent') ||
        input.toLowerCase().contains('important') ||
        input.toLowerCase().contains('high priority')) {
      priority = 'High';
    }

    // Clean up title
    title = title
        .replaceAll(
            RegExp(r'remind me to|add task|create task|add a|create a',
                caseSensitive: false),
            '')
        .replaceAll(RegExp(r'^\s*to\s+', caseSensitive: false), '')
        .trim();

    // Capitalize first letter
    if (title.isNotEmpty) {
      title = title[0].toUpperCase() + title.substring(1);
    }

    return {
      'title': title.isNotEmpty ? title : 'New Task',
      'dueDate':
          dueDate != null ? DateFormat('MMM d, yyyy').format(dueDate) : null,
      'dueDateRaw': dueDate,
      'priority': priority,
    };
  }

  ChatMessage _handleShowTasks(String input, HybridTaskProvider taskProvider) {
    final allTasks = taskProvider.allTodos;
    List<Todo> tasksToShow = [];
    String taskType = 'all';

    if (input.contains('overdue')) {
      tasksToShow = allTasks.where((t) => t.isOverdue).toList();
      taskType = 'overdue';
    } else if (input.contains('today')) {
      final now = DateTime.now();
      tasksToShow = allTasks.where((t) {
        if (t.dueDate == null) return false;
        return t.dueDate!.year == now.year &&
            t.dueDate!.month == now.month &&
            t.dueDate!.day == now.day;
      }).toList();
      taskType = 'today\'s';
    } else if (input.contains('completed')) {
      tasksToShow = allTasks.where((t) => t.isCompleted).toList();
      taskType = 'completed';
    } else if (input.contains('pending')) {
      tasksToShow = allTasks.where((t) => !t.isCompleted).toList();
      taskType = 'pending';
    } else {
      tasksToShow = allTasks.where((t) => !t.isCompleted).take(5).toList();
    }

    if (tasksToShow.isEmpty) {
      return ChatMessage(
        content: "You don't have any $taskType tasks right now. 🎉\n\n"
            "Would you like me to help you create a new task?",
        isUser: false,
        timestamp: DateTime.now(),
      );
    }

    final taskList = tasksToShow.take(5).map((t) {
      final dueInfo = t.dueDate != null
          ? ' (Due: ${DateFormat('MMM d').format(t.dueDate!)})'
          : '';
      final status = t.isCompleted ? '✅' : '⬜';
      return '$status ${t.title}$dueInfo';
    }).join('\n');

    return ChatMessage(
      content: "Here are your $taskType tasks:\n\n$taskList"
          "${tasksToShow.length > 5 ? '\n\n...and ${tasksToShow.length - 5} more' : ''}",
      isUser: false,
      timestamp: DateTime.now(),
    );
  }

  ChatMessage _handleProductivityAnalysis(HybridTaskProvider taskProvider) {
    final allTasks = taskProvider.allTodos;
    final completedTasks = allTasks.where((t) => t.isCompleted).length;
    final pendingTasks = allTasks.where((t) => !t.isCompleted).length;
    final overdueTasks = allTasks.where((t) => t.isOverdue).length;
    final completionRate = allTasks.isEmpty
        ? 0
        : ((completedTasks / allTasks.length) * 100).round();

    // Get today's completed tasks
    final now = DateTime.now();
    final todayCompleted = allTasks.where((t) {
      if (t.completionDate == null) return false;
      return t.completionDate!.year == now.year &&
          t.completionDate!.month == now.month &&
          t.completionDate!.day == now.day;
    }).length;

    String message = "📊 **Your Productivity Report**\n\n"
        "**Overall Stats:**\n"
        "• Total Tasks: ${allTasks.length}\n"
        "• Completed: $completedTasks\n"
        "• Pending: $pendingTasks\n"
        "• Completion Rate: $completionRate%\n\n"
        "**Today's Progress:**\n"
        "• Completed Today: $todayCompleted\n";

    if (overdueTasks > 0) {
      message += "\n⚠️ **Attention Needed:**\n"
          "You have $overdueTasks overdue task${overdueTasks > 1 ? 's' : ''}.\n";
    }

    // Add encouragement
    if (completionRate >= 80) {
      message += "\n🌟 Excellent work! You're crushing it!";
    } else if (completionRate >= 50) {
      message += "\n💪 Good progress! Keep it up!";
    } else {
      message += "\n🚀 Let's boost that productivity! Start with one task.";
    }

    return ChatMessage(
      content: message,
      isUser: false,
      timestamp: DateTime.now(),
    );
  }

  ChatMessage _handleWhatToDo(HybridTaskProvider taskProvider) {
    final pendingTasks =
        taskProvider.allTodos.where((t) => !t.isCompleted).toList();

    if (pendingTasks.isEmpty) {
      return ChatMessage(
        content: "🎉 Amazing! You've completed all your tasks!\n\n"
            "Would you like me to suggest some productive activities?",
        isUser: false,
        timestamp: DateTime.now(),
      );
    }

    // Prioritize: overdue > due today > high priority
    final overdue = pendingTasks.where((t) => t.isOverdue).toList();
    final dueToday = pendingTasks.where((t) => t.isDueToday).toList();
    final highPriority = pendingTasks.where((t) => t.priority == 1).toList();

    Todo? recommendedTask;
    String reason = '';

    if (overdue.isNotEmpty) {
      recommendedTask = overdue.first;
      reason = 'This task is overdue and needs immediate attention!';
    } else if (dueToday.isNotEmpty) {
      recommendedTask = dueToday.first;
      reason = 'This task is due today.';
    } else if (highPriority.isNotEmpty) {
      recommendedTask = highPriority.first;
      reason = 'This is your highest priority task.';
    } else {
      recommendedTask = pendingTasks.first;
      reason = 'Starting with any task builds momentum!';
    }

    return ChatMessage(
      content: "🎯 **I recommend working on:**\n\n"
          "📋 **${recommendedTask.title}**\n"
          "${recommendedTask.dueDate != null ? '📅 Due: ${DateFormat('MMM d').format(recommendedTask.dueDate!)}\n' : ''}"
          "🚩 Priority: ${recommendedTask.priorityText}\n\n"
          "💡 **Why:** $reason\n\n"
          "Would you like me to start a focus session for this task?",
      isUser: false,
      timestamp: DateTime.now(),
      action: ChatAction(
        type: ChatActionType.focusTask,
        data: {
          'taskId': recommendedTask.id,
          'taskTitle': recommendedTask.title
        },
      ),
    );
  }

  ChatMessage _handleDayPlanning(HybridTaskProvider taskProvider) {
    final now = DateTime.now();
    final pendingTasks =
        taskProvider.allTodos.where((t) => !t.isCompleted).toList();

    final overdue = pendingTasks.where((t) => t.isOverdue).toList();
    final dueToday = pendingTasks.where((t) => t.isDueToday).toList();
    final upcoming = pendingTasks
        .where((t) => t.dueDate != null && t.dueDate!.isAfter(now))
        .take(3)
        .toList();

    String plan =
        "📅 **Your Day Plan for ${DateFormat('EEEE, MMM d').format(now)}**\n\n";

    if (overdue.isNotEmpty) {
      plan += "🔴 **Overdue - Do First:**\n";
      for (var task in overdue.take(3)) {
        plan += "• ${task.title}\n";
      }
      plan += "\n";
    }

    if (dueToday.isNotEmpty) {
      plan += "🟡 **Due Today:**\n";
      for (var task in dueToday.take(3)) {
        plan += "• ${task.title}\n";
      }
      plan += "\n";
    }

    if (upcoming.isNotEmpty) {
      plan += "🟢 **Coming Up:**\n";
      for (var task in upcoming) {
        plan += "• ${task.title}";
        if (task.dueDate != null) {
          plan += " (${DateFormat('MMM d').format(task.dueDate!)})";
        }
        plan += "\n";
      }
      plan += "\n";
    }

    if (pendingTasks.isEmpty) {
      plan = "🎉 **Great news!** You have no pending tasks.\n\n"
          "Enjoy your day or create new tasks to stay productive!";
    } else {
      plan +=
          "💡 **Tip:** Start with the overdue tasks, then move to today's tasks.\n"
          "Consider using Focus Mode for deep work sessions!";
    }

    return ChatMessage(
      content: plan,
      isUser: false,
      timestamp: DateTime.now(),
    );
  }

  void _handleQuickAction(String action) {
    switch (action) {
      case 'what_now':
        _sendMessage('What should I work on now?');
        break;
      case 'overdue':
        _sendMessage('Show my overdue tasks');
        break;
      case 'productivity':
        _sendMessage('Analyze my productivity');
        break;
      case 'plan':
        _sendMessage('Plan my day');
        break;
    }
  }

  void _handleChatAction(ChatAction action) {
    switch (action.type) {
      case ChatActionType.createTask:
        _createTaskFromAction(action.data);
        break;
      case ChatActionType.focusTask:
        _startFocusFromAction(action.data);
        break;
      default:
        break;
    }
  }

  void _createTaskFromAction(Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditTodoScreen(
          initialTitle: data['title'],
          initialDueDate: data['dueDateRaw'],
        ),
      ),
    );
  }

  void _startFocusFromAction(Map<String, dynamic> data) {
    // Navigate to focus mode with task
    Navigator.pushNamed(context, '/focus', arguments: data);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: theme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'AI Assistant',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _messages.clear();
                _addWelcomeMessage();
              });
            },
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'New Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickActionChip(
                    icon: Icons.lightbulb_outline_rounded,
                    label: 'What to do?',
                    onTap: () => _handleQuickAction('what_now'),
                  ),
                  _buildQuickActionChip(
                    icon: Icons.warning_amber_rounded,
                    label: 'Overdue',
                    onTap: () => _handleQuickAction('overdue'),
                  ),
                  _buildQuickActionChip(
                    icon: Icons.analytics_outlined,
                    label: 'Productivity',
                    onTap: () => _handleQuickAction('productivity'),
                  ),
                  _buildQuickActionChip(
                    icon: Icons.calendar_today_rounded,
                    label: 'Plan Day',
                    onTap: () => _handleQuickAction('plan'),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          // Input Field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.cardColor,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: _sendMessage,
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => _sendMessage(_inputController.text),
                      icon: const Icon(Icons.send_rounded),
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser ? theme.primaryColor : theme.cardColor,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomLeft: isUser ? null : const Radius.circular(4),
                      bottomRight: isUser ? const Radius.circular(4) : null,
                    ),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isUser
                          ? Colors.white
                          : theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                if (message.action != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () => _handleChatAction(message.action!),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          message.action!.type == ChatActionType.createTask
                              ? 'Create Task'
                              : 'Start Focus',
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.primaryColor,
              child: const Icon(
                Icons.person,
                size: 18,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 18,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomLeft: const Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 100)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final ChatAction? action;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.action,
  });
}

enum ChatActionType {
  createTask,
  focusTask,
  showTasks,
  navigate,
}

class ChatAction {
  final ChatActionType type;
  final Map<String, dynamic> data;

  ChatAction({
    required this.type,
    required this.data,
  });
}
