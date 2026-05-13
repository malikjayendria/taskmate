import 'package:cloud_firestore/cloud_firestore.dart';

class TaskNote {
  TaskNote({
    required this.text,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
  });

  final String text;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;

  factory TaskNote.fromMap(Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    return TaskNote(
      text: data['text'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdByName: data['createdByName'] ?? '',
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : createdAt is DateTime
          ? createdAt
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

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
    this.notes = const [],
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
  final List<TaskNote> notes;

  bool get isOverdue {
    if (status == 'Completed') return false;
    return deadline.isBefore(DateTime.now());
  }

  factory TaskModel.fromMap(Map<String, dynamic> data, String documentId) {
    final timestampDeadline = data['deadline'];
    final timestampCreatedAt = data['createdAt'];
    final notesData = data['notes'] as List<dynamic>? ?? [];

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
      notes: notesData
          .map((n) => TaskNote.fromMap(Map<String, dynamic>.from(n)))
          .toList(),
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
      'notes': notes.map((n) => n.toMap()).toList(),
    };
  }
}

extension TaskModelExtension on TaskModel {
  TaskModel copyWith({
    String? title,
    String? description,
    String? assigneeId,
    String? assigneeName,
    String? status,
    DateTime? deadline,
    List<TaskNote>? notes,
  }) {
    return TaskModel(
      id: id,
      groupId: groupId,
      title: title ?? this.title,
      description: description ?? this.description,
      assigneeId: assigneeId ?? this.assigneeId,
      assigneeName: assigneeName ?? this.assigneeName,
      status: status ?? this.status,
      deadline: deadline ?? this.deadline,
      createdBy: createdBy,
      createdAt: createdAt,
      notes: notes ?? this.notes,
    );
  }
}
