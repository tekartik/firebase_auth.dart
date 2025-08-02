import 'package:tekartik_firebase_auth/auth_mixin.dart';

/// Admin mode
abstract class FirebaseAuthLocalAdmin implements FirebaseAuth {
  /// Set/Create user
  Future<void> setUser(
    String uid, {
    String? email,
    bool? isAnonymous,
    bool? emailVerified,
  });

  /// Delete user
  Future<void> deleteUser(String uid);

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
