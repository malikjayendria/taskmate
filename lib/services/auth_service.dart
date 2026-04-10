import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  FirebaseApp? _adminApp;

  Stream<User?> get userChanges => _auth.userChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(displayName);
    await credential.user?.reload();
    return credential;
  }

  Future<UserCredential> adminCreateUserWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final adminApp = await _ensureAdminApp();
    final adminAuth = FirebaseAuth.instanceFor(app: adminApp);
    final credential = await adminAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(displayName);
    await credential.user?.reload();
    await adminAuth.signOut();
    return credential;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<FirebaseApp> _ensureAdminApp() async {
    if (_adminApp != null) return _adminApp!;
    try {
      _adminApp = Firebase.app('taskmate-admin');
    } on FirebaseException {
      _adminApp = await Firebase.initializeApp(
        name: 'taskmate-admin',
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    return _adminApp!;
  }
}
