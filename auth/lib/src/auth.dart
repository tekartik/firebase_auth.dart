import 'dart:async';

import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';

/// Deprecated alias for [FirebaseAuthService]. New code should reference
/// [FirebaseAuthService] directly.
typedef AuthService = FirebaseAuthService;

/// Deprecated alias for [FirebaseAuth]. New code should reference
/// [FirebaseAuth] directly.
typedef Auth = FirebaseAuth;

/// Represents a Firebase Auth service, i.e. the product-level object that
/// creates and owns [FirebaseAuth] instances for each [App].
///
/// A concrete [FirebaseAuthService] typically corresponds to one backend
/// (REST, Node.js, Flutter, mock/local) and is registered once per process;
/// use [auth] to obtain the [FirebaseAuth] instance bound to a given [App].
abstract class FirebaseAuthService implements FirebaseProductService {
  /// Whether this service implementation supports listing users
  /// ([FirebaseAuth.listUsers], [FirebaseAuth.getUsers]) and looking users
  /// up by email or uid.
  ///
  /// When `false`, calling those members on the [FirebaseAuth] instances it
  /// creates typically throws (most implementations throw
  /// [UnsupportedError]).
  bool get supportsListUsers;

  /// Whether this service implementation tracks a signed-in
  /// [FirebaseAuth.currentUser] and exposes it through
  /// [FirebaseAuth.onCurrentUser].
  ///
  /// When `false`, [FirebaseAuth.currentUser] and [FirebaseAuth.onCurrentUser]
  /// are not meaningful for the instances it creates.
  bool get supportsCurrentUser;

  /// Returns the [FirebaseAuth] instance for [app], creating it on first
  /// access and reusing the same instance on subsequent calls for the same
  /// [app].
  FirebaseAuth auth(App app);
}

/// Represents an identity provider (for example Google, Facebook or
/// email/password) that can be used with [FirebaseAuth.signIn].
///
/// See: <https://firebase.google.com/docs/reference/js/firebase.auth.AuthProvider>.
abstract class AuthProvider {
  /// The provider identifier (for example `'google.com'` or `'password'`)
  /// as defined by the underlying Firebase Auth provider.
  String get providerId;
}

/// Base type for provider-specific sign-in options passed to
/// [FirebaseAuth.signIn].
///
/// This interface has no members of its own; each [AuthProvider]
/// implementation defines its own concrete subclass carrying the options
/// relevant to that provider (scopes, custom parameters, and so on).
abstract class AuthSignInOptions {}

/// The outcome of a [FirebaseAuth.signIn] call.
abstract class AuthSignInResult {
  /// Whether this result carries meaningful information about the sign-in
  /// outcome.
  ///
  /// Some sign-in flows (typically redirect-based ones) return control to
  /// the app before the actual result is known; in that case [hasInfo] is
  /// `false` and [credential] being `null` does not indicate failure - the
  /// real outcome will arrive later, for example through
  /// [FirebaseAuth.onCurrentUser].
  bool get hasInfo;

  /// The resulting credential, if the sign-in completed with one.
  ///
  /// May be `null` even on success; in particular a `null` value does not
  /// necessarily mean failure when [hasInfo] is `true`.
  UserCredential? get credential;
}

/// Represents a Firebase Auth database and is the entry point for all
/// Auth operations for a given [App].
///
/// Obtain an instance through [FirebaseAuthService.auth],
/// [TekartikFirebaseAuthFirebaseAppExt.auth] or the [instance] shortcut.
abstract class FirebaseAuth implements FirebaseAppProduct<FirebaseAuth> {
  /// Retrieves a single batch of users of up to [maxResults] users, starting
  /// after the offset represented by [pageToken].
  ///
  /// [maxResults]: the maximum number of users to return in this batch. If
  /// omitted, an implementation-defined default batch size is used.
  ///
  /// [pageToken]: the [ListUsersResult.pageToken] returned by a previous
  /// call, used to fetch the next batch. If omitted, the first batch is
  /// returned.
  ///
  /// Call this repeatedly, passing the returned [ListUsersResult.pageToken]
  /// back in, until it is `null`, to iterate over all the users of the
  /// project in batches.
  ///
  /// Only supported when [FirebaseAuthService.supportsListUsers] is `true`;
  /// most implementations throw [UnsupportedError] otherwise.
  Future<ListUsersResult> listUsers({int? maxResults, String? pageToken});

