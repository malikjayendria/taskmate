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
  StreamSubscription<AppUser?>? _userProfileSubscription;

  bool get isAdmin => currentUser?.role == 'admin';

  void initialize() {
    _authSubscription ??= _authService.userChanges.listen((firebaseUser) {
      if (firebaseUser == null) {
        currentUser = null;
        _userProfileSubscription?.cancel();
        _userProfileSubscription = null;
        notifyListeners();
        return;
      }
      _listenToProfile(firebaseUser.uid);
    });
  }

  void _listenToProfile(String uid) {
    _userProfileSubscription?.cancel();
    _userProfileSubscription = _userService.listenToUser(uid).listen((appUser) {
      if (appUser != null) {
        currentUser = appUser;
      } else {
        _createInitialProfile(uid);
      }
      notifyListeners();
    });
  }

  Future<void> _createInitialProfile(String uid) async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser == null) return;

    final newUser = AppUser(
      uid: uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? '',
      photoUrl: firebaseUser.photoURL,
      groupIds: const [],
      role: 'user',
      createdAt: DateTime.now(),
    );
    await _userService.createOrUpdateUser(newUser);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userProfileSubscription?.cancel();
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
