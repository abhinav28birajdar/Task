import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/task_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import 'widgets/weekly_chart.dart';
import 'widgets/priority_distribution.dart';
import 'widgets/status_distribution.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskProvider = context.read<TaskProvider>();
      final analyticsProvider = context.read<AnalyticsProvider>();
      analyticsProvider.updateTasks(taskProvider.tasks);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        elevation: 0,
      ),
      body: Consumer2<AnalyticsProvider, TaskProvider>(
        builder: (context, analyticsProvider, taskProvider, _) {
          // Update analytics with latest tasks for real-time updates
          analyticsProvider.updateTasks(taskProvider.tasks);

          if (taskProvider.tasks.isEmpty) {
            return _buildEmptyState();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary stats
                _buildSummaryStats(analyticsProvider),
                const SizedBox(height: AppSizes.p24),

                // Completion rate
                _buildCompletionRate(analyticsProvider),
                const SizedBox(height: AppSizes.p24),

                // Weekly chart
                _buildWeeklyChart(analyticsProvider),
                const SizedBox(height: AppSizes.p24),

                // Distributions
                Row(
                  children: [
                    Expanded(
                      child: _buildPriorityDistribution(analyticsProvider),
                    ),
                    const SizedBox(width: AppSizes.p12),
                    Expanded(
                      child: _buildStatusDistribution(analyticsProvider),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.p24),

                // Detailed stats
                _buildDetailedStats(analyticsProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: AppSizes.p16),
          Text(
            'No tasks yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSizes.p8),
          Text(
            'Create tasks to see your analytics',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(AnalyticsProvider analyticsProvider) {
    final byStatus = analyticsProvider.getTasksByStatus();

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Total Tasks',
            value: analyticsProvider.tasks.length.toString(),
            icon: Icons.assignment,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSizes.p12),
        Expanded(
          child: _buildStatCard(
            title: 'Completed',
            value: byStatus['completed'].toString(),
            icon: Icons.check_circle,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: AppSizes.p12),
        Expanded(
          child: _buildStatCard(
            title: 'Pending',
            value: byStatus['pending'].toString(),
            icon: Icons.schedule,
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: AppSizes.p8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                  ),
            ),
            const SizedBox(height: AppSizes.p4),
            Text(
              title,
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionRate(AnalyticsProvider analyticsProvider) {
    final rate = analyticsProvider.getCompletionRatePercentage();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Completion Rate',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSizes.p16),
            Center(
              child: CircularPercentIndicator(
                radius: 80,
                lineWidth: 8,
                percent: rate / 100,
                center: Text(
                  '$rate%',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.primary,
                      ),
                ),
                progressColor: AppColors.primary,
                backgroundColor: Colors.grey.shade200,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(AnalyticsProvider analyticsProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This Week',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSizes.p16),
            WeeklyChart(weekData: analyticsProvider.getThisWeek()),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityDistribution(AnalyticsProvider analyticsProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'By Priority',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSizes.p16),
            PriorityDistribution(
              priorities: analyticsProvider.getTasksByPriority(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDistribution(AnalyticsProvider analyticsProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'By Status',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSizes.p16),
            StatusDistribution(
              status: analyticsProvider.getTasksByStatus(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStats(AnalyticsProvider analyticsProvider) {
    final avgTime = analyticsProvider.getAverageCompletionTime();
    final mostProductive = analyticsProvider.getMostProductiveDay();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Insights',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSizes.p16),
            _buildStatRow(
              icon: Icons.schedule,
              title: 'Avg. Completion Time',
              value: '${avgTime.toStringAsFixed(1)} hours',
            ),
            const Divider(),
            _buildStatRow(
              icon: Icons.star,
              title: 'Most Productive Day',
              value: mostProductive,
            ),
            const Divider(),
            _buildStatRow(
              icon: Icons.trending_up,
              title: 'Weekly Rate',
              value:
                  '${analyticsProvider.getWeeklyCompletionRate().toStringAsFixed(1)}%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: AppSizes.p12),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
