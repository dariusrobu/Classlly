import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:classlly/data/models/task_model.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/features/library/screens/add_task_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filter = 'All'; // All, High, Medium, Low

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Task>(NotesRepository.taskBoxName).listenable(),
      builder: (context, Box<Task> box, _) {
        final allTasks = box.values.toList();

        // Filter logic
        var filteredTasks = allTasks;
        if (_filter != 'All') {
          final priorityMap = {'High': 2, 'Medium': 1, 'Low': 0};
          filteredTasks = filteredTasks
              .where((t) => t.priority == priorityMap[_filter])
              .toList();
        }

        final todoTasks = filteredTasks
            .where((t) => !t.isCompleted && t.progress == 0)
            .toList();
        final inProgressTasks = filteredTasks
            .where((t) => !t.isCompleted && t.progress > 0)
            .toList();
        final doneTasks = filteredTasks.where((t) => t.isCompleted).toList();

        return Column(
          children: [
            _buildHeader(
              context,
              allTasks.length,
              todoTasks.length + inProgressTasks.length,
              doneTasks.length,
            ),
            const SizedBox(height: 8),
            _buildToolbar(context),
            const SizedBox(height: 24),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildKanbanView(todoTasks, inProgressTasks, doneTasks),
                  _buildListView(filteredTasks),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          _buildTabs(context),
          const Spacer(),
          _buildFilterChip(context),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filter,
          icon: const Icon(Icons.filter_list, size: 16),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          items: [
            'All',
            'High',
            'Medium',
            'Low',
          ].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
          onChanged: (v) => setState(() => _filter = v!),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int total, int pending, int done) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Task Dashboard',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'You have $pending pending tasks',
                style: TextStyle(
                  color: isDark ? Colors.grey[600] : Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _summaryCard('Total', '$total', Colors.blue),
              const SizedBox(width: 12),
              _summaryCard('Pending', '$pending', Colors.orange),
              const SizedBox(width: 12),
              _summaryCard('Done', '$done', Colors.green),
              const SizedBox(width: 24),
              ElevatedButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (c) => const AddTaskScreen(),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Task'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 40,
      width: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(2),
        labelColor: colorScheme.primary,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        tabs: const [
          Tab(
            text: 'Board',
            icon: Icon(Icons.view_kanban, size: 14),
            iconMargin: EdgeInsets.only(bottom: 2),
          ),
          Tab(
            text: 'List',
            icon: Icon(Icons.list, size: 14),
            iconMargin: EdgeInsets.only(bottom: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanView(
    List<Task> todo,
    List<Task> inProgress,
    List<Task> done,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kanbanColumn('To Do', todo, Colors.grey),
          const SizedBox(width: 24),
          _kanbanColumn('In Progress', inProgress, Colors.orange),
          const SizedBox(width: 24),
          _kanbanColumn('Done', done, Colors.green),
        ],
      ),
    );
  }

  Widget _kanbanColumn(String title, List<Task> tasks, Color color) {
    return SizedBox(
      width: 320,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (tasks.isEmpty)
            Container(
              height: 100,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.2),
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'No tasks',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) => _TaskCard(task: tasks[index]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListView(List<Task> tasks) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _TaskCard(task: task, isList: true),
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final bool isList;
  const _TaskCard({required this.task, this.isList = false});

  @override
  Widget build(BuildContext context) {
    final priorityColor = task.priority == 2
        ? Colors.red
        : (task.priority == 1 ? Colors.orange : Colors.blue);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: isList ? 0 : 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  task.priority == 2
                      ? 'HIGH'
                      : (task.priority == 1 ? 'MEDIUM' : 'LOW'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: priorityColor,
                  ),
                ),
              ),
              if (task.dueDate != null)
                Text(
                  DateFormat('MMM d').format(task.dueDate!),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey : Colors.grey[900],
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            task.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          if (task.description?.isNotEmpty == true && !isList) ...[
            const SizedBox(height: 8),
            Text(
              task.description!,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey : Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.folder_open,
                size: 14,
                color: isDark ? Colors.grey : Colors.grey[800],
              ),
              const SizedBox(width: 4),
              Text(
                task.category ?? 'General',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey : Colors.grey[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (task.isCompleted)
                const Icon(Icons.check_circle, color: Colors.green, size: 22)
              else
                Icon(Icons.circle_outlined, color: Colors.grey[400], size: 22),
            ],
          ),
        ],
      ),
    );
  }
}
