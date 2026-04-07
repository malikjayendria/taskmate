import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taskmate/models/task_models.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fitur 3: Membuat dan Membagi Tugas (Halaman 4 Proposal)
  Future<void> addTask(TaskModel task) async {
    await _db.collection('tasks').add(task.toMap());
  }

  // Fitur 4: Melihat Daftar Tugas secara Real-time (Halaman 4 Proposal)
  Stream<List<TaskModel>> getTasks() {
    return _db.collection('tasks').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => TaskModel.fromMap(doc.data(), doc.id)).toList());
  }

  // Fitur 5: Update Status Tugas (Halaman 5 Proposal)
  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    await _db.collection('tasks').doc(taskId).update({'status': newStatus});
  }
}