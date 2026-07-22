import 'dart:async';

import 'package:tekartik_common_utils/stream/subject.dart';
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth/auth_admin.dart';

/// Deprecated alias for [FirebaseAuthServiceMixin]. New code should
/// reference [FirebaseAuthServiceMixin] directly.
typedef AuthServiceMixin = FirebaseAuthServiceMixin;

/// Marker mixin for [FirebaseAuthService] implementations.
///
/// It does not provide any default member implementation; it exists so
/// concrete service classes across the different backends (REST, Node.js,
/// Flutter, mock) share a common, easily identifiable mixin for tooling and
/// bookkeeping purposes.
mixin FirebaseAuthServiceMixin implements FirebaseAuthService {}

/// Deprecated alias for [FirebaseAuthMixin]. New code should reference
/// [FirebaseAuthMixin] directly.
typedef AuthMixin = FirebaseAuthMixin;

/// Base mixin implementing [FirebaseAuth] for concrete backends.
///
/// It provides the shared bookkeeping for the current-user state
/// ([currentUser], [onCurrentUser], [currentUserAdd], [currentUserClose])
/// backed by a broadcast subject, and a default "unsupported" behavior
/// (throwing [UnsupportedError]) for every other operation, so that
/// concrete implementations only need to override the operations they
/// actually support.
mixin FirebaseAuthMixin
    implements FirebaseAuth, FirebaseAppProduct<FirebaseAuth> {
  final _currentUserSubject = Subject<User?>();

  /// Publishes [user] as the new current user.
  ///
  /// This updates [currentUser] and notifies [onCurrentUser] listeners.
  /// Pass `null` to indicate that no user is currently signed in.
  /// Concrete implementations should call this whenever the signed-in user
  /// changes (sign-in, sign-out, reload, and so on).
  void currentUserAdd(User? user) {
    _currentUserSubject.add(user);
  }

  //void currentUserTokenAdd(String tokenId)

  /// The most recently published current user, or `null` if no user has
  /// been published yet or the last published value was `null` (signed
  /// out). Backed by [currentUserAdd].
  @override
  User? get currentUser => _currentUserSubject.value;

  /// Broadcast stream of current-user changes fed by [currentUserAdd].
  ///
  /// Once at least one value has been published, newly-added listeners
  /// immediately receive the latest known value (which may be `null`).
  @override
  Stream<User?> get onCurrentUser => _currentUserSubject.stream;

  /// Closes the internal current-user stream.
  ///
  /// Call this when disposing of the [FirebaseAuth] instance to release
  /// resources; after this completes, [onCurrentUser] is done and further
  /// calls to [currentUserAdd] are invalid.
  Future<void> currentUserClose() async {
    await _currentUserSubject.close();
  }

  /// {@template tekartik_firebase_auth.auth_mixin.not_supported}
  /// Default implementation, which is not supported by this mixin.
  ///
  /// Concrete classes that support this operation must override this member
  /// to provide the real behavior; as implemented here it always throws an
  /// [UnsupportedError].
  /// {@endtemplate}
  @override
  Future<ListUsersResult> listUsers({int? maxResults, String? pageToken}) {
    throw UnsupportedError('$runtimeType.listUsers not supported');
  }

  /// {@macro tekartik_firebase_auth.auth_mixin.not_supported}
  @override
  Future<UserRecord?> getUser(String uid) {
    throw UnsupportedError('$runtimeType.getUser not supported');
  }

  /// {@macro tekartik_firebase_auth.auth_mixin.not_supported}
  @override
  Future<List<UserRecord>> getUsers(List<String> uids) {
    throw UnsupportedError('$runtimeType.getUsers not supported');
  }

  /// {@macro tekartik_firebase_auth.auth_mixin.not_supported}
  @override
  Future<UserRecord?> getUserByEmail(String email) {
    throw UnsupportedError('$runtimeType.getUserByEmail not supported');
  }

  /// {@macro tekartik_firebase_auth.auth_mixin.not_supported}
  @override
  Future<AuthSignInResult> signIn(
    AuthProvider authProvider, {
    AuthSignInOptions? options,
  }) {
    throw UnsupportedError('$runtimeType.signIn not supported');
  }

  /// {@macro tekartik_firebase_auth.auth_mixin.not_supported}
  @override
  Future signOut() {
    throw UnsupportedError('$runtimeType.signOut not supported');
  }

  /// {@macro tekartik_firebase_auth.auth_mixin.not_supported}
  @override
  Future<DecodedIdToken> verifyIdToken(String idToken, {bool? checkRevoked}) {
    throw UnsupportedError('$runtimeType.verifyIdToken not supported');
  }

  /// {@macro tekartik_firebase_auth.auth_mixin.not_supported}
  @override
  Future<void> sendEmailVerification() {
    throw UnsupportedError('$runtimeType.sendEmailVerification not supported');
  }

  /// {@macro tekartik_firebase_auth.auth_mixin.not_supported}
  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    throw UnsupportedError(
      '$runtimeType.signInWithEmailAndPassword not supported',
    );
  }

  /// {@macro tekartik_firebase_auth.auth_mixin.not_supported}
  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    throw UnimplementedError(
      '$runtimeType.createUserWithEmailAndPassword not supported',
    );
  }

  /// {@macro tekartik_firebase_auth.auth_mixin.not_supported}
  @override
  Future<UserCredential> signInAnonymously() {
    throw UnsupportedError('$runtimeType.signInAnonymously not supported');
  }
}

