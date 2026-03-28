import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PriorityDistribution extends StatelessWidget {
  final Map<String, int> priorities;

  const PriorityDistribution({
    Key? key,
    required this.priorities,
  }) : super(key: key);

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      case 'low':
        return AppColors.success;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: priorities.entries.map((entry) {
        final total = priorities.values.fold<int>(0, (a, b) => a + b);
        final percentage =
            total > 0 ? (entry.value / total * 100).toStringAsFixed(1) : '0';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getPriorityColor(entry.key),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.key.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              Text(
                '$percentage%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
