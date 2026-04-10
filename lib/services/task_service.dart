import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/task_models.dart';

class TaskService {
  TaskService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _tasksRef =>
      _firestore.collection('tasks');

  Future<void> createTask(TaskModel task) async {
    await _tasksRef.add(task.toMap());
  }

  Stream<List<TaskModel>> listenToTasks(String groupId) {
    return _tasksRef
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    await _tasksRef.doc(taskId).update({'status': newStatus});
  }

  Future<void> deleteTask(String taskId) async {
    await _tasksRef.doc(taskId).delete();
  }
}
