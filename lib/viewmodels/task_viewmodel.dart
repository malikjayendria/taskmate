import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/task_models.dart';
import '../services/task_service.dart';

class TaskViewModel extends ChangeNotifier {
  TaskViewModel(this._taskService);

  final TaskService _taskService;

  List<TaskModel> tasks = [];
  bool isLoading = false;
  String? errorMessage;

  StreamSubscription<List<TaskModel>>? _taskSubscription;
  String? _currentGroupId;

  void attachGroup(String? groupId) {
    if (_currentGroupId == groupId) return;
    _currentGroupId = groupId;
    _taskSubscription?.cancel();
    _taskSubscription = null;
    tasks = [];
    errorMessage = null;

    if (groupId == null) {
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();

    _taskSubscription = _taskService.listenToTasks(groupId).listen(
      (data) {
        tasks = data;
        isLoading = false;
        errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        isLoading = false;
        errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _taskSubscription?.cancel();
    super.dispose();
  }

  Future<void> createTask(TaskModel task) async {
    try {
      await _taskService.createTask(task);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateStatus(String taskId, String newStatus) async {
    try {
      final index = tasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        final updatedTask = tasks[index].copyWith(status: newStatus);
        tasks[index] = updatedTask;
        notifyListeners();
      }
      await _taskService.updateTaskStatus(taskId, newStatus);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAssignee(
    String taskId,
    String assigneeId,
    String assigneeName,
  ) async {
    try {
      await _taskService.updateTaskAssignee(taskId, assigneeId, assigneeName);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addTaskNote(String taskId, TaskNote note) async {
    try {
      await _taskService.addTaskNote(taskId, note);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _taskService.deleteTask(taskId);
    } catch (e) {
      rethrow;
    }
  }
}
