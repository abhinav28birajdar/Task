import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

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
