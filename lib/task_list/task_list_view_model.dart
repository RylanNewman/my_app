import 'package:flutter/foundation.dart';
import 'package:my_app/models/task.dart';
import 'package:my_app/repositories/task_repository.dart';

class TaskListViewModel extends ChangeNotifier {
  final TaskRepository repository;
  List<TaskItem> tasks = [];
  bool isLoading = false;
  bool _isSyncing = false;
  String? errorMessage;

  TaskListViewModel({required this.repository});

  Future<void> loadTasks() async {
    // 1. Prevent duplicate concurrent runs if a load/sync is already in progress
    if (_isSyncing) return;
    _isSyncing = true;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    // 2. Immediately render local cached tasks so UI displays instantly offline
    try {
      final cached = await repository.getCachedTasks();
      debugPrint('📱 [CACHE READ]: Found ${cached.length} tasks locally');
      if (cached.isNotEmpty) {
        tasks = cached;
        notifyListeners(); // Update view with cached tasks while network request processes
      }
    } catch (e) {
      debugPrint('⚠️ [CACHE READ FAILED]: $e');
    }

    // 3. Attempt background network sync & remote fetch
    try {
      debugPrint('🌐 [NETWORK ATTEMPT]: Fetching from server...');
      final remote = await repository.getTasks();
      debugPrint('✅ [NETWORK SUCCESS]: Fetched ${remote.length} tasks');
      tasks = remote;
      errorMessage = null;
    } catch (e) {
      debugPrint('❌ [NETWORK FAILED]: Server unreachable. Retaining cache.');
      if (tasks.isEmpty) {
        errorMessage = "Offline mode: Failed to connect to server.";
      } else {
        errorMessage = "Offline mode: Showing cached data.";
      }
    } finally {
      isLoading = false;
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Alias for createTask to match UI callers expecting `addTask`
  Future<void> addTask(TaskItem task) async {
    await createTask(task);
  }

  /// Persists newly added items to repository and updates local list
  Future<void> createTask(TaskItem task) async {
    try {
      await repository.createTask(task);
      tasks = await repository.getCachedTasks();
      errorMessage = null;
    } catch (e) {
      debugPrint('❌ [CREATE TASK FAILED]: $e');
      errorMessage = "Task created locally (Offline).";
      tasks = await repository.getCachedTasks();
    } finally {
      notifyListeners();
    }
  }

  /// Alias for editTask / updateTask to match UI callers expecting `editTask`
  Future<void> editTask(TaskItem updatedTask) async {
    await updateTask(updatedTask);
  }

  /// Updates task details across UI, local cache, and remote backend
  Future<void> updateTask(TaskItem updatedTask) async {
    // Optimistic UI update
    final index = tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      tasks[index] = updatedTask;
      notifyListeners();
    }

    try {
      await repository.updateTask(updatedTask);
      errorMessage = null;
    } catch (e) {
      debugPrint('❌ [UPDATE TASK FAILED]: $e');
      errorMessage = "Offline mode: Updated locally.";
    } finally {
      // Reload cache to keep sync status in agreement
      tasks = await repository.getCachedTasks();
      notifyListeners();
    }
  }

  /// Alias for toggleCompletion to match UI callers expecting `toggleTaskCompletion`
  Future<void> toggleTaskCompletion(TaskItem task, bool isCompleted) async {
    final updatedTask = task.copyWith(isCompleted: isCompleted);
    await toggleCompletion(updatedTask);
  }

  /// Updates task completion state in local cache and backend
  Future<void> toggleCompletion(TaskItem task) async {
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      tasks[index] = task;
      notifyListeners();
    }

    try {
      await repository.updateTask(task);
      errorMessage = null;
    } catch (e) {
      errorMessage = "Offline mode: Updated locally.";
    }
  }

  /// Deletes task by ID safely
  Future<void> deleteTask(int id) async {
    tasks.removeWhere((t) => t.id == id);
    notifyListeners();

    try {
      await repository.deleteTask(id);
      errorMessage = null;
    } catch (e) {
      errorMessage = "Offline mode: Deleted locally.";
    }
  }
}
