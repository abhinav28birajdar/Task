import 'package:flutter/material.dart';
import 'dart:math' as math;

class QuickActionFAB extends StatefulWidget {
  final VoidCallback? onCreateTask;
  final VoidCallback? onVoiceInput;
  final VoidCallback? onPhotoCapture;
  final VoidCallback? onAiSuggest;

  const QuickActionFAB({
    super.key,
    this.onCreateTask,
    this.onVoiceInput,
    this.onPhotoCapture,
    this.onAiSuggest,
  });

  @override
  State<QuickActionFAB> createState() => _QuickActionFABState();
}

class _QuickActionFABState extends State<QuickActionFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 0.125).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _handleActionTap(VoidCallback? action) {
    _toggleExpanded();
    action?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Action Buttons
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // AI Suggest Button
                _buildActionButton(
                  icon: Icons.auto_awesome_rounded,
                  label: 'AI Suggest',
                  color: const Color(0xFFF59E0B),
                  onTap: () => _handleActionTap(widget.onAiSuggest),
                  offset: 3,
                ),
                const SizedBox(height: 12),
                // Photo Capture Button
                _buildActionButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Photo Task',
                  color: const Color(0xFF06B6D4),
                  onTap: () => _handleActionTap(widget.onPhotoCapture),
                  offset: 2,
                ),
                const SizedBox(height: 12),
                // Voice Input Button
                _buildActionButton(
                  icon: Icons.mic_rounded,
                  label: 'Voice Input',
                  color: const Color(0xFF10B981),
                  onTap: () => _handleActionTap(widget.onVoiceInput),
                  offset: 1,
                ),
                const SizedBox(height: 12),
                // Create Task Button
                _buildActionButton(
                  icon: Icons.add_task_rounded,
                  label: 'New Task',
                  color: Theme.of(context).primaryColor,
                  onTap: () => _handleActionTap(widget.onCreateTask),
                  offset: 0,
                ),
                const SizedBox(height: 12),
              ],
            );
          },
        ),
        // Main FAB
        AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationAnimation.value * math.pi * 2,
              child: FloatingActionButton(
                onPressed: _toggleExpanded,
                heroTag: 'quick_action_fab',
                backgroundColor: Theme.of(context).primaryColor,
                child: Icon(
                  _isExpanded ? Icons.close_rounded : Icons.add_rounded,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required int offset,
  }) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _scaleAnimation,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Mini FAB
            SizedBox(
              width: 48,
              height: 48,
              child: FloatingActionButton(
                onPressed: onTap,
                heroTag: 'action_$offset',
                backgroundColor: color,
                mini: true,
                elevation: 4,
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExpandableFAB extends StatefulWidget {
  final Widget child;
  final List<ExpandableFABItem> items;

  const ExpandableFAB({
    super.key,
    required this.child,
    required this.items,
  });

  @override
  State<ExpandableFAB> createState() => _ExpandableFABState();
}

class _ExpandableFABState extends State<ExpandableFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Expanded items
        ...widget.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return _buildItem(item, index);
        }),
        const SizedBox(height: 8),
        // Main FAB
        GestureDetector(
          onTap: _toggle,
          child: widget.child,
        ),
      ],
    );
  }

  Widget _buildItem(ExpandableFABItem item, int index) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _controller,
        curve: Interval(
          0.0,
          1.0 - (index / widget.items.length) / 2,
          curve: Curves.easeOutBack,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.label != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  item.label!,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            if (item.label != null) const SizedBox(width: 8),
            SizedBox(
              width: 40,
              height: 40,
              child: FloatingActionButton(
                onPressed: () {
                  _toggle();
                  item.onPressed?.call();
                },
                heroTag: 'expandable_item_$index',
                backgroundColor: item.color ?? Theme.of(context).primaryColor,
                mini: true,
                child: Icon(item.icon, size: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExpandableFABItem {
  final IconData icon;
  final String? label;
  final Color? color;
  final VoidCallback? onPressed;

  const ExpandableFABItem({
    required this.icon,
    this.label,
    this.color,
    this.onPressed,
  });
}
