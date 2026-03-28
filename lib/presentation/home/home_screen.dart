import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/app_dialog.dart';
import 'widgets/greeting_header_widget.dart';
import 'widgets/summary_card_widget.dart';
import 'widgets/category_filter_widget.dart';
import 'widgets/task_card_widget.dart';
import 'sheets/add_task_sheet.dart';
import 'sheets/edit_task_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        context.read<UserProvider>().loadUser(uid);
      }
    });
  }

  void _showEditTask(task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditTaskSheet(task: task),
    );
  }

  void _showAddTask() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTaskSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final userProvider = context.watch<UserProvider>();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final streak = uid != null ? taskProvider.currentStreak(uid) : 0;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (uid != null) {
              taskProvider.startListening(uid);
              userProvider.loadUser(uid);
            }
          },
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(AppSizes.p16),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const GreetingHeaderWidget(),
                      GestureDetector(
                        onTap: () => context.go('/profile'),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          backgroundImage: userProvider.user?.photoURL != null
                              ? NetworkImage(userProvider.user!.photoURL!)
                              : null,
                          child: userProvider.user?.photoURL == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 140,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 3,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return SummaryCardWidget(
                          title: 'Ongoing',
                          count: taskProvider.pendingCount.toString(),
                          icon: Icons.pending_actions,
                          gradientColors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.7)
                          ],
                          onTap: () => taskProvider.setFilterStatus('pending'),
                        );
                      } else if (index == 1) {
                        return SummaryCardWidget(
                          title: 'Completed',
                          count: taskProvider.completedCount.toString(),
                          icon: Icons.check_circle_outline,
                          gradientColors: [Colors.green, Colors.green.shade700],
                          onTap: () =>
                              taskProvider.setFilterStatus('completed'),
                        );
                      } else {
                        return SummaryCardWidget(
                          title: 'Current Streak',
                          count: '$streak 🔥',
                          icon: Icons.local_fire_department,
                          gradientColors: [Colors.orange, Colors.deepOrange],
                          onTap: () {},
                        );
                      }
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              const SliverToBoxAdapter(child: CategoryFilterWidget()),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              if (taskProvider.isLoading)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const ShimmerTaskCard(),
                    childCount: 5,
                  ),
                )
              else if (taskProvider.filteredTasks.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_turned_in_outlined,
                            size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No tasks found',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final task = taskProvider.filteredTasks[index];
                      return GestureDetector(
                        onLongPress: () => _showEditTask(task),
                        child: TaskCardWidget(
                          task: task,
                          onTap: () => context.push('/task/${task.id}'),
                          onEdit: () => _showEditTask(task),
                          onDelete: () async {
                            final confirm = await AppDialog.confirm(
                              context,
                              'Delete Task',
                              'Are you sure you want to delete this task?',
                            );
                            if (confirm == true) {
                              taskProvider.deleteTask(task);
                            }
                          },
                        ),
                      );
                    },
                    childCount: taskProvider.filteredTasks.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          heroTag: 'home_add_task_fab',
          onPressed: _showAddTask,
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