/// Default, minimal implementation of [User] (a [FirebaseUser]).
///
/// Every identity-related getter defaults to `null`/`false` rather than
/// throwing, so a class using this mixin is usable out of the box as a
/// blank/anonymous-looking user; concrete implementations override the
/// members that should carry real data.
mixin FirebaseUserMixin implements User {
  /// {@template tekartik_firebase_auth.auth_mixin.user_default_null}
  /// Defaults to `null`. Override to provide the actual value.
  /// {@endtemplate}
  @override
  String? get displayName => null;

  /// {@macro tekartik_firebase_auth.auth_mixin.user_default_null}
  @override
  String? get email => null;

  /// Defaults to `false`. Override to provide the actual value.
  @override
  bool get emailVerified => false;

  /// Defaults to `false`. Override to provide the actual value.
  @override
  bool get isAnonymous => false;

  /// {@macro tekartik_firebase_auth.auth_mixin.user_default_null}
  @override
  String? get phoneNumber => null;

  /// {@macro tekartik_firebase_auth.auth_mixin.user_default_null}
  @override
  String? get photoURL => null;

  /// {@macro tekartik_firebase_auth.auth_mixin.user_default_null}
  @override
  String? get providerId => null;

  /// Returns a debug string with [uid] and, when available, [email] or
  /// [displayName].
  @override
  String toString() =>
      'User($uid${email != null ? ', $email' : ((displayName != null) ? ', $displayName' : '')})';

  /// Default implementation which is not supported: always throws an
  /// [UnimplementedError]. Concrete implementations must override this to
  /// provide the real deletion behavior.
  @override
  Future<void> delete() {
    throw UnimplementedError('FirebaseUser $runtimeType.delete');
  }
}

/// Default implementation of [UserCredential].
///
/// [user] is not implemented by default; concrete implementations must
/// override it.
mixin FirebaseUserCredentialMixin implements UserCredential {
  /// Default implementation which is not supported: always throws an
  /// [UnimplementedError]. Concrete implementations must override this to
  /// return the actual signed-in [FirebaseUser].
  @override
  FirebaseUser get user =>
      throw UnimplementedError('FirebaseUserCredential.user');

  /// Returns a debug string with [user] and [credential].
  @override
  String toString() => 'UserCredential($user, $credential)';
}

/// Marker mixin for [FirebaseAuthCredential] implementations.
///
/// It does not provide any default member implementation - in particular
/// [FirebaseAuthCredential.providerId] is not implemented here - so mixing
/// classes must still implement the interface themselves. It exists purely
/// so concrete credential classes share a common, easily identifiable
/// mixin across backends.
mixin FirebaseAuthCredentialMixin implements FirebaseAuthCredential {
  // @override String get providerId => throw UnimplementedError('FirebaseAuthCredential.providerId');
}

