import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:classlly/data/models/task_model.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/features/library/providers/library_provider.dart';
import 'package:classlly/features/library/screens/add_task_screen.dart';

import 'package:classlly/features/library/widgets/empty_state.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Task>(NotesRepository.taskBoxName).listenable(),
      builder: (context, Box<Task> box, _) {
        final allTasks = box.values.toList();

        // Task filtering for Kanban
        final highPriorityTasks = allTasks
            .where((t) => !t.isCompleted && t.priority == 2)
            .toList();
        final todoTasks = allTasks
            .where((t) => !t.isCompleted && t.priority != 2)
            .toList();
        final doneTasks = allTasks.where((t) => t.isCompleted).toList();

        final tasksForAgenda = _getTasksForDay(allTasks, DateTime.now());
        final isLargeScreen = MediaQuery.of(context).size.width > 1200;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  _buildToolbar(context, allTasks.length),
                  Expanded(
                    // Kanban Board with To Do, High Priority, and Done columns
                    child: allTasks.isEmpty
                        ? EmptyState(
                            icon: Icons.task_outlined,
                            title: 'No tasks yet',
                            subtitle: 'Create a task to stay organized.',
                            actionLabel: 'Add Task',
                            onAction: () => showDialog(
                              context: context,
                              builder: (context) => const AddTaskScreen(),
                            ),
                          )
                        : _buildKanbanBoard(
                            todoTasks,
                            highPriorityTasks,
                            doneTasks,
                          ),
                  ),
                ],
              ),
            ),
            if (isLargeScreen)
              Container(
                width: 320,
                decoration: const BoxDecoration(
                  border: Border(left: BorderSide(color: Color(0xFF2A2A2A))),
                  color: Color(0xFF121212),
                ),
                child: _buildRightSidebar(context, tasksForAgenda),
              ),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(BuildContext context, int totalTasks) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Task Dashboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'You have $totalTasks tasks in total.',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
          // Removed Board/List toggle and Filter dropdown
        ],
      ),
    );
  }

  Widget _buildKanbanBoard(
    List<Task> todo,
    List<Task> highPriority,
    List<Task> done,
  ) {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        _buildKanbanColumn('To Do', todo, Colors.grey),
        const SizedBox(width: 24),
        _buildKanbanColumn(
          'High Priority',
          highPriority,
          const Color(0xFFEF4444),
        ),
        const SizedBox(width: 24),
        _buildKanbanColumn('Done', done, const Color(0xFF10B981)),
      ],
    );
  }

  Widget _buildKanbanColumn(String title, List<Task> tasks, Color accentColor) {
    return SizedBox(
      width: 300,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return _buildTaskCard(tasks[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (task.category != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(
                      task.priority,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    task.category!.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getPriorityColor(task.priority),
                    ),
                  ),
                ),
              if (task.dueDate != null)
                Text(
                  DateFormat('MMM d').format(task.dueDate!),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            task.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          if (task.description?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              task.description!,
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.flag,
                size: 14,
                color: _getPriorityColor(task.priority),
              ),
              const SizedBox(width: 4),
              Text(
                task.priority == 2
                    ? 'High'
                    : (task.priority == 1 ? 'Medium' : 'Low'),
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  final provider =
                      Provider.of<LibraryProvider>(context, listen: false);
                  task.isCompleted = !task.isCompleted;
                  task.progress = task.isCompleted ? 1.0 : 0.0;
                  provider.saveTask(task);
                },
                borderRadius: BorderRadius.circular(12),
                child: Icon(
                  task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                  color: task.isCompleted
                      ? const Color(0xFF10B981)
                      : Colors.grey[600],
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRightSidebar(BuildContext context, List<Task> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Agenda',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, MMM d').format(DateTime.now()),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'add') {
                    showDialog(
                      context: context,
                      builder: (context) => const AddTaskScreen(),
                    );
                  } else if (value == 'calendar') {
                    Provider.of<LibraryProvider>(context, listen: false)
                        .setView(LibraryView.calendar);
                  } else if (value == 'clear') {
                    final provider =
                        Provider.of<LibraryProvider>(context, listen: false);
                    final box = Hive.box<Task>(NotesRepository.taskBoxName);
                    final today = DateTime.now();
                    final completedToday =
                        box.values
                            .where(
                              (t) =>
                                  !t.isDeleted &&
                                  t.isCompleted &&
                                  t.dueDate != null &&
                                  t.dueDate!.year == today.year &&
                                  t.dueDate!.month == today.month &&
                                  t.dueDate!.day == today.day,
                            )
                            .toList();
                    for (var task in completedToday) {
                      provider.deleteTask(task.id);
                    }
                  }
                },
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'add',
                        child: Row(
                          children: [
                            Icon(Icons.add, size: 18),
                            SizedBox(width: 8),
                            Text('Add Task'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'calendar',
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 18),
                            SizedBox(width: 8),
                            Text('View Calendar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'clear',
                        child: Row(
                          children: [
                            Icon(Icons.delete_sweep, size: 18),
                            SizedBox(width: 8),
                            Text('Clear Completed'),
                          ],
                        ),
                      ),
                    ],
                icon: const Icon(Icons.more_horiz, color: Colors.grey),
              ),
            ],
          ),
        ),
        Expanded(
          child: tasks.isEmpty
              ? EmptyState(
                  icon: Icons.event_available_outlined,
                  title: 'Free day!',
                  subtitle: 'You have no tasks scheduled for today.',
                  actionLabel: 'Add Task',
                  onAction: () => showDialog(
                    context: context,
                    builder: (context) => const AddTaskScreen(),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return _buildTimelineItem(context, task, index == 0);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(BuildContext context, Task task, bool isFirst) {
    final color = _getPriorityColor(task.priority);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  border: Border.all(color: color, width: 2),
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Container(width: 2, color: const Color(0xFF2A2A2A)),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.dueDate != null
                        ? DateFormat('hh:mm a').format(task.dueDate!)
                        : 'All Day',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTaskCard(task),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  List<Task> _getTasksForDay(List<Task> tasks, DateTime day) {
    return tasks.where((t) {
      if (t.dueDate == null) return false;
      return t.dueDate!.year == day.year &&
          t.dueDate!.month == day.month &&
          t.dueDate!.day == day.day;
    }).toList();
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 2:
        return const Color(0xFFEF4444); // Red
      case 1:
        return const Color(0xFFF59E0B); // Amber
      case 0:
        return const Color(0xFF3B82F6); // Blue
      default:
        return const Color(0xFF8B5CF6); // Purple
    }
  }
}