  /// Gets the user data for the user corresponding to the given [email], or
  /// `null` if no user has that primary email.
  ///
  /// Only supported when [FirebaseAuthService.supportsListUsers] is `true`;
  /// most implementations throw [UnsupportedError] otherwise.
  Future<UserRecord?> getUserByEmail(String email);

  /// Gets the user data for the user corresponding to the given [uid], or
  /// `null` if no such user exists.
  ///
  /// Only supported when [FirebaseAuthService.supportsListUsers] is `true`;
  /// most implementations throw [UnsupportedError] otherwise.
  Future<UserRecord?> getUser(String uid);

  /// Gets the user data for all the users identified by [uids].
  ///
  /// Users that cannot be found are typically omitted from the result, so
  /// the returned list may be shorter than [uids].
  ///
  /// Only supported when [FirebaseAuthService.supportsListUsers] is `true`;
  /// most implementations throw [UnsupportedError] otherwise.
  Future<List<UserRecord>> getUsers(List<String> uids);

  /// The currently signed-in user, or `null` if no user is signed in or the
  /// current user has not been resolved yet.
  ///
  /// Only meaningful when [FirebaseAuthService.supportsCurrentUser] is
  /// `true`; otherwise it is always `null`. Use [onCurrentUser] to be
  /// notified when this value changes.
  User? get currentUser;

  /// Reloads the current user's data from the backend and returns it.
  ///
  /// Needed to observe server-side changes to the current user, such as
  /// after email verification. Returns `null` if there is no current user.
  Future<FirebaseUser?> reloadCurrentUser();

  /// A stream of the current user, emitting a new value each time the
  /// signed-in user changes (including sign-in, sign-out and, for some
  /// implementations, token refresh).
  ///
  /// Newly-added listeners also immediately receive the current value once
  /// it is known, which can be `null` if no user is signed in.
  ///
  /// Only meaningful when [FirebaseAuthService.supportsCurrentUser] is
  /// `true`.
  Stream<FirebaseUser?> get onCurrentUser;

  /// Starts a sign-in flow with [authProvider], optionally configured with
  /// provider-specific [options].
  ///
  /// Only supported when [FirebaseAuthService.supportsCurrentUser] is
  /// `true`.
  ///
  /// The returned [AuthSignInResult.credential] can be `null` even on
  /// success - for example during a redirect-based flow the actual sign-in
  /// may complete later and be observed through [onCurrentUser]; check
  /// [AuthSignInResult.hasInfo] to know whether the result is meaningful.
  Future<AuthSignInResult> signIn(
    AuthProvider authProvider, {
    AuthSignInOptions? options,
  });

  /// Signs out the current user.
  ///
  /// After this completes, [currentUser] is `null` and [onCurrentUser]
  /// emits `null`.
  Future signOut();

