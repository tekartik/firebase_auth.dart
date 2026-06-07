import 'package:tekartik_firebase_auth/auth_mixin.dart';

/// Admin mode
/// To remove
abstract class FirebaseAuthLocalAdmin
    implements FirebaseAuth, FirebaseAuthAdmin {
  /// Set/Create user
  Future<void> setUser(
    String uid, {
    String? email,
    bool? isAnonymous,
    bool? emailVerified,
  });

  /// User record stream
  Stream<UserRecord?> onUserRecord(String uid);

  /// Do not sign in but get the credentials
  Future<UserCredential> getSignInWithEmailAndPasswordUserCredential({
    required String email,
    required String password,
  });

  /// Do not sign in but get the credentials
  Future<UserCredential> getSignInAnonymouslyUserCredential();
}

/// Firebase Auth Admin interface.
abstract class FirebaseAuthAdmin implements FirebaseAuth {
  /// Create user.
  Future<UserRecord> createUser(FirebaseAuthCreateUserRequest request);

  /// Get user by uid.
  @override
  Future<UserRecord?> getUser(String uid);

  /// Get user by email.
  @override
  Future<UserRecord?> getUserByEmail(String email);

  /// Delete user
  Future<void> deleteUser(String uid);
}
