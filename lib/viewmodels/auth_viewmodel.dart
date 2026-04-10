import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._authService, this._userService);

  final AuthService _authService;
  final UserService _userService;

  AppUser? currentUser;
  bool isBusy = false;
  String? errorMessage;

  StreamSubscription<User?>? _authSubscription;

  bool get isAdmin => currentUser?.role == 'admin';

  void initialize() {
    _authSubscription ??= _authService.userChanges.listen((firebaseUser) {
      if (firebaseUser == null) {
        currentUser = null;
        notifyListeners();
        return;
      }
      _loadUserProfile(firebaseUser);
    });
  }

  Future<void> _loadUserProfile(User firebaseUser) async {
    final existing = await _userService.fetchUser(firebaseUser.uid);
    if (existing != null) {
      currentUser = existing;
    } else {
      final newUser = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? '',
        photoUrl: firebaseUser.photoURL,
        groupIds: const [],
        role: 'user',
        createdAt: DateTime.now(),
      );
      await _userService.createOrUpdateUser(newUser);
      currentUser = newUser;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<bool> signIn({required String email, required String password}) async {
    try {
      _setBusy(true);
      await _authService.signInWithEmail(email: email, password: password);
      errorMessage = null;
      return true;
    } on Exception catch (error) {
      errorMessage = error.toString();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
    String role = 'user',
  }) async {
    try {
      _setBusy(true);
      final credential = await _authService.registerWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      final firebaseUser = credential.user;
      if (firebaseUser != null) {
        final appUser = AppUser(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? email,
          displayName: firebaseUser.displayName ?? displayName,
          photoUrl: firebaseUser.photoURL,
          groupIds: const [],
          role: role,
          createdAt: DateTime.now(),
        );
        await _userService.createOrUpdateUser(appUser);
      }
      errorMessage = null;
      return true;
    } on Exception catch (error) {
      errorMessage = error.toString();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> adminCreateUser({
    required String email,
    required String password,
    required String displayName,
    required String role,
  }) async {
    try {
      _setBusy(true);
      final credential = await _authService.adminCreateUserWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      final firebaseUser = credential.user;
      if (firebaseUser != null) {
        final appUser = AppUser(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? email,
          displayName: firebaseUser.displayName ?? displayName,
          photoUrl: firebaseUser.photoURL,
          groupIds: const [],
          role: role,
          createdAt: DateTime.now(),
        );
        await _userService.createOrUpdateUser(appUser);
      }
      errorMessage = null;
      return true;
    } on Exception catch (error) {
      errorMessage = error.toString();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  void _setBusy(bool value) {
    if (isBusy == value) return;
    isBusy = value;
    notifyListeners();
  }
}
