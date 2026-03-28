import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class WeeklyChart extends StatelessWidget {
  final List<int> weekData;

  const WeeklyChart({Key? key, required this.weekData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final maxValue = weekData.isEmpty
        ? 1.0
        : weekData.reduce((a, b) => a > b ? a : b).toDouble();
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
                Flexible(
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
