import 'package:flutter/material.dart';
import 'package:my_app/task_list/task_list_view_model.dart';
import 'package:provider/provider.dart';

import '../../models/task.dart';

class MobileLayout extends StatefulWidget {
  const MobileLayout({super.key});

  @override
  State<MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends State<MobileLayout> {
  int _selectedIndex = 0;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  DateTime? selectedDate;
  TaskPriority selectedPriority = TaskPriority.meh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskListViewModel>().loadTasks();
    });
  }

  void _saveTask(TaskListViewModel viewModel) async {
    if (titleController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty ||
        selectedDate == null) {
      _showSnackBar('Please fill out all fields!');
      return;
    }

    final newTask = TaskItem(
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      isCompleted: false,
      priority: selectedPriority,
      dueDate: selectedDate,
      createdAt: DateTime.now(),
      isSynced: false,
    );

    await viewModel.addTask(newTask);

    titleController.clear();
    descriptionController.clear();
    dateController.clear();
    setState(() {
      selectedDate = null;
      selectedPriority = TaskPriority.meh;
      _selectedIndex = 1; // Automatically switch to Tasks tab after creation
    });

    _showSnackBar('Task saved!');
  }

  void _showEditTaskSheet(BuildContext context, TaskItem task) {
    final editTitleController = TextEditingController(text: task.title);
    final editDescController = TextEditingController(text: task.description);
    final editDateController = TextEditingController(
      text: task.dueDate != null
          ? "${task.dueDate!.toLocal()}".split(' ')[0]
          : '',
    );

    DateTime? editSelectedDate = task.dueDate;
    TaskPriority editSelectedPriority = task.priority;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Edit Task',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: editTitleController,
                      decoration: const InputDecoration(
                        labelText: 'Task name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.task),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: editDescController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<TaskPriority>(
                      initialValue: editSelectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flag),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: TaskPriority.dontCare,
                          child: Text("Don't Care"),
                        ),
                        DropdownMenuItem(
                          value: TaskPriority.meh,
                          child: Text("Meh"),
                        ),
                        DropdownMenuItem(
                          value: TaskPriority.doItNow,
                          child: Text("Do It Now"),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() => editSelectedPriority = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: editDateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Due Date',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: editSelectedDate ?? DateTime.now(),
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setSheetState(() {
                            editSelectedDate = picked;
                            editDateController.text = "${picked.toLocal()}"
                                .split(' ')[0];
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: () async {
                        if (editTitleController.text.trim().isEmpty ||
                            editDescController.text.trim().isEmpty ||
                            editSelectedDate == null) {
                          _showSnackBar('Please fill out all fields!');
                          return;
                        }

                        final updatedTask = task.copyWith(
                          id: task.id,
                          title: editTitleController.text.trim(),
                          description: editDescController.text.trim(),
                          priority: editSelectedPriority,
                          dueDate: editSelectedDate,
                          isSynced: false,
                        );

                        await context.read<TaskListViewModel>().editTask(
                          updatedTask,
                        );

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          _showSnackBar('Task updated!');
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    dateController.dispose();
    super.dispose();
  }

  String _getPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.dontCare:
        return "Low";
      case TaskPriority.meh:
        return "Medium";
      case TaskPriority.doItNow:
        return "High";
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.dontCare:
        return Colors.green;
      case TaskPriority.meh:
        return Colors.orange;
      case TaskPriority.doItNow:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskListViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Text(
              _selectedIndex == 0 ? 'Task Application Manager' : 'Task List',
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Sync & Refresh Tasks',
                onPressed: () => viewModel.loadTasks(),
              ),
            ],
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              // Page 1: Create Task View
              _buildCreateTaskView(viewModel),
              // Page 2: Task List View
              _buildTaskListView(viewModel),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.add_task),
                label: 'New Task',
              ),
              NavigationDestination(
                icon: Badge(
                  label: Text('${viewModel.tasks.length}'),
                  child: const Icon(Icons.list_alt),
                ),
                label: 'Tasks',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCreateTaskView(TaskListViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Task name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.task),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<TaskPriority>(
            initialValue: selectedPriority,
            decoration: const InputDecoration(
              labelText: 'Priority',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.flag),
            ),
            items: const [
              DropdownMenuItem(
                value: TaskPriority.dontCare,
                child: Text("Don't Care"),
              ),
              DropdownMenuItem(value: TaskPriority.meh, child: Text("Meh")),
              DropdownMenuItem(
                value: TaskPriority.doItNow,
                child: Text("Do It Now"),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => selectedPriority = value);
              }
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: dateController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Due Date',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_today),
            ),
            onTap: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
              );
              if (pickedDate != null) {
                setState(() {
                  selectedDate = pickedDate;
                  dateController.text = "${pickedDate.toLocal()}".split(' ')[0];
                });
              }
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            onPressed: () => _saveTask(viewModel),
            icon: const Icon(Icons.add),
            label: const Text('Add Task', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskListView(TaskListViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.tasks.isEmpty) {
      return const Center(
        child: Text(
          'No tasks available.',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: viewModel.tasks.length,
      itemBuilder: (context, index) {
        final task = viewModel.tasks[index];
        final formattedDate = task.dueDate != null
            ? "${task.dueDate!.toLocal()}".split(' ')[0]
            : 'No due date';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showEditTaskSheet(context, task),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: ListTile(
                leading: Checkbox(
                  value: task.isCompleted,
                  onChanged: (bool? value) {
                    if (value != null) {
                      viewModel.toggleTaskCompletion(task, value);
                    }
                  },
                ),
                title: Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                subtitle: Column(
crossAxisAlignment: CrossAxisAlignment.start,                  children: [
                    const SizedBox(height: 4),
                    Text(
                      task.description ?? 'No description',
                      style: TextStyle(
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(task.priority)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getPriorityText(task.priority),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getPriorityColor(task.priority),
                            ),
                          ),
                        ),
                        if (!task.isSynced)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.cloud_off,
                                  size: 12,
                                  color: Colors.amber,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Offline',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () {
                    if (task.id != null) {
                      viewModel.deleteTask(task.id!);
                    }
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