/// Default implementation of [UserRecord] where every member other than
/// [UserRecord.uid] throws [UnimplementedError] unless overridden by the
/// concrete backend.
///
/// Unlike [FirebaseUserMixin] (which defaults to harmless empty values),
/// this mixin is meant for backends where accessing an unsupported field is
/// a programming error that should fail loudly; [UserRecord.uid] and
/// [UserRecord.email] are not provided by this mixin and must always be
/// implemented directly by the concrete class.
mixin FirebaseUserRecordDefaultMixin implements UserRecord {
  /// {@template tekartik_firebase_auth.auth_mixin.user_record_not_implemented}
  /// Default implementation which is not supported: always throws an
  /// [UnimplementedError]. Concrete implementations must override this to
  /// provide the actual value.
  /// {@endtemplate}
  @override
  String? get displayName =>
      throw UnimplementedError('FirebaseUserRecord.displayName');

  /// {@macro tekartik_firebase_auth.auth_mixin.user_record_not_implemented}
  @override
  bool get emailVerified =>
      throw UnimplementedError('FirebaseUserRecord.emailVerified');

  /// {@macro tekartik_firebase_auth.auth_mixin.user_record_not_implemented}
  @override
  bool get isAnonymous =>
      throw UnimplementedError('FirebaseUserRecord.isAnonymous');

  /// {@macro tekartik_firebase_auth.auth_mixin.user_record_not_implemented}
  @override
  String? get phoneNumber =>
      throw UnimplementedError('FirebaseUserRecord.phoneNumber');

  /// {@macro tekartik_firebase_auth.auth_mixin.user_record_not_implemented}
  @override
  String? get photoURL =>
      throw UnimplementedError('FirebaseUserRecord.photoURL');

  /// {@macro tekartik_firebase_auth.auth_mixin.user_record_not_implemented}
  @override
  Object? get customClaims =>
      throw UnimplementedError('FirebaseUserRecord.customClaims');

  /// {@macro tekartik_firebase_auth.auth_mixin.user_record_not_implemented}
  @override
  bool get disabled => throw UnimplementedError('FirebaseUserRecord.disabled');

  /// {@macro tekartik_firebase_auth.auth_mixin.user_record_not_implemented}
  @override
  UserMetadata? get metadata =>
      throw UnimplementedError('FirebaseUserRecord.metadata');

  /// {@macro tekartik_firebase_auth.auth_mixin.user_record_not_implemented}
  @override
  String? get passwordHash =>
      throw UnimplementedError('FirebaseUserRecord.passwordHash');

  /// {@macro tekartik_firebase_auth.auth_mixin.user_record_not_implemented}
  @override
  String? get passwordSalt =>
      throw UnimplementedError('FirebaseUserRecord.passwordSalt');

  /// {@macro tekartik_firebase_auth.auth_mixin.user_record_not_implemented}
  @override
  List<UserInfo>? get providerData =>
      throw UnimplementedError('FirebaseUserRecord.providerData');

  /// {@macro tekartik_firebase_auth.auth_mixin.user_record_not_implemented}
  @override
  String? get tokensValidAfterTime =>
      throw UnimplementedError('FirebaseUserRecord.tokensValidAfterTime');

  /// Returns a debug string built from [uid], [email], [displayName],
  /// [isAnonymous] and [emailVerified].
  ///
  /// May throw [UnimplementedError] if [displayName], [isAnonymous] or
  /// [emailVerified] have not been overridden by the concrete
  /// implementation.
  @override
  String toString() =>
      '$uid, $email, $displayName${isAnonymous ? ', anonymous' : ''}, ${emailVerified ? '' : ' email not verified'}';
}

/// Default mixin for [FirebaseAuthAdmin] where every admin operation throws
/// [UnsupportedError] unless overridden, letting a backend that only
/// implements a subset of the admin API mix this in and override just the
/// operations it supports.
mixin FirebaseAuthAdminDefaultMixin implements FirebaseAuthAdmin {
  /// {@template tekartik_firebase_auth.auth_mixin.admin_not_supported}
  /// Default implementation, which is not supported by this mixin.
  ///
  /// Concrete classes that support this operation must override this member
  /// to provide the real behavior; as implemented here it always throws an
  /// [UnsupportedError].
  /// {@endtemplate}
  @override
  Future<UserRecord> createUser(FirebaseAuthCreateUserRequest request) {
    throw UnsupportedError('$runtimeType.createUser not supported');
  }

  /// {@macro tekartik_firebase_auth.auth_mixin.admin_not_supported}
  @override
  Future<UserRecord?> getUser(String uid) {
    throw UnsupportedError('$runtimeType.getUser not supported');
  }

  /// {@macro tekartik_firebase_auth.auth_mixin.admin_not_supported}
  @override
  Future<UserRecord?> getUserByEmail(String email) {
    throw UnsupportedError('$runtimeType.getUserByEmail not supported');
  }

  /// {@macro tekartik_firebase_auth.auth_mixin.admin_not_supported}
  @override
  Future<void> deleteUser(String uid) {
    throw UnsupportedError('$runtimeType.deleteUser not supported');
  }
}

/// Default mixin for [FirebaseAuthLocalAdmin] providing "not implemented"
/// behavior for the two credential-preview operations, letting a backend
/// mix this in and override only the ones it supports.
mixin FirebaseAuthLocalAdminDefaultMixin implements FirebaseAuthLocalAdmin {
  /// Default implementation which is not supported: always throws an
  /// [UnimplementedError]. Concrete implementations must override this to
  /// actually compute the credential without signing in.
  @override
  Future<UserCredential> getSignInAnonymouslyUserCredential() {
    throw UnimplementedError(
      'FirebaseAuthLocalAdmin.getSignInAnonymouslyUserCredential',
    );
  }

  /// Default implementation which is not supported: always throws an
  /// [UnimplementedError]. Concrete implementations must override this to
  /// actually compute the credential without signing in.
  @override
  Future<UserCredential> getSignInWithEmailAndPasswordUserCredential({
    required String email,
    required String password,
  }) {
    throw UnimplementedError(
      'FirebaseAuthLocalAdmin.getSignInWithEmailAndPasswordUserCredential',
    );
  }
}
