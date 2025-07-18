import 'dart:async';

import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';

/// To deprecate: Use FirebaseAuthService
typedef AuthService = FirebaseAuthService;

/// To deprecate: Use FirebaseAuthService
typedef Auth = FirebaseAuth;

/// Represents a Firebase Auth service.
abstract class FirebaseAuthService implements FirebaseProductService {
  /// true if it supports listing and finding users
  bool get supportsListUsers;

  /// true if it supports the current user
  bool get supportsCurrentUser;

  /// Creates/get a [FirebaseAuth] instance.
  FirebaseAuth auth(App app);
}

/// Represents an auth provider.
///
/// See: <https://firebase.google.com/docs/reference/js/firebase.auth.AuthProvider>.
abstract class AuthProvider {
  /// Provider id.
  String get providerId;
}

/// Abstract sign in options, per provider.
abstract class AuthSignInOptions {}

/// Sign in result;
abstract class AuthSignInResult {
  /// If true, especially during redirect, we have no clue of what is going on...
  bool get hasInfo;

  /// The credentials if any. null might not mean failure if [hasInfo] is true
  UserCredential? get credential;
}

/// Represents a Auth Database and is the entry point for all
/// Auth operations.
abstract class FirebaseAuth implements FirebaseAppProduct<FirebaseAuth> {
  /// Retrieves a list of users (single batch only) with a size of [maxResults]
  /// and starting from the offset as specified by [pageToken].
  ///
  /// This is used to retrieve all the users of a specified project in batches.
  Future<ListUsersResult> listUsers({int? maxResults, String? pageToken});

  /// Gets the user data for the user corresponding to a given [email].
  Future<UserRecord?> getUserByEmail(String email);

  /// Gets the user data for the user corresponding to a given [uid].
  Future<UserRecord?> getUser(String uid);

  /// Gets the user data for all the users.
  Future<List<UserRecord>> getUsers(List<String> uids);

  /// only if [FirebaseAuthService.supportsCurrentUser] is true
  User? get currentUser;

  /// Reload user (needed after email verification)
  Future<FirebaseUser?> reloadCurrentUser();

  /// Current user stream.
  ///
  /// It also trigger upon start when the current user is ready (can be null if
  /// none)
  Stream<FirebaseUser?> get onCurrentUser;

  /// only if [FirebaseAuthService.supportsCurrentUser] is true.
  ///
  /// Credential can be null and the login happen later
  Future<AuthSignInResult> signIn(
    AuthProvider authProvider, {
    AuthSignInOptions? options,
  });

  /// Signs out the current user.
  Future signOut();

  /// Attempts to sign in a user with the given email address and password.
  ///
  /// If successful, it also signs the user in into the app and updates
  /// any [authStateChanges], [idTokenChanges] or [userChanges] stream
  /// listeners.
  ///
  /// **Important**: You must enable Email & Password accounts in the Auth
  /// section of the Firebase console before being able to use them.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
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

  /// Asynchronously creates and becomes an anonymous user.
  ///
  /// If there is already an anonymous user signed in, that user will be
  /// returned instead. If there is any other existing user signed in, that
  /// user will be signed out.
  ///
  /// **Important**: You must enable Anonymous accounts in the Auth section
  /// of the Firebase console before being able to use them.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **operation-not-allowed**:
  ///  - Thrown if anonymous accounts are not enabled. Enable anonymous accounts
  /// in the Firebase Console, under the Auth tab.
  Future<UserCredential> signInAnonymously();

  /// Verifies a Firebase ID token (JWT).
  ///
  /// If the token is valid, the returned [Future] is completed with an instance
  /// of [DecodedIdToken]; otherwise, the future is completed with an error.
  /// An optional flag can be passed to additionally check whether the ID token
  /// was revoked.
  Future<DecodedIdToken> verifyIdToken(String idToken, {bool? checkRevoked});

  /// Default Firebase Auth instance.
  static FirebaseAuth get instance =>
      (FirebaseApp.instance as FirebaseAppMixin).getProduct<FirebaseAuth>()!;