  /// Attempts to sign in a user with the given [email] address and
  /// [password].
  ///
  /// If successful, it also signs the user in into the app, updates
  /// [currentUser] and notifies [onCurrentUser] listeners, and completes
  /// with a [UserCredential] describing the signed-in user.
  ///
  /// **Important**: You must enable Email & Password accounts in the Auth
  /// section of the Firebase console before being able to use them.
  ///
  /// A `FirebaseAuthException` maybe thrown with the following error code:
  /// - **invalid-email**:
  ///  - Thrown if the email address is not valid.
  /// - **user-disabled**:
  ///  - Thrown if the user corresponding to the given email has been disabled.
  /// - **user-not-found**:
  ///  - Thrown if there is no user corresponding to the given email.
  /// - **wrong-password**:
  ///  - Thrown if the password is invalid for the given email, or the account
  ///    corresponding to the email does not have a password set.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Tries to create a new user account with the given [email] address and
  /// [password], and signs that user in on success.
  ///
  /// Completes with a [UserCredential] for the newly created user.
  ///
  /// A `FirebaseAuthException` maybe thrown with the following error code:
  /// - **email-already-in-use**:
  ///  - Thrown if there already exists an account with the given email address.
  /// - **invalid-email**:
  ///  - Thrown if the email address is not valid.
  /// - **operation-not-allowed**:
  ///  - Thrown if email/password accounts are not enabled. Enable
  ///    email/password accounts in the Firebase Console, under the Auth tab.
  /// - **weak-password**:
  ///  - Thrown if the password is not strong enough.
  /// - **too-many-requests**:
  ///  - Thrown if the user sent too many requests at the same time, for security
  ///     the api will not allow too many attempts at the same time, user will have
  ///     to wait for some time
  /// - **user-token-expired**:
  ///  - Thrown if the user is no longer authenticated since his refresh token
  ///    has been expired
  /// - **network-request-failed**:
  ///  - Thrown if there was a network request error, for example the user
  ///    doesn't have internet connection
  /// - **operation-not-allowed**:
  ///  - Thrown if email/password accounts are not enabled. Enable
  ///    email/password accounts in the Firebase Console, under the Auth tab.
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Asynchronously creates and becomes an anonymous user.
  ///
  /// If there is already an anonymous user signed in, that user will be
  /// returned instead. If there is any other existing user signed in, that
  /// user will be signed out.
  ///
  /// **Important**: You must enable Anonymous accounts in the Auth section
  /// of the Firebase console before being able to use them.
  ///
  /// A `FirebaseAuthException` maybe thrown with the following error code:
  /// - **operation-not-allowed**:
  ///  - Thrown if anonymous accounts are not enabled. Enable anonymous accounts
  /// in the Firebase Console, under the Auth tab.
  Future<UserCredential> signInAnonymously();

  /// Verifies a Firebase ID token (JWT) [idToken].
  ///
  /// If [checkRevoked] is `true`, the token is additionally checked against
  /// the backend to make sure it has not been revoked (for example after a
  /// password change or a call to revoke refresh tokens); omitting it or
  /// passing `false` skips that extra check.
  ///
  /// If the token is valid, the returned [Future] is completed with an
  /// instance of [DecodedIdToken]; otherwise, the future completes with an
  /// error.
  Future<DecodedIdToken> verifyIdToken(String idToken, {bool? checkRevoked});

  /// Sends a verification email to the [currentUser].
  ///
  /// Most implementations require a signed-in user and throw if
  /// [currentUser] is `null`.
  Future<void> sendEmailVerification();

  /// The default [FirebaseAuth] instance, bound to [FirebaseApp.instance].
  ///
  /// Throws if there is no default [App] or if no [FirebaseAuth] product has
  /// been registered on it.
  static FirebaseAuth get instance =>
      (FirebaseApp.instance as FirebaseAppMixin).getProduct<FirebaseAuth>()!;

  /// The [FirebaseAuthService] that created this instance.
  FirebaseAuthService get service;
}

/// Represents a Firebase user record as returned by admin-level lookups such
/// as [FirebaseAuth.getUser], [FirebaseAuth.getUserByEmail],
/// [FirebaseAuth.getUsers] and [FirebaseAuth.listUsers].
abstract class UserRecord {
  /// The user's custom claims object, if any custom claims have been set on
  /// this user, typically used to define user roles and propagated to an
  /// authenticated user's ID token. `null` if none have been set.
  Object? get customClaims;

  /// Whether or not the user is disabled: `true` for disabled; `false` for
  /// enabled. A disabled user cannot sign in.
  bool get disabled;

  /// The user's display name, or `null` if none is set.
  String? get displayName;

  /// The user's primary email, or `null` if none is set.
  String? get email;

  /// Whether or not the user's primary email is verified.
  bool get emailVerified;

  /// Additional metadata about the user (creation and last sign-in time), or
  /// `null` if not available.
  UserMetadata? get metadata;

  /// `true` if this is an anonymous user, `false` otherwise.
  bool get isAnonymous;

