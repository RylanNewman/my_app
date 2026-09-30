import 'package:flutter/material.dart';
import 'package:my_app/main.dart';
import 'task_list_desktop_view.dart';


class TaskListView extends StatelessWidget {
  const TaskListView({super.key}); // Included key parameter to resolve the lint warning

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          return const DesktopLayout();
        }
        return const MyApp();
      },
    );
  }
}