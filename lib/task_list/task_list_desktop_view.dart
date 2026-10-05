import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import 'task_list_view_model.dart';

class DesktopLayout extends StatefulWidget {
  const DesktopLayout({super.key});

  @override
  State<DesktopLayout> createState() => _DesktopLayoutState();
}

class _DesktopLayoutState extends State<DesktopLayout> {
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
      id: null,
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      isCompleted: false,
      priority: selectedPriority,
      dueDate: selectedDate,
      createdAt: DateTime.now(),
      isSynced: false,
    );
    await viewModel.addTask(newTask);

    // Clear form inputs after successful submission
    titleController.clear();
    descriptionController.clear();
    dateController.clear();
    setState(() {
      selectedDate = null;
      selectedPriority = TaskPriority.meh;
    });

    _showSnackBar('Task saved!');
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
            title: const Text('Task Manager Application'),
            actions: [
              
            ],
          ),
          body: Row(
            children: [
              // Left Side: Task Creation Form
              Expanded(
                flex: 2,
                child: Container(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create New Task',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Task name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.task),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description),
                          ),
                        ),
                        const SizedBox(height: 20),
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
                            DropdownMenuItem(
                              value: TaskPriority.meh,
                              child: Text("Meh"),
                            ),
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
                        const SizedBox(height: 20),
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
                                dateController.text = "${pickedDate.toLocal()}"
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
                          onPressed: () => _saveTask(viewModel),
                          icon: const Icon(Icons.add),
                          label: const Text(
                            'Add Task',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              // Right Side: Task List View
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tasks (${viewModel.tasks.length})',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: viewModel.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : viewModel.tasks.isEmpty
                            ? const Center(
                                child: Text(
                                  'No tasks available.',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: viewModel.tasks.length,
                                itemBuilder: (context, index) {
                                  final task = viewModel.tasks[index];
                                  final formattedDate = task.dueDate != null
                                      ? "${task.dueDate!.toLocal()}".split(
                                          ' ',
                                        )[0]
                                      : 'No due date';

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: ListTile(
                                      leading: Checkbox(
                                        value: task.isCompleted,
                                        onChanged: (bool? value) {
                                          if (value != null) {
                                            viewModel.toggleTaskCompletion(
                                              task,
                                              value,
                                            );
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(
                                            task.description ??
                                                'No description',
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
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
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
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: _getPriorityColor(
                                                    task.priority,
                                                  ).withValues(alpha: 0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  _getPriorityText(
                                                    task.priority,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: _getPriorityColor(
                                                      task.priority,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              if (!task.isSynced)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.amber
                                                        .withValues(alpha: 0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
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
                                                          fontWeight:
                                                              FontWeight.bold,
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
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: () {
                                          if (task.id != null) {
                                            viewModel.deleteTask(task.id!);
                                          }
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
