import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/user_service.dart';

class UserViewModel extends ChangeNotifier {
  UserViewModel(this._userService);

  final UserService _userService;

  List<AppUser> users = [];
  StreamSubscription<List<AppUser>>? _userSubscription;

  void startListening() {
    _userSubscription ??= _userService.listenToUsers().listen((event) {
      users = event;
      notifyListeners();
    });
  }

  Future<List<AppUser>> fetchUsersByIds(List<String> ids) {
    return _userService.fetchUsersByIds(ids);
  }

  Future<void> updateRole(String uid, String role) {
    return _userService.updateRole(uid, role);
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
