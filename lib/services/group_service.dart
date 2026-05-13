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
    required String leaderId,
    required List<String> members,
  }) async {
    final allMembers = Set<String>.from(members);
    allMembers.add(ownerId);
    allMembers.add(leaderId);

    final doc = await _groupsRef.add({
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'leaderId': leaderId,
      'members': allMembers.toList(),
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
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => GroupModel.fromMap(doc.data(), doc.id))
              .toList();
        });
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
    String? leaderId,
  }) async {
    final data = {
      'name': name,
      'description': description,
    };
    if (leaderId != null) {
      data['leaderId'] = leaderId;
    }
    await _groupsRef.doc(groupId).update(data);
  }

  Future<void> deleteGroup(String groupId) async {
    final groupDoc = await _groupsRef.doc(groupId).get();
    if (!groupDoc.exists) return;

    final memberIds = List<String>.from(groupDoc.data()?['members'] ?? []);

    // 1. Delete all tasks in this group
    final tasksSnapshot = await _firestore
        .collection('tasks')
        .where('groupId', isEqualTo: groupId)
        .get();

    final batch = _firestore.batch();

    for (var doc in tasksSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 2. Delete the group document
    batch.delete(_groupsRef.doc(groupId));

    // 3. Commit tasks and group deletion first
    await batch.commit();

    // 4. Update user profile references (Optional/Clean-up)
    // We do this separately because if a user document doesn't exist, 
    // it would cause the entire batch to fail.
    if (memberIds.isNotEmpty) {
      for (var userId in memberIds) {
        _firestore.collection('users').doc(userId).update({
          'groupIds': FieldValue.arrayRemove([groupId]),
        }).catchError((e) {
          // Ignore if user doc doesn't exist
          return null;
        });
      }
    }
  }
}