  /// The user’s hashed password (base64-encoded), only if Firebase Auth hashing
  /// algorithm (SCRYPT) is used.
  ///
  /// If a different hashing algorithm had been used when uploading this user,
  /// typical when migrating from another Auth system, this will be an empty
  /// string. If no password is set, this will be`null`.
  ///
  /// This is only available when the user is obtained from [FirebaseAuth.listUsers].
  String? get passwordHash;

  /// The user’s password salt (base64-encoded), only if Firebase Auth hashing
  /// algorithm (SCRYPT) is used.
  ///
  /// If a different hashing algorithm had been used to upload this user, typical
  /// when migrating from another Auth system, this will be an empty string.
  /// If no password is set, this will be `null`.
  ///
  /// This is only available when the user is obtained from [FirebaseAuth.listUsers].
  String? get passwordSalt;

  /// The user's primary phone number, or `null` if none is set.
  String? get phoneNumber;

  /// The user's photo URL, or `null` if none is set.
  String? get photoURL;

  /// The linked identity providers (for example, Google, Facebook) for this
  /// user, or `null` if not available.
  List<UserInfo>? get providerData;

  /// The date the user's tokens are valid after, formatted as a UTC string,
  /// or `null` if not available.
  ///
  /// This is updated every time the user's refresh tokens are revoked,
  /// either through the backend admin API or as a result of major account
  /// changes (password resets, password or email updates, etc). Tokens
  /// issued before this date should be considered invalid.
  String? get tokensValidAfterTime;

  /// The user's unique identifier.
  String get uid;
}

/// Additional metadata about a [UserRecord], such as account timestamps.
abstract class UserMetadata {
  /// The date the user was created, formatted as a UTC string.
  String get creationTime;

  /// The date the user last signed in, formatted as a UTC string.
  String get lastSignInTime;
}

/// Deprecated alias for [FirebaseUserInfo]. New code should reference
/// [FirebaseUserInfo] directly.
typedef UserInfo = FirebaseUserInfo;

/// Interface representing a user's info from a third-party identity provider
/// such as Google or Facebook.
///
/// [FirebaseUser] extends this with sign-in specific members; a
/// [UserRecord]'s [UserRecord.providerData] is a list of these.
abstract class FirebaseUserInfo {
  /// The display name for the linked provider, or `null` if none is set.
  String? get displayName;

  /// The email for the linked provider, or `null` if none is set.
  String? get email;

  /// The phone number for the linked provider, or `null` if none is set.
  String? get phoneNumber;

  /// The photo URL for the linked provider, or `null` if none is set.
  String? get photoURL;

  /// The linked provider ID (for example, `'google.com'` for the Google
  /// provider), or `null` if not available.
  String? get providerId;

  /// The user identifier for the linked provider.
  String get uid;
}

/// Deprecated alias for [FirebaseUser]. New code should reference
/// [FirebaseUser] directly.
typedef User = FirebaseUser;

/// A signed-in user account, as returned by sign-in and current-user
/// operations such as [FirebaseAuth.currentUser], [FirebaseAuth.onCurrentUser]
/// and [UserCredential.user].
///
/// See: <https://firebase.google.com/docs/reference/js/firebase.User>.
abstract class FirebaseUser extends UserInfo {
  /// Whether the user's email address has already been verified.
  bool get emailVerified;

  /// Whether this is an anonymous user (created through
  /// [FirebaseAuth.signInAnonymously]).
  bool get isAnonymous;

  /// Deletes and signs out the user.
  ///
  /// **Important**: this is a security-sensitive operation that requires the
  /// user to have recently signed in. If this requirement isn't met, most
  /// implementations require the user to authenticate again before this can
  /// succeed.
  ///
  /// A `FirebaseAuthException` maybe thrown with the following error code:
  /// - **requires-recent-login**:
  ///  - Thrown if the user's last sign-in time does not meet the security
  ///    threshold. This does not apply if the user is anonymous.
  Future<void> delete();
}

/// Deprecated alias for [FirebaseAuthCredential]. New code should reference
/// [FirebaseAuthCredential] directly.
typedef AuthCredential = FirebaseAuthCredential;

