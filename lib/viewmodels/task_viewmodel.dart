import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/task_models.dart';
import '../services/task_service.dart';

class TaskViewModel extends ChangeNotifier {
  TaskViewModel(this._taskService);

  final TaskService _taskService;

  List<TaskModel> tasks = [];
  bool isLoading = false;
  String? _groupId;
  AppUser? _viewer;
  StreamSubscription<List<TaskModel>>? _taskSubscription;

  void setContext({required String? groupId, required AppUser? viewer}) {
    final sameGroup = _groupId == groupId;
    final sameViewer = _viewer?.uid == viewer?.uid;
    if (sameGroup && sameViewer) return;

    _groupId = groupId;
    _viewer = viewer;
    _taskSubscription?.cancel();
    tasks = [];

    if (groupId == null) {
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();

    _taskSubscription = _taskService
        .listenToTasks(groupId)
        .listen(
          (data) {
            if (kDebugMode) {
              print('DEBUG: Received ${data.length} tasks for group $groupId');
            }
            tasks = _filterTasks(data);
            isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            if (kDebugMode) {
              print('DEBUG: Error listening to tasks: $error');
            }
            isLoading = false;
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
    await _taskService.createTask(task);
  }

  Future<void> updateStatus(String taskId, String status) async {
    await _taskService.updateTaskStatus(taskId, status);
  }

  List<TaskModel> _filterTasks(List<TaskModel> data) {
    if (_viewer?.role == 'admin') {
      return data;
    }
    final viewerId = _viewer?.uid;
    if (viewerId == null) return [];
    return data.where((task) => task.assigneeId == viewerId).toList();
  }
}
