import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/group_model.dart';
import '../services/group_service.dart';

class GroupViewModel extends ChangeNotifier {
  GroupViewModel(this._groupService);

  final GroupService _groupService;

  List<GroupModel> groups = [];
  bool isLoading = false;
  String? selectedGroupId;
  String? errorMessage;

  StreamSubscription<List<GroupModel>>? _groupSubscription;
  String? _userId;

  void attachUser(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _groupSubscription?.cancel();
    groups = [];
    selectedGroupId = null;
    errorMessage = null;

    if (userId == null) {
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();

    if (kDebugMode) {
      print('DEBUG: Attaching user $userId to GroupViewModel');
    }

    _groupSubscription = _groupService
        .listenToGroups(userId)
        .listen(
          (data) {
            if (kDebugMode) {
              print('DEBUG: Received ${data.length} groups for user $userId');
            }
            groups = data;
            selectedGroupId ??= data.isNotEmpty ? data.first.id : null;
            isLoading = false;
            errorMessage = null;
            notifyListeners();
          },
          onError: (error) {
            if (kDebugMode) {
              print('DEBUG: Error listening to groups: $error');
            }
            isLoading = false;
            errorMessage = error.toString();
            notifyListeners();
          },
        );
  }

  @override
  void dispose() {
    _groupSubscription?.cancel();
    super.dispose();
  }

  Future<void> createGroup({
    required String name,
    required String description,
    required String ownerId,
  }) async {
    try {
      if (kDebugMode) {
        print('DEBUG: Creating group "$name" for owner $ownerId');
      }
      await _groupService.createGroup(
        name: name,
        description: description,
        ownerId: ownerId,
      );
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error creating group: $e');
      }
      rethrow;
    }
  }

  void selectGroup(String groupId) {
    if (selectedGroupId == groupId) return;
    selectedGroupId = groupId;
    notifyListeners();
  }

  GroupModel? get selectedGroup {
    if (selectedGroupId == null) return null;
    try {
      return groups.firstWhere((group) => group.id == selectedGroupId);
    } catch (_) {
      return null;
    }
  }

  GroupModel? byId(String id) {
    try {
      return groups.firstWhere((group) => group.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addMember(String groupId, String userId) async {
    try {
      if (kDebugMode) {
        print('DEBUG: Adding user $userId to group $groupId');
      }
      await _groupService.addMember(groupId: groupId, memberId: userId);
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error adding member: $e');
      }
      rethrow;
    }
  }

  Future<void> updateGroup({
    required String groupId,
    required String name,
    required String description,
  }) async {
    try {
      await _groupService.updateGroup(
        groupId: groupId,
        name: name,
        description: description,
      );
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error updating group: $e');
      }
      rethrow;
    }
  }

  Future<void> deleteGroup(String groupId) async {
    try {
      await _groupService.deleteGroup(groupId);
      if (selectedGroupId == groupId) {
        selectedGroupId = null;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error deleting group: $e');
      }
      rethrow;
    }
  }
}