/// Represents the credentials returned by an auth provider.
/// Implementations specify the details about each auth provider's credential
/// requirements.
///
/// See: <https://firebase.google.com/docs/reference/js/firebase.auth.AuthCredential>.
abstract class FirebaseAuthCredential {
  /// The authentication provider ID for the credential (for example
  /// `'password'` or `'google.com'`).
  String get providerId;
}

/// The successful outcome of a sign-in, link, or re-authentication
/// operation, pairing the resulting [user] with the [credential] that was
/// used.
///
/// See: <https://firebase.google.com/docs/reference/js/firebase.auth#.UserCredential>
abstract class UserCredential {
  /// The user that signed in, was linked, or was re-authenticated.
  User get user;

  /// The auth credential used for this operation.
  AuthCredential get credential;
}

/// Interface for clients that can produce a Firebase ID token, typically
/// implemented alongside [FirebaseUser] by client-side backends.
abstract class UserInfoWithIdToken {
  /// Gets the current user's Firebase ID token.
  ///
  /// If [forceRefresh] is `true`, forces a refresh of the token regardless
  /// of expiration; otherwise the cached token is reused when it is still
  /// valid. Omitting [forceRefresh] behaves as `false`.
  ///
  /// Completes with the ID token string, or with an error if the token
  /// could not be retrieved (for example if the user is signed out).
  Future<String> getIdToken({bool? forceRefresh});
}

/// A single batch of results from [FirebaseAuth.listUsers].
abstract class ListUsersResult {
  /// The token to pass as `pageToken` to [FirebaseAuth.listUsers] to fetch
  /// the next batch, or `null` if this was the last batch.
  String? get pageToken;

  /// The users in this batch. Individual entries can be `null` if a user
  /// could not be resolved.
  List<UserRecord?> get users;

  /// Creates an immutable [ListUsersResult] with the given [pageToken] and
  /// [users].
  factory ListUsersResult({
    String? pageToken,
    required List<UserRecord?> users,
  }) {
    return _ListUsersResult(pageToken: pageToken, users: users);
  }
}

class _ListUsersResult implements ListUsersResult {
  @override
  final String? pageToken;

  @override
  final List<UserRecord?> users;

  _ListUsersResult({required this.pageToken, required this.users});
}

/// Interface representing a decoded Firebase ID token, returned from the
/// [FirebaseAuth.verifyIdToken] method.
abstract class DecodedIdToken {
  /// The uid corresponding to the user who the ID token belonged to.
  String get uid;
}

/// Convenience extension methods on [FirebaseAuth].
extension TekartikFirebaseAuthExt on FirebaseAuth {
  /// Signs in with [email] and [password] via
  /// [FirebaseAuth.signInWithEmailAndPassword]; if that fails (for example
  /// because the account does not exist yet) falls back to creating the
  /// account via [FirebaseAuth.createUserWithEmailAndPassword].
  ///
  /// Completes with the resulting [UserCredential], and leaves the user
  /// signed in either way.
  Future<UserCredential> signInOrUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      var credential = await signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } catch (e) {
      return await createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    }
  }

  /// Signs in with [email] and [password], creating the account first via
  /// [FirebaseAuth.createUserWithEmailAndPassword] if signing in fails.
  ///
  /// Unlike [signInOrUpWithEmailAndPassword], this implementation signs the
  /// user back out ([FirebaseAuth.signOut]) before returning, so it never
  /// leaves a user signed in; it is meant for callers that only need the
  /// resulting [FirebaseUser] record, not an active session.
  Future<FirebaseUser> getOrCreateUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    UserCredential userCredential;
    try {
      userCredential = await signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (_) {
      userCredential = await createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    }
    await signOut();
    return userCredential.user;
  }
}

/// Convenience extension for accessing the [FirebaseAuth] product of a
/// [FirebaseApp].
extension TekartikFirebaseAuthFirebaseAppExt on FirebaseApp {
  /// Returns the [FirebaseAuth] product registered on this app.
  ///
  /// Throws a [StateError] if no auth product has been registered for this
  /// app.
  FirebaseAuth auth() {
    var auth = getProduct<FirebaseAuth>();
    if (auth == null) {
      throw StateError('No auth product for app $name');
    } else {
      return auth;
    }
  }
}
