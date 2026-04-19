import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

class UserService {
  UserService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  Future<AppUser?> fetchUser(String uid) async {
    final snapshot = await _usersRef.doc(uid).get();
    final data = snapshot.data();
    if (data == null) return null;
    return AppUser.fromMap(data, snapshot.id);
  }

  Future<void> createOrUpdateUser(AppUser user) async {
    await _usersRef.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  Future<void> updateRole(String uid, String role) async {
    await _usersRef.doc(uid).update({'role': role});
  }

  Future<void> updateDisplayName(String uid, String displayName) async {
    await _usersRef.doc(uid).update({'displayName': displayName});
  }

  Future<void> deleteUser(String uid) async {
    await _usersRef.doc(uid).delete();
  }

  Stream<List<AppUser>> listenToUsers() {
    return _usersRef
        .orderBy('displayName')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppUser.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<List<AppUser>> fetchUsersByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final chunks = <List<String>>[];
    const chunkSize = 10;
    for (var i = 0; i < ids.length; i += chunkSize) {
      chunks.add(
        ids.sublist(i, i + chunkSize > ids.length ? ids.length : i + chunkSize),
      );
    }

    final results = await Future.wait(
      chunks.map(
        (chunk) => _usersRef.where(FieldPath.documentId, whereIn: chunk).get(),
      ),
    );
    return results
        .expand(
          (snapshot) =>
              snapshot.docs.map((doc) => AppUser.fromMap(doc.data(), doc.id)),
        )
        .toList();
  }
}
