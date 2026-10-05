import 'dart:async';

import 'package:flutter/foundation.dart';

import '../repositories/task_repository.dart';

class TaskSyncService {
  final TaskRepository repository;
  final Function() onSyncCompleted;
  Timer? _timer;

  TaskSyncService({required this.repository, required this.onSyncCompleted});

  // Starts checking for tasks created locally every 60 seconds
  void startAutoSync() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) async {
      await _checkAndSyncTasks();
    });
  }

  /// Checks if any tasks are unsynced before triggering a full fetch/sync
  Future<void> _checkAndSyncTasks() async {
    try {
      final cachedTasks = await repository.getCachedTasks();
      final hasUnsyncedTasks = cachedTasks.any(
        (task) => !task.isSynced || (task.id != null && task.id! < 0),
      );

      if (hasUnsyncedTasks) {
        debugPrint('⏰ [AUTO SYNC]: Unsynced local tasks detected. Syncing...');
        await repository.getTasks();
        onSyncCompleted(); // Notifies ViewModel to rebuild state
      } else {
        debugPrint('⏰ [AUTO SYNC]: All tasks are synced. Skipping fetch.');
      }
    } catch (e) {
      debugPrint('⏰ [AUTO SYNC FAILED]: $e');
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}
