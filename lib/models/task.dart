import 'dart:convert';

enum TaskPriority { dontCare, meh, doItNow }

class TaskItem {
  final int? id;
  final String title;
  final String? description;
  final bool isCompleted;
  final TaskPriority priority;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final bool isSynced;

  TaskItem({
    this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.priority = TaskPriority.meh,
    this.dueDate,
    DateTime? createdAt,
    this.isSynced = true,
  }) : createdAt = createdAt ?? DateTime.now();

  factory TaskItem.fromRawJson(String str) =>
      TaskItem.fromJson(json.decode(str) as Map<String, dynamic>);

  String toRawJson() => json.encode(toJson());

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    // 1. Handle flexible integer parsing for priority
    int priorityIndex =
        json['priority'] as int? ?? json['Priority'] as int? ?? 1;
    if (priorityIndex < 0 || priorityIndex >= TaskPriority.values.length) {
      priorityIndex = TaskPriority.meh.index;
    }

    // 2. Fallback parsing for dates
    DateTime? parsedCreatedAt;
    final rawCreatedAt = json['createdAt'] ?? json['CreatedAt'];
    if (rawCreatedAt != null && rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt);
    }

    DateTime? parsedDueDate;
    final rawDueDate = json['dueDate'] ?? json['DueDate'];
    if (rawDueDate != null && rawDueDate is String) {
      parsedDueDate = DateTime.tryParse(rawDueDate);
    }

    return TaskItem(
      id: json['id'] as int? ?? json['Id'] as int?,
      title:
          json['title'] as String? ??
          json['Title'] as String? ??
          'Untitled Task',
      description:
          json['description'] as String? ?? json['Description'] as String?,
      isCompleted:
          json['isCompleted'] as bool? ??
          json['IsCompleted'] as bool? ??
          json['is_completed'] as bool? ??
          false,
      priority: TaskPriority.values[priorityIndex],
      dueDate: parsedDueDate,
      createdAt: parsedCreatedAt ?? DateTime.now(),
      isSynced:
          json['isSynced'] as bool? ??
          true, // 👈 Ensures local cache reads `isSynced`
    );
  }

  /// Output JSON payload specifically for .NET Web API
   Map<String, dynamic> toJson() => {
    // 👈 Only attach ID if positive (real server ID), omit temporary offline negative IDs
    if (id != null && id! > 0) 'id': id,
    'title': title,
    'description': description,
    'isCompleted': isCompleted,
    'priority': priority.index,
    'dueDate': dueDate?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(),
  };

  /// Output JSON for local disk storage (SharedPreferences / Hive)
  Map<String, dynamic> toCacheJson() => {
    'id': id, // 👈 Retains temporary negative IDs for local lookup
    'title': title,
    'description': description,
    'isCompleted': isCompleted,
    'priority': priority.index,
    'dueDate': dueDate?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(),
    'isSynced': isSynced,
  };

  /// Read JSON from local disk cache
  factory TaskItem.fromCacheJson(Map<String, dynamic> json) =>
      TaskItem.fromJson(json);

  TaskItem copyWith({
    int? id,
    String? title,
    String? description,
    bool? isCompleted,
    TaskPriority? priority,
    DateTime? dueDate,
    DateTime? createdAt,
    bool? isSynced,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
