import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class PriorityDotWidget extends StatelessWidget {
  final String priority;
  const PriorityDotWidget({Key? key, required this.priority}) : super(key: key);

  Color get _color {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppColors.priorityHigh;
      case 'medium':
        return AppColors.priorityMedium;
      case 'low':
        return AppColors.priorityLow;
      default:
        return AppColors.priorityLow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
      ),
    );
  }
}