  /// Service access
  FirebaseAuthService get service;
}

/// Represents a Firebase user record
abstract class UserRecord {
  /// The user's custom claims object if available, typically used to define user
  /// roles and propagated to an authenticated user's ID token.
  ///
  /// This is set via [FirebaseAuth.setCustomUserClaims].
  Object? get customClaims;

  /// Whether or not the user is disabled: true for disabled; false for enabled.
  bool get disabled;

  /// The user's display name.
  String? get displayName;

  /// The user's primary email, if set.
  String? get email;

  /// Whether or not the user's primary email is verified.
  bool get emailVerified;

  /// Additional metadata about the user.
  UserMetadata? get metadata;

  /// True for anonymous
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

  /// The user's primary phone number or `null`.
  String? get phoneNumber;

  /// The user's photo URL or `null`.
  String? get photoURL;

  /// An array of providers (for example, Google, Facebook) linked to the user.
  List<UserInfo>? get providerData;

  /// The date the user's tokens are valid after, formatted as a UTC string.
  ///
  /// This is updated every time the user's refresh token are revoked either from
  /// the [FirebaseAuth.revokeRefreshTokens] API or from the Firebase Auth backend on big
  /// account changes (password resets, password or email updates, etc).
  String? get tokensValidAfterTime;

  /// The user's uid.
  String get uid;
}

/// Additional metadata about the user.
abstract class UserMetadata {
  /// The date the user was created, formatted as a UTC string.
  String get creationTime;

  /// The date the user last signed in, formatted as a UTC string.
  String get lastSignInTime;
}

/// Compat
typedef UserInfo = FirebaseUserInfo;

/// Interface representing a user's info from a third-party identity provider
/// such as Google or Facebook.
abstract class FirebaseUserInfo {
  /// The display name for the linked provider.
  String? get displayName;

  /// The email for the linked provider.
  String? get email;

  /// The phone number for the linked provider.
  String? get phoneNumber;

  /// The photo URL for the linked provider.
  String? get photoURL;

  /// The linked provider ID (for example, 'google.com' for the Google provider).
  String? get providerId;

  /// The user identifier for the linked provider.
  String get uid;
}

/// Compat
typedef User = FirebaseUser;

/// User account.
///
/// See: <https://firebase.google.com/docs/reference/js/firebase.User>.
abstract class FirebaseUser extends UserInfo {
  /// If the user's email address has been already verified.
  bool get emailVerified;

  /// If the user is anonymous.
  bool get isAnonymous;
}

/// Compat
typedef AuthCredential = FirebaseAuthCredential;

/// Represents the credentials returned by an auth provider.
/// Implementations specify the details about each auth provider's credential
/// requirements.
///
/// See: <https://firebase.google.com/docs/reference/js/firebase.auth.AuthCredential>.
abstract class FirebaseAuthCredential {
  /// The authentication provider ID for the credential.
  String get providerId;
}

/// A structure containing a [User], an [AuthCredential] and [operationType].
/// operationType could be 'signIn' for a sign-in operation, 'link' for a
/// linking operation and 'reauthenticate' for a reauthentication operation.
///
/// See: <https://firebase.google.com/docs/reference/js/firebase.auth#.UserCredential>
abstract class UserCredential {
  /// Returns the user.
  User get user;

  /// Returns the auth credential.
  AuthCredential get credential;
}

/// Client interface.
abstract class UserInfoWithIdToken {
  /// Get the auth token
  Future<String> getIdToken({bool? forceRefresh});
}

/// User list result
abstract class ListUsersResult {
  /// to use for next page token
  String get pageToken;

  /// The user list, some items can be null
  List<UserRecord?> get users;
}

/// Interface representing a decoded Firebase ID token, returned from the
/// [FirebaseAuth.verifyIdToken] method.
abstract class DecodedIdToken {
  /// The uid corresponding to the user who the ID token belonged to.
  String get uid;
}
