import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Weekly bar chart
class WeeklyChart extends StatelessWidget {
  final List<int> weekData;

  const WeeklyChart({Key? key, required this.weekData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final maxValue = weekData.reduce((a, b) => a > b ? a : b).toDouble();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          weekData.length,
          (index) => Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  weekData[index].toString(),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.7),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                    height: (weekData[index] / (maxValue + 1)) * 150,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  days[index],
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Priority distribution pie chart
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

/// Status distribution
class StatusDistribution extends StatelessWidget {
  final Map<String, int> status;

  const StatusDistribution({
    Key? key,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: status.entries.map((entry) {
        final total = status.values.fold<int>(0, (a, b) => a + b);
        final percentage =
            total > 0 ? (entry.value / total * 100).toStringAsFixed(1) : '0';
        final color =
            entry.key == 'completed' ? AppColors.success : AppColors.warning;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
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
