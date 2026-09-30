import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'repositories/task_repository.dart';
import 'services/task_api_service.dart';
import 'services/task_cache_service.dart';
import 'task_list/task_list_desktop_view.dart';
import 'task_list/task_list_mobile_view.dart';
import 'task_list/task_list_view_model.dart';

/// Returns the correct base URL depending on platform runtime environment.
String getApiBaseUrl() {
  if (kIsWeb) {
    return 'http://127.0.0.1:5246/api';
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      // 10.0.2.2 maps directly to host localhost inside the Android Emulator
      return 'http://10.0.2.2:5246/api';
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
    case TargetPlatform.linux:
      return 'http://127.0.0.1:5246/api';
    default:
      return 'http://127.0.0.1:5246/api';
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize API, Cache, and Repository dependencies with dynamic base URL
  final apiService = TaskApiService(
    client: http.Client(),
    baseUrl: getApiBaseUrl(),
  );
  final cacheService = TaskCacheService();
  final taskRepository = TaskRepository(
    apiService: apiService,
    cacheService: cacheService,
  );

  runApp(
    // 2. Provide TaskListViewModel above ResponsiveLayoutWrapper
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              TaskListViewModel(repository: taskRepository)..loadTasks(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task Manager App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 157, 15, 167),
        ),
      ),
      home: const ResponsiveLayoutWrapper(),
    );
  }
}

class ResponsiveLayoutWrapper extends StatelessWidget {
  const ResponsiveLayoutWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If screen width is 600px or larger, load Desktop side-by-side view
        if (constraints.maxWidth >= 600) {
          return const DesktopLayout();
        }
        // Otherwise, load Mobile single-screen view
        return const MobileLayout();
      },
    );
  }
}
