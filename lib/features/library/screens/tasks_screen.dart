import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:classlly/data/models/task_model.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/features/library/providers/library_provider.dart';
import 'package:classlly/features/library/providers/task_provider.dart';
import 'package:classlly/features/library/screens/add_task_screen.dart';
import 'package:classlly/features/library/widgets/empty_state.dart';
import 'package:classlly/l10n/app_localizations.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = Theme.of(context).cardColor;
    final dividerColor = Theme.of(context).dividerColor;
    final textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.grey : Colors.grey[700]!;

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
                  _buildToolbar(
                    context,
                    allTasks.length,
                    textColor,
                    subTextColor,
                  ),
                  Expanded(
                    // Kanban Board with To Do, High Priority, and Done columns
                    child: allTasks.isEmpty
                        ? EmptyState(
                            icon: Icons.task_outlined,
                            title: AppLocalizations.of(context)!.noTasksYet,
                            subtitle: 'Create a task to stay organized.',
                            actionLabel: AppLocalizations.of(context)!.addTask,
                            onAction: () => showDialog(
                              context: context,
                              builder: (context) => const AddTaskScreen(),
                            ),
                          )
                        : _buildKanbanBoard(
                            todoTasks,
                            highPriorityTasks,
                            doneTasks,
                            cardBg,
                            dividerColor,
                            textColor,
                            subTextColor,
                          ),
                  ),
                ],
              ),
            ),
            if (isLargeScreen)
              Container(
                width: 320,
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: dividerColor.withValues(alpha: 0.5),
                    ),
                  ),
                  color: scaffoldBg,
                ),
                child: _buildRightSidebar(
                  context,
                  tasksForAgenda,
                  textColor,
                  subTextColor,
                  cardBg,
                  dividerColor,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    int totalTasks,
    Color textColor,
    Color subTextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (MediaQuery.of(context).size.width <= 1000)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: IconButton(
                    icon: Icon(
                      Icons.menu,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.taskDashboard,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.totalTasks(totalTasks),
                    style: TextStyle(color: subTextColor, fontSize: 14),
                  ),
                ],
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
    Color cardBg,
    Color dividerColor,
    Color textColor,
    Color subTextColor,
  ) {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        _buildKanbanColumn(
          AppLocalizations.of(context)!.todo,
          todo,
          Colors.grey,
          cardBg,
          dividerColor,
          textColor,
          subTextColor,
        ),
        const SizedBox(width: 24),
        _buildKanbanColumn(
          AppLocalizations.of(context)!.highPriority,
          highPriority,
          const Color(0xFFEF4444),
          cardBg,
          dividerColor,
          textColor,
          subTextColor,
        ),
        const SizedBox(width: 24),
        _buildKanbanColumn(
          AppLocalizations.of(context)!.done,
          done,
          const Color(0xFF10B981),
          cardBg,
          dividerColor,
          textColor,
          subTextColor,
        ),
      ],
    );
  }

  Widget _buildKanbanColumn(
    String title,
    List<Task> tasks,
    Color accentColor,
    Color cardBg,
    Color dividerColor,
    Color textColor,
    Color subTextColor,
  ) {
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
                    color: cardBg,
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
                return _buildTaskCard(
                  tasks[index],
                  cardBg,
                  dividerColor,
                  textColor,
                  subTextColor,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(
    Task task,
    Color cardBg,
    Color dividerColor,
    Color textColor,
    Color subTextColor,
  ) {
    return GestureDetector(
      onTap: () => _showTaskDetailsDialog(context, task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: dividerColor.withValues(alpha: 0.5)),
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
                      color: subTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              task.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: textColor,
              ),
            ),
            if (task.description?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                task.description!,
                style: TextStyle(fontSize: 12, color: subTextColor),
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
                      ? AppLocalizations.of(context)!.high
                      : (task.priority == 1
                            ? AppLocalizations.of(context)!.medium
                            : AppLocalizations.of(context)!.low),
                  style: TextStyle(fontSize: 12, color: subTextColor),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    final provider = Provider.of<TaskProvider>(
                      context,
                      listen: false,
                    );
                    task.isCompleted = !task.isCompleted;
                    task.progress = task.isCompleted ? 1.0 : 0.0;
                    provider.saveTask(task);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Icon(
                    task.isCompleted
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    color: task.isCompleted
                        ? const Color(0xFF10B981)
                        : subTextColor,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTaskDetailsDialog(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : Colors.black87;
        final subTextColor = isDark ? Colors.grey : Colors.grey[700]!;

        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description?.isNotEmpty == true) ...[
                Text(
                  AppLocalizations.of(context)!.description,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: subTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(task.description!, style: TextStyle(color: textColor)),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: subTextColor),
                  const SizedBox(width: 8),
                  Text(
                    task.dueDate != null
                        ? DateFormat(
                            'EEEE, MMM d, y • hh:mm a',
                          ).format(task.dueDate!)
                        : AppLocalizations.of(context)!.noDueDate,
                    style: TextStyle(color: textColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.flag,
                    size: 16,
                    color: _getPriorityColor(task.priority),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${AppLocalizations.of(context)!.priority}: ${task.priority == 2 ? AppLocalizations.of(context)!.high : (task.priority == 1 ? AppLocalizations.of(context)!.medium : AppLocalizations.of(context)!.low)}',
                    style: TextStyle(color: textColor),
                  ),
                ],
              ),
              if (task.category != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.label, size: 16, color: subTextColor),
                    const SizedBox(width: 8),
                    Text(
                      '${AppLocalizations.of(context)!.category}: ${task.category}',
                      style: TextStyle(color: textColor),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                final provider = Provider.of<TaskProvider>(
                  context,
                  listen: false,
                );
                provider.deleteTask(task.id);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: Text(
                AppLocalizations.of(context)!.delete,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AddTaskScreen(taskToEdit: task),
                );
              },
              icon: const Icon(Icons.edit),
              label: Text(AppLocalizations.of(context)!.edit),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRightSidebar(
    BuildContext context,
    List<Task> tasks,
    Color textColor,
    Color subTextColor,
    Color cardBg,
    Color dividerColor,
  ) {
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
                  Text(
                    AppLocalizations.of(context)!.dailyAgenda,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, MMM d').format(DateTime.now()),
                    style: TextStyle(fontSize: 12, color: subTextColor),
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
                    Provider.of<LibraryProvider>(
                      context,
                      listen: false,
                    ).setView(LibraryView.calendar);
                  } else if (value == 'clear') {
                    final provider = Provider.of<TaskProvider>(
                      context,
                      listen: false,
                    );
                    final box = Hive.box<Task>(NotesRepository.taskBoxName);
                    final today = DateTime.now();
                    final completedToday = box.values
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
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'add',
                    child: Row(
                      children: [
                        const Icon(Icons.add, size: 18),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.addTask),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'calendar',
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.viewCalendar),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_sweep, size: 18),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.clearCompleted),
                      ],
                    ),
                  ),
                ],
                icon: Icon(Icons.more_horiz, color: subTextColor),
              ),
            ],
          ),
        ),
        Expanded(
          child: tasks.isEmpty
              ? EmptyState(
                  icon: Icons.event_available_outlined,
                  title: AppLocalizations.of(context)!.freeDay,
                  subtitle: AppLocalizations.of(context)!.noTasksScheduled,
                  actionLabel: AppLocalizations.of(context)!.addTask,
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
                    return _buildTimelineItem(
                      context,
                      task,
                      index == 0,
                      textColor,
                      subTextColor,
                      cardBg,
                      dividerColor,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    Task task,
    bool isFirst,
    Color textColor,
    Color subTextColor,
    Color cardBg,
    Color dividerColor,
  ) {
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
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border.all(color: color, width: 2),
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: dividerColor.withValues(alpha: 0.5),
                ),
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
                      color: subTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTaskCard(
                    task,
                    cardBg,
                    dividerColor,
                    textColor,
                    subTextColor,
                  ),
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
