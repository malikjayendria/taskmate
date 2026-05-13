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
    if (_userSubscription != null) {
      if (kDebugMode) print('DEBUG: UserViewModel.startListening() - already listening');
      return;
    }
    
    if (kDebugMode) print('DEBUG: UserViewModel.startListening() - starting new listener');
    _userSubscription = _userService.listenToUsers().listen((event) {
      if (kDebugMode) print('DEBUG: UserViewModel received ${event.length} users');
      users = event;
      notifyListeners();
    }, onError: (e) {
      if (kDebugMode) print('DEBUG: UserViewModel error listening to users: $e');
    });
  }

  Future<List<AppUser>> fetchUsersByIds(List<String> ids) {
    return _userService.fetchUsersByIds(ids);
  }

  Future<void> updateRole(String uid, String role) {
    return _userService.updateRole(uid, role);
  }

  Future<void> updateDisplayName(String uid, String displayName) {
    return _userService.updateDisplayName(uid, displayName);
  }

  Future<void> deleteUser(String uid) {
    return _userService.deleteUser(uid);
  }

  @override
  void dispose() {
    if (kDebugMode) print('DEBUG: UserViewModel.dispose()');
    _userSubscription?.cancel();
    super.dispose();
  }
}
