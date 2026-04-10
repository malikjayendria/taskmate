import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  TaskModel({
    required this.id,
    required this.groupId,
    required this.title,
    required this.description,
    required this.assigneeId,
    required this.assigneeName,
    required this.status,
    required this.deadline,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String groupId;
  final String title;
  final String description;
  final String assigneeId;
  final String assigneeName;
  final String status; // To Do, In Progress, Completed
  final DateTime deadline;
  final String createdBy;
  final DateTime createdAt;

  factory TaskModel.fromMap(Map<String, dynamic> data, String documentId) {
    final timestampDeadline = data['deadline'];
    final timestampCreatedAt = data['createdAt'];

    return TaskModel(
      id: documentId,
      groupId: data['groupId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      assigneeId: data['assigneeId'] ?? '',
      assigneeName: data['assigneeName'] ?? '',
      status: data['status'] ?? 'To Do',
      deadline: timestampDeadline is Timestamp
          ? timestampDeadline.toDate()
          : timestampDeadline is DateTime
          ? timestampDeadline
          : DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      createdAt: timestampCreatedAt is Timestamp
          ? timestampCreatedAt.toDate()
          : timestampCreatedAt is DateTime
          ? timestampCreatedAt
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'title': title,
      'description': description,
      'assigneeId': assigneeId,
      'assigneeName': assigneeName,
      'status': status,
      'deadline': Timestamp.fromDate(deadline),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
