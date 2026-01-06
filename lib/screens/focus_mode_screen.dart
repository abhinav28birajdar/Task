import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;

import '../providers/hybrid_task_provider.dart';
import '../models/todo.dart';
import '../services/notification_service.dart';

class FocusModeScreen extends StatefulWidget {
  final String? taskId;
  final String? taskTitle;

  const FocusModeScreen({
    super.key,
    this.taskId,
    this.taskTitle,
  });

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen>
    with TickerProviderStateMixin {
  // Timer settings
  int _workDuration = 25; // minutes
  int _shortBreakDuration = 5;
  int _longBreakDuration = 15;
  int _sessionsBeforeLongBreak = 4;

  // Timer state
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isRunning = false;
  bool _isPaused = false;
  int _completedSessions = 0;
  FocusSessionType _currentSessionType = FocusSessionType.work;

  // Selected task
  Todo? _selectedTask;

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _workDuration * 60;
    _initAnimations();
    _loadSelectedTask();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _loadSelectedTask() {
    if (widget.taskId != null) {
      final taskProvider =
          Provider.of<HybridTaskProvider>(context, listen: false);
      final tasks = taskProvider.allTodos;
      try {
        _selectedTask = tasks.firstWhere((t) => t.id == widget.taskId);
      } catch (e) {
        // Task not found
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _onSessionComplete();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isPaused = true;
      _isRunning = false;
    });
  }

  void _resumeTimer() {
    _startTimer();
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _remainingSeconds = _getDurationForSessionType(_currentSessionType) * 60;
    });
  }

  void _onSessionComplete() {
    _timer?.cancel();

    // Play notification sound
    NotificationService.instance.showInstantNotification(
      title: _currentSessionType == FocusSessionType.work
          ? 'Focus Session Complete!'
          : 'Break is over!',
      body: _currentSessionType == FocusSessionType.work
          ? 'Great job! Take a break.'
          : 'Ready to focus again?',
    );

    if (_currentSessionType == FocusSessionType.work) {
      setState(() {
        _completedSessions++;
        _isRunning = false;

        // Determine next break type
        if (_completedSessions % _sessionsBeforeLongBreak == 0) {
          _currentSessionType = FocusSessionType.longBreak;
          _remainingSeconds = _longBreakDuration * 60;
        } else {
          _currentSessionType = FocusSessionType.shortBreak;
          _remainingSeconds = _shortBreakDuration * 60;
        }
      });
    } else {
      setState(() {
        _currentSessionType = FocusSessionType.work;
        _remainingSeconds = _workDuration * 60;
        _isRunning = false;
      });
    }

    _showSessionCompleteDialog();
  }

  void _showSessionCompleteDialog() {
    final isWorkComplete = _currentSessionType != FocusSessionType.work;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isWorkComplete ? Icons.celebration_rounded : Icons.coffee_rounded,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 12),
            Text(isWorkComplete ? 'Well Done!' : 'Break Over'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isWorkComplete
                  ? 'You completed a focus session. Time for a break!'
                  : 'Ready to start another focus session?',
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatChip(
                  icon: Icons.timer_rounded,
                  value: '$_completedSessions',
                  label: 'Sessions',
                ),
                const SizedBox(width: 16),
                _buildStatChip(
                  icon: Icons.access_time_rounded,
                  value: '${_completedSessions * _workDuration}',
                  label: 'Minutes',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startTimer();
            },
            child: Text(isWorkComplete ? 'Start Break' : 'Start Focus'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  int _getDurationForSessionType(FocusSessionType type) {
    switch (type) {
      case FocusSessionType.work:
        return _workDuration;
      case FocusSessionType.shortBreak:
        return _shortBreakDuration;
      case FocusSessionType.longBreak:
        return _longBreakDuration;
    }
  }

  void _selectTask() async {
    final taskProvider =
        Provider.of<HybridTaskProvider>(context, listen: false);
    final pendingTasks =
        taskProvider.allTodos.where((t) => !t.isCompleted).toList();

    final selectedTask = await showModalBottomSheet<Todo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TaskSelectionSheet(tasks: pendingTasks),
    );

    if (selectedTask != null) {
      setState(() {
        _selectedTask = selectedTask;
      });
    }
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PomodoroSettingsSheet(
        workDuration: _workDuration,
        shortBreakDuration: _shortBreakDuration,
        longBreakDuration: _longBreakDuration,
        sessionsBeforeLongBreak: _sessionsBeforeLongBreak,
        onSave: (work, shortBreak, longBreak, sessions) {
          setState(() {
            _workDuration = work;
            _shortBreakDuration = shortBreak;
            _longBreakDuration = longBreak;
            _sessionsBeforeLongBreak = sessions;
            if (!_isRunning && !_isPaused) {
              _remainingSeconds =
                  _getDurationForSessionType(_currentSessionType) * 60;
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = 1 -
        (_remainingSeconds /
            (_getDurationForSessionType(_currentSessionType) * 60));

    final isBreak = _currentSessionType != FocusSessionType.work;
    final sessionColor = isBreak ? const Color(0xFF10B981) : theme.primaryColor;

    return Scaffold(
      backgroundColor: isBreak
          ? const Color(0xFF10B981).withOpacity(0.05)
          : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isBreak ? 'Break Time' : 'Focus Mode',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Timer Display
            ScaleTransition(
              scale: _isRunning
                  ? _pulseAnimation
                  : const AlwaysStoppedAnimation(1.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Progress Ring
                  SizedBox(
                    width: 280,
                    height: 280,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 12,
                      backgroundColor: sessionColor.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation(sessionColor),
                    ),
                  ),
                  // Timer Text
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(_remainingSeconds),
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: sessionColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: sessionColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getSessionLabel(),
                          style: TextStyle(
                            color: sessionColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Session Progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_sessionsBeforeLongBreak, (index) {
                  final isCompleted = index < _completedSessions;
                  final isCurrent = index == _completedSessions &&
                      _currentSessionType == FocusSessionType.work;
                  return Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? sessionColor
                          : isCurrent
                              ? sessionColor.withOpacity(0.5)
                              : sessionColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: isCurrent
                          ? Border.all(color: sessionColor, width: 2)
                          : null,
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_completedSessions of $_sessionsBeforeLongBreak sessions',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
            ),
            const Spacer(),

            // Selected Task
            if (_selectedTask != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: sessionColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.task_alt_rounded,
                        color: sessionColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Working on',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedTask!.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedTask = null;
                        });
                      },
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
              )
            else
              TextButton.icon(
                onPressed: _selectTask,
                icon: const Icon(Icons.add_task_rounded),
                label: const Text('Select a task to focus on'),
              ),
            const SizedBox(height: 24),

            // Control Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Reset Button
                  _buildControlButton(
                    icon: Icons.refresh_rounded,
                    onPressed: _resetTimer,
                    isSecondary: true,
                  ),
                  const SizedBox(width: 24),
                  // Play/Pause Button
                  _buildMainControlButton(
                    icon: _isRunning
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    onPressed: _isRunning
                        ? _pauseTimer
                        : _isPaused
                            ? _resumeTimer
                            : _startTimer,
                    color: sessionColor,
                  ),
                  const SizedBox(width: 24),
                  // Skip Button
                  _buildControlButton(
                    icon: Icons.skip_next_rounded,
                    onPressed: () {
                      _timer?.cancel();
                      _onSessionComplete();
                    },
                    isSecondary: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isSecondary = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSecondary
            ? Theme.of(context).cardColor
            : Theme.of(context).primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        iconSize: 28,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildMainControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  String _getSessionLabel() {
    switch (_currentSessionType) {
      case FocusSessionType.work:
        return 'Focus Session';
      case FocusSessionType.shortBreak:
        return 'Short Break';
      case FocusSessionType.longBreak:
        return 'Long Break';
    }
  }
}

enum FocusSessionType { work, shortBreak, longBreak }

class _TaskSelectionSheet extends StatelessWidget {
  final List<Todo> tasks;

  const _TaskSelectionSheet({required this.tasks});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text(
                  'Select a Task',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: tasks.isEmpty
                ? const Center(
                    child: Text('No pending tasks'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return ListTile(
                        onTap: () => Navigator.pop(context, task),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(task.priority)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.task_alt_rounded,
                            color: _getPriorityColor(task.priority),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          task.priorityText,
                          style: TextStyle(
                            color: _getPriorityColor(task.priority),
                            fontSize: 12,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return const Color(0xFFEF4444);
      case 2:
        return const Color(0xFFF59E0B);
      case 3:
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFF3B82F6);
    }
  }
}

class _PomodoroSettingsSheet extends StatefulWidget {
  final int workDuration;
  final int shortBreakDuration;
  final int longBreakDuration;
  final int sessionsBeforeLongBreak;
  final Function(int, int, int, int) onSave;

  const _PomodoroSettingsSheet({
    required this.workDuration,
    required this.shortBreakDuration,
    required this.longBreakDuration,
    required this.sessionsBeforeLongBreak,
    required this.onSave,
  });

  @override
  State<_PomodoroSettingsSheet> createState() => _PomodoroSettingsSheetState();
}

class _PomodoroSettingsSheetState extends State<_PomodoroSettingsSheet> {
  late int _workDuration;
  late int _shortBreakDuration;
  late int _longBreakDuration;
  late int _sessionsBeforeLongBreak;

  @override
  void initState() {
    super.initState();
    _workDuration = widget.workDuration;
    _shortBreakDuration = widget.shortBreakDuration;
    _longBreakDuration = widget.longBreakDuration;
    _sessionsBeforeLongBreak = widget.sessionsBeforeLongBreak;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Timer Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildDurationSetting(
            label: 'Focus Duration',
            value: _workDuration,
            min: 1,
            max: 60,
            onChanged: (value) => setState(() => _workDuration = value),
          ),
          const SizedBox(height: 16),
          _buildDurationSetting(
            label: 'Short Break',
            value: _shortBreakDuration,
            min: 1,
            max: 30,
            onChanged: (value) => setState(() => _shortBreakDuration = value),
          ),
          const SizedBox(height: 16),
          _buildDurationSetting(
            label: 'Long Break',
            value: _longBreakDuration,
            min: 1,
            max: 60,
            onChanged: (value) => setState(() => _longBreakDuration = value),
          ),
          const SizedBox(height: 16),
          _buildDurationSetting(
            label: 'Sessions before long break',
            value: _sessionsBeforeLongBreak,
            min: 2,
            max: 8,
            suffix: '',
            onChanged: (value) =>
                setState(() => _sessionsBeforeLongBreak = value),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onSave(
                  _workDuration,
                  _shortBreakDuration,
                  _longBreakDuration,
                  _sessionsBeforeLongBreak,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save Settings'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDurationSetting({
    required String label,
    required int value,
    required int min,
    required int max,
    String suffix = ' min',
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 15),
          ),
        ),
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline_rounded),
          color: Theme.of(context).primaryColor,
        ),
        Container(
          width: 60,
          alignment: Alignment.center,
          child: Text(
            '$value$suffix',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline_rounded),
          color: Theme.of(context).primaryColor,
        ),
      ],
    );
  }
}
