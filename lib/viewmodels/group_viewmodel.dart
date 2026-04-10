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

  StreamSubscription<List<GroupModel>>? _groupSubscription;
  String? _userId;

  void attachUser(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _groupSubscription?.cancel();
    groups = [];
    selectedGroupId = null;

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
            notifyListeners();
          },
          onError: (_) {
            isLoading = false;
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
    await _groupService.createGroup(
      name: name,
      description: description,
      ownerId: ownerId,
    );
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
}
