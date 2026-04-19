import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/group_model.dart';

class GroupService {
  GroupService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _groupsRef =>
      _firestore.collection('groups');

  Future<GroupModel> createGroup({
    required String name,
    required String description,
    required String ownerId,
  }) async {
    final doc = await _groupsRef.add({
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'members': [ownerId],
      'createdAt': Timestamp.now(),
    });

    final snapshot = await doc.get();
    return GroupModel.fromMap(snapshot.data() ?? {}, snapshot.id);
  }

  Stream<List<GroupModel>> listenToGroups(String userId) {
    return _groupsRef
        .where('members', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GroupModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> addMember({
    required String groupId,
    required String memberId,
  }) async {
    await _groupsRef.doc(groupId).update({
      'members': FieldValue.arrayUnion([memberId]),
    });
  }

  Future<void> updateGroup({
    required String groupId,
    required String name,
    required String description,
  }) async {
    await _groupsRef.doc(groupId).update({
      'name': name,
      'description': description,
    });
  }

  Future<void> deleteGroup(String groupId) async {
    final batch = _firestore.batch();

    final groupDoc = await _groupsRef.doc(groupId).get();
    final memberIds = List<String>.from(groupDoc.data()?['members'] ?? []);

    final tasksSnapshot = await _firestore
        .collection('tasks')
        .where('groupId', isEqualTo: groupId)
        .get();
    for (var doc in tasksSnapshot.docs) {
      batch.delete(doc.reference);
    }

    for (var userId in memberIds) {
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'groupIds': FieldValue.arrayRemove([groupId]),
      });
    }

    batch.delete(_groupsRef.doc(groupId));

    await batch.commit();
  }
}
