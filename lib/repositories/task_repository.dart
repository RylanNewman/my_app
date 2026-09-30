import 'package:flutter/foundation.dart';
import 'package:my_app/models/task.dart';

import '../services/task_api_service.dart';
import '../services/task_cache_service.dart';

class TaskRepository {
  final TaskApiService apiService;
  final TaskCacheService cacheService;

  TaskRepository({required this.apiService, required this.cacheService});

  /// Exposes direct access to local disk cache for instant startup loading
  Future<List<TaskItem>> getCachedTasks() async {
    return await cacheService.getCachedTasks();
  }

  /// Synchronizes offline tasks, then fetches fresh tasks from the API.
  /// Falls back to local disk cache if the network request fails.
  Future<List<TaskItem>> getTasks() async {
    // 1. First sync any pending local additions or edits to the backend API
    await syncPendingTasks();

    try {
      // 2. Fetch fresh items from the backend API
      final remoteTasks = await apiService.fetchTasks();

      // 3. Keep only items that STILL failed to sync during step 1
      final localTasks = await cacheService.getCachedTasks();
      final unsyncedLocal = localTasks.where((t) => !t.isSynced).toList();

      // 4. Combine synced server tasks and remaining offline tasks, then update cache
      final combined = [...remoteTasks, ...unsyncedLocal];
      await cacheService.saveCache(combined);
      return combined;
    } catch (e) {
      debugPrint(
        '🌐 [NETWORK OFFLINE]: Fetch failed ($e). Returning local cache.',
      );
      return await cacheService.getCachedTasks();
    }
  }

  /// Pushes all unsynced local tasks to the backend API and updates local state
  Future<void> syncPendingTasks() async {
    final localTasks = await cacheService.getCachedTasks();
    if (localTasks.isEmpty) return;

    final updatedList = List<TaskItem>.from(localTasks);
    bool cacheChanged = false;

    for (int i = 0; i < updatedList.length; i++) {
      final task = updatedList[i];
      if (!task.isSynced) {
        // CASE A: New offline task (temp ID < 0) -> Call CREATE endpoint
        if (task.id != null && task.id! < 0) {
          debugPrint(
            '🔄 [SYNCING NEW]: Uploading offline task "${task.title}"...',
          );
          try {
            final syncedTask = await apiService.createTask(task);
            updatedList[i] = syncedTask.copyWith(isSynced: true);
            cacheChanged = true;
            debugPrint(
              '✅ [SYNCED NEW]: Task "${task.title}" created on server (ID: ${syncedTask.id}).',
            );
          } catch (e) {
            debugPrint(
              '❌ [SYNC FAILED]: Could not create "${task.title}" ($e).',
            );
          }
        }
        // CASE B: Existing server task edited offline (ID > 0) -> Call UPDATE endpoint
        else if (task.id != null && task.id! > 0) {
          debugPrint(
            '🔄 [SYNCING EDIT]: Pushing updates for task "${task.title}"...',
          );
          try {
            await apiService.updateTask(task);
            updatedList[i] = task.copyWith(isSynced: true);
            cacheChanged = true;
            debugPrint(
              '✅ [SYNCED EDIT]: Updates pushed for "${task.title}" (ID: ${task.id}).',
            );
          } catch (e) {
            debugPrint(
              '❌ [SYNC FAILED]: Could not update "${task.title}" ($e).',
            );
          }
        }
      }
    }

    if (cacheChanged) {
      await cacheService.saveCache(updatedList);
    }
  }

  /// Optimistically persists task to local cache, then attempts server sync.
  Future<void> createTask(TaskItem task) async {
    final currentTasks = await cacheService.getCachedTasks();

    try {
      final createdTask = await apiService.createTask(task);
      currentTasks.add(createdTask.copyWith(isSynced: true));
      await cacheService.saveCache(currentTasks);
      debugPrint('✅ [SERVER CREATED]: Task created on backend.');
    } catch (e) {
      // Assign temporary negative ID so local state can identify it uniquely as a creation
      final tempId = -DateTime.now().millisecondsSinceEpoch;
      final offlineTask = task.copyWith(id: tempId, isSynced: false);

      currentTasks.add(offlineTask);
      await cacheService.saveCache(currentTasks);
      debugPrint(
        '📱 [OFFLINE CREATED]: Saved task locally with temp ID: $tempId',
      );
    }
  }

  /// Optimistically updates task in local cache, then attempts server sync.
  Future<void> updateTask(TaskItem task) async {
    final currentTasks = await cacheService.getCachedTasks();
    final index = currentTasks.indexWhere((t) => t.id == task.id);

    // If offline update fails later, task will be saved locally with isSynced = false
    final updatedTask = task.copyWith(isSynced: false);

    try {
      // If it's a temp offline task (< 0), update local cache directly without API call
      if (task.id != null && task.id! < 0) {
        if (index != -1) {
          currentTasks[index] = updatedTask;
          await cacheService.saveCache(currentTasks);
        }
        return;
      }

      // Try server update first
      await apiService.updateTask(task);
      debugPrint('✅ [SERVER UPDATED]: Task updated on backend.');

      if (index != -1) {
        currentTasks[index] = task.copyWith(isSynced: true);
        await cacheService.saveCache(currentTasks);
      }
    } catch (e) {
      debugPrint('📱 [OFFLINE UPDATE]: Update saved locally.');
      if (index != -1) {
        currentTasks[index] = updatedTask;
        await cacheService.saveCache(currentTasks);
      }
    }
  }

  /// Deletes a task by ID or removes an unsynced task from local cache
  Future<void> deleteTask(int? id) async {
    if (id == null) return;

    final currentTasks = await cacheService.getCachedTasks();
    currentTasks.removeWhere((t) => t.id == id);
    await cacheService.saveCache(currentTasks);

    // If it was a temporary offline task (negative ID), skip server delete endpoint
    if (id < 0) return;

    try {
      await apiService.deleteTask(id);
      debugPrint('✅ [SERVER DELETED]: Task removed from backend.');
    } catch (e) {
      debugPrint('📱 [OFFLINE DELETE]: Delete saved locally.');
    }
  }
}
