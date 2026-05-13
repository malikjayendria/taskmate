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
    _groupSubscription = null;
    groups = [];
    selectedGroupId = null;
    errorMessage = null;

    if (userId == null) {
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();

    _groupSubscription = _groupService
        .listenToGroups(userId)
        .listen(
          (data) {
            groups = data;
            selectedGroupId ??= data.isNotEmpty ? data.first.id : null;
            isLoading = false;
            errorMessage = null;
            notifyListeners();
          },
          onError: (error) {
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
    required String leaderId,
    required List<String> members,
  }) async {
    try {
      await _groupService.createGroup(
        name: name,
        description: description,
        ownerId: ownerId,
        leaderId: leaderId,
        members: members,
      );
    } catch (e) {
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
      await _groupService.addMember(groupId: groupId, memberId: userId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateGroup({
    required String groupId,
    required String name,
    required String description,
    String? leaderId,
  }) async {
    try {
      await _groupService.updateGroup(
        groupId: groupId,
        name: name,
        description: description,
        leaderId: leaderId,
      );
    } catch (e) {
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
      rethrow;
    }
  }
}
