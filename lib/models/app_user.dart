import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.groupIds,
    required this.role,
    required this.createdAt,
  });

  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final List<String> groupIds;
  final String role; // admin | user
  final DateTime createdAt;

  factory AppUser.fromMap(Map<String, dynamic> data, String documentId) {
    final createdAt = data['createdAt'];
    return AppUser(
      uid: documentId,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      groupIds: List<String>.from(data['groupIds'] ?? []),
      role: data['role'] ?? 'user',
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : createdAt is DateTime
          ? createdAt
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'groupIds': groupIds,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AppUser copyWith({
    String? displayName,
    String? photoUrl,
    List<String>? groupIds,
    String? role,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      groupIds: groupIds ?? this.groupIds,
      role: role ?? this.role,
      createdAt: createdAt,
    );
  }
}
