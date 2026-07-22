import 'package:tekartik_firebase_auth/auth_mixin.dart';

/// A [FirebaseAuth] implementation that also supports [FirebaseAuthAdmin]
/// and can be driven programmatically without going through a real
/// authentication flow.
///
/// This is primarily meant for local/mock/test backends, letting test code
/// inject arbitrary user state directly with [setUser] and inspect
/// credentials produced by a sign-in flow without actually signing in with
/// [getSignInWithEmailAndPasswordUserCredential] and
/// [getSignInAnonymouslyUserCredential].
abstract class FirebaseAuthLocalAdmin
    implements FirebaseAuth, FirebaseAuthAdmin {
  /// Creates the user identified by [uid] if it does not exist yet, or
  /// updates it in place, setting the given fields.
  ///
  /// [email]: the primary email to set, or `null` to leave it unset.
  /// [isAnonymous]: whether the user should be marked as anonymous; omitting
  /// it leaves the current/default value.
  /// [emailVerified]: whether [email] should be marked as verified; omitting
  /// it leaves the current/default value.
  Future<void> setUser(
    String uid, {
    String? email,
    bool? isAnonymous,
    bool? emailVerified,
  });

  /// A stream of the user record for [uid], emitting a new value whenever it
  /// changes (for example through [setUser]), or `null` while/if the user
  /// does not exist.
  Stream<UserRecord?> onUserRecord(String uid);

  /// Computes the [UserCredential] that would result from signing in with
  /// [email] and [password], creating the user first if it does not exist
  /// yet, but without actually signing the user in (does not affect
  /// [FirebaseAuth.currentUser] or [FirebaseAuth.onCurrentUser]).
  Future<UserCredential> getSignInWithEmailAndPasswordUserCredential({
    required String email,
    required String password,
  });

  /// Computes the [UserCredential] that would result from an anonymous
  /// sign-in, without actually signing the user in (does not affect
  /// [FirebaseAuth.currentUser] or [FirebaseAuth.onCurrentUser]).
  Future<UserCredential> getSignInAnonymouslyUserCredential();
}

/// Convenience extension methods on [FirebaseAuthLocalAdmin].
extension FirebaseAuthLocalAdminExt on FirebaseAuthLocalAdmin {
  /// Gets the user with the given [email], or creates it with [email] and
  /// [password] if it does not exist yet.
  Future<UserRecord> getOrCreateUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    var user = await getUserByEmail(email);
    if (user != null) {
      return user;
    }

    return await createUser(
      FirebaseAuthCreateUserRequest(email: email, password: password),
    );
  }
}

/// Administrative extension of [FirebaseAuth] that can create, look up and
/// delete users directly, without those users signing in themselves.
///
/// Typically only available for trusted/server-side backends (for example
/// the Firebase Admin SDK), unlike the plain [FirebaseAuth] operations which
/// are meant to be safe for client use.
abstract class FirebaseAuthAdmin implements FirebaseAuth {
  /// Creates a new user from the given [request] and returns the resulting
  /// [UserRecord].
  ///
  /// Most implementations throw if a user with the same [request]
  /// [FirebaseAuthCreateUserRequest.uid] or
  /// [FirebaseAuthCreateUserRequest.email] already exists.
  Future<UserRecord> createUser(FirebaseAuthCreateUserRequest request);

  /// Gets the user data for the user corresponding to the given [uid], or
  /// `null` if no such user exists.
  @override
  Future<UserRecord?> getUser(String uid);

  /// Gets the user data for the user corresponding to the given [email], or
  /// `null` if no user has that primary email.
  @override
  Future<UserRecord?> getUserByEmail(String email);

  /// Deletes the user identified by [uid].
  Future<void> deleteUser(String uid);
}

/// Convenience extension methods on [FirebaseAuthAdmin].
extension FirebaseAuthAdminExt on FirebaseAuthAdmin {
  /// Gets or creates a user based on [request].
  ///
  /// If [FirebaseAuthCreateUserRequest.uid] is provided, it tries to get the
  /// user by uid first. If not found (or if no uid was provided), it tries
  /// to get the user by [FirebaseAuthCreateUserRequest.email]. If still not
  /// found, it creates a new user from [request].
  ///
  /// Throws a [StateError] if no matching user is found by uid and
  /// [FirebaseAuthCreateUserRequest.email] is `null`, since an email is
  /// then required to create the user.
  Future<UserRecord> getOrCreateUser(
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
