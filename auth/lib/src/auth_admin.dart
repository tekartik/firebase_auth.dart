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

/// Extension for [FirebaseAuthAdmin].
extension FirebaseAuthAdminExt on FirebaseAuthAdmin {
  /// Get or create a user based on the request.
  ///
  /// If [request.uid] is provided, it tries to get the user by uid first.
  /// If not found or if uid was not provided, it tries to get the user by email.
  /// If still not found, it creates a new user.
  Future<UserRecord?> getOrCreateUser(
    FirebaseAuthCreateUserRequest request,
  ) async {
    var uid = request.uid;
    if (uid != null) {
      var user = await getUser(uid);
      if (user != null) {
        return user;
      }
    }
    var email = request.email;
    if (email == null) {
      throw StateError('Email is required to create user');
    }

    var user = await getUserByEmail(email);
    if (user != null) {
      return user;
    }

    return createUser(request);
  }
}
