import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';

class TaskCacheService {
  static const String _cacheKey = 'cached_task_list';

  /// Saves the task list to local browser storage (localStorage)
  Future<void> saveCache(List<TaskItem> tasks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = tasks.map((t) => t.toCacheJson()).toList();
      final encodedData = json.encode(jsonList);

      await prefs.setString(_cacheKey, encodedData);
      debugPrint(
        '💾 CACHE SAVE SUCCESS: Persisted ${tasks.length} task(s) to storage.',
      );
    } catch (e) {
      debugPrint('❌ CACHE SAVE ERROR: Failed to persist cache: $e');
    }
  }

  /// Retrieves cached tasks from storage
  Future<List<TaskItem>> getCachedTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString(_cacheKey);

      if (cachedData == null || cachedData.isEmpty) {
        debugPrint('📱No cached tasks found in storage.');
        return [];
      }

      final List<dynamic> jsonList = json.decode(cachedData);
      final tasks = jsonList
          .map((item) => TaskItem.fromCacheJson(item as Map<String, dynamic>))
          .toList();

      debugPrint(
        '📱 Loaded ${tasks.length} task(s) from storage.',
      );
      return tasks;
    } catch (e) {
      debugPrint(
        '❌ Failed to parse local storage ($e). Clearing cache.',
      );
      return [];
    }
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }
}
