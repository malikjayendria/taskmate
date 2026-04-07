import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  String id;
  String title;
  String assignedTo; // Nama anggota kelompok
  String status;     // To Do, In Progress, Completed
  DateTime deadline;

  TaskModel({
    required this.id,
    required this.title,
    required this.assignedTo,
    required this.status,
    required this.deadline,
  });

  // Mengubah data dari Firestore (Map) ke Object Flutter
  factory TaskModel.fromMap(Map<String, dynamic> data, String documentId) {
    return TaskModel(
      id: documentId,
      title: data['title'] ?? '',
      assignedTo: data['assignedTo'] ?? '',
      status: data['status'] ?? 'To Do',
      deadline: (data['deadline'] as Timestamp).toDate(),
    );
  }

  // Mengubah Object Flutter ke Map untuk disimpan di Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'assignedTo': assignedTo,
      'status': status,
      'deadline': deadline,
    };
  }
}