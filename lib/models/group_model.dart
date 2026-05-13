import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.leaderId,
    required this.members,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final String ownerId;
  final String leaderId;
  final List<String> members;
  final DateTime createdAt;

  factory GroupModel.fromMap(Map<String, dynamic> data, String documentId) {
    final createdAt = data['createdAt'];

    return GroupModel(
      id: documentId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      ownerId: data['ownerId'] ?? '',
      leaderId: data['leaderId'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : createdAt is DateTime
          ? createdAt
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'leaderId': leaderId,
      'members': members,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
