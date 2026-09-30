import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/task.dart';

class TaskApiService {
  final http.Client client;
  final String baseUrl;
  final Duration timeout;

  TaskApiService({
    required this.client,
    required this.baseUrl,
    this.timeout = const Duration(seconds: 5),
  });

  // GET /api/Tasks
  Future<List<TaskItem>> fetchTasks() async {
    try {
      final response = await client
          .get(
            Uri.parse('$baseUrl/Tasks'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => TaskItem.fromJson(json)).toList();
      } else {
        throw HttpException(
          'Failed to load tasks from server (${response.statusCode})',
        );
      }
    } on SocketException catch (e) {
      throw SocketException('Network unreachable: ${e.message}');
    } on TimeoutException {
      throw TimeoutException('Request timed out connecting to backend API');
    }
  }

  // GET /api/Tasks/{id}
  Future<TaskItem> fetchTaskById(int id) async {
    try {
      final response = await client
          .get(
            Uri.parse('$baseUrl/Tasks/$id'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return TaskItem.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw const HttpException('Task not found');
      } else {
        throw HttpException(
          'Failed to load task details (${response.statusCode})',
        );
      }
    } on SocketException catch (e) {
      throw SocketException('Network unreachable: ${e.message}');
    } on TimeoutException {
      throw TimeoutException('Request timed out connecting to backend API');
    }
  }

  // POST /api/Tasks
  Future<TaskItem> createTask(TaskItem task) async {
    try {
      final response = await client
          .post(
            Uri.parse('$baseUrl/Tasks'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(task.toJson()),
          )
          .timeout(timeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          return TaskItem.fromJson(json.decode(response.body));
        }
        return task;
      } else if (response.statusCode == 400) {
        throw HttpException('Invalid task payload: ${response.body}');
      } else {
        throw HttpException('Failed to create task (${response.statusCode})');
      }
    } on SocketException catch (e) {
      throw SocketException('Network unreachable: ${e.message}');
    } on TimeoutException {
      throw TimeoutException('Request timed out connecting to backend API');
    }
  }

  // PUT /api/Tasks/{id}
  Future<void> updateTask(TaskItem task) async {
    try {
      final response = await client
          .put(
            Uri.parse('$baseUrl/Tasks/${task.id}'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(task.toJson()),
          )
          .timeout(timeout);

      if (response.statusCode == 204 || response.statusCode == 200) {
        return;
      } else if (response.statusCode == 404) {
        throw const HttpException('Cannot update: Task not found');
      } else if (response.statusCode == 400) {
        throw HttpException('Invalid task payload: ${response.body}');
      } else {
        throw HttpException('Failed to update task (${response.statusCode})');
      }
    } on SocketException catch (e) {
      throw SocketException('Network unreachable: ${e.message}');
    } on TimeoutException {
      throw TimeoutException('Request timed out connecting to backend API');
    }
  }

  // DELETE /api/Tasks/{id}
  Future<void> deleteTask(int id) async {
    try {
      final response = await client
          .delete(
            Uri.parse('$baseUrl/Tasks/$id'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(timeout);

      if (response.statusCode == 204 || response.statusCode == 200) {
        return;
      } else if (response.statusCode == 404) {
        throw const HttpException('Cannot delete: Task not found');
      } else {
        throw HttpException('Failed to delete task (${response.statusCode})');
      }
    } on SocketException catch (e) {
      throw SocketException('Network unreachable: ${e.message}');
    } on TimeoutException {
      throw TimeoutException('Request timed out connecting to backend API');
    }
  }
}
