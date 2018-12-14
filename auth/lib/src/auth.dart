
import 'package:tekartik_firebase/firebase.dart';

abstract class AuthService {
  // true if it supports listing users
  bool get supportsListUsers;

  Auth auth(App app);
}

/// Represents a Auth Database and is the entry point for all
/// Auth operations.
abstract class Auth {
  /// Retrieves a list of users (single batch only) with a size of [maxResults]
  /// and starting from the offset as specified by [pageToken].
  ///
  /// This is used to retrieve all the users of a specified project in batches.
  Future<ListUsersResult> listUsers({num maxResults, String pageToken});
}

abstract class UserRecord {
  /// The user's custom claims object if available, typically used to define user
  /// roles and propagated to an authenticated user's ID token.
  ///
  /// This is set via [Auth.setCustomUserClaims].
  get customClaims;

  /// Whether or not the user is disabled: true for disabled; false for enabled.
  bool get disabled;

  /// The user's display name.
  String get displayName;

  /// The user's primary email, if set.
  String get email;

  /// Whether or not the user's primary email is verified.
  bool get emailVerified;

  /// Additional metadata about the user.
  UserMetadata get metadata;

  /// The user’s hashed password (base64-encoded), only if Firebase Auth hashing
  /// algorithm (SCRYPT) is used.
  ///
  /// If a different hashing algorithm had been used when uploading this user,
  /// typical when migrating from another Auth system, this will be an empty
  /// string. If no password is set, this will be`null`.
  ///
  /// This is only available when the user is obtained from [Auth.listUsers].
  String get passwordHash;

  /// The user’s password salt (base64-encoded), only if Firebase Auth hashing
  /// algorithm (SCRYPT) is used.
  ///
  /// If a different hashing algorithm had been used to upload this user, typical
  /// when migrating from another Auth system, this will be an empty string.
  /// If no password is set, this will be `null`.
  ///
  /// This is only available when the user is obtained from [Auth.listUsers].
  String get passwordSalt;

  /// The user's primary phone number or `null`.
  String get phoneNumber;

  /// The user's photo URL or `null`.
  String get photoURL;

  /// An array of providers (for example, Google, Facebook) linked to the user.
  List<UserInfo> get providerData;

  /// The date the user's tokens are valid after, formatted as a UTC string.
  ///
  /// This is updated every time the user's refresh token are revoked either from
  /// the [Auth.revokeRefreshTokens] API or from the Firebase Auth backend on big
  /// account changes (password resets, password or email updates, etc).
  String get tokensValidAfterTime;

  /// The user's uid.
  String get uid;
}

abstract class UserMetadata {
  /// The date the user was created, formatted as a UTC string.
  String get creationTime;

  /// The date the user last signed in, formatted as a UTC string.
  String get lastSignInTime;
}

/// Interface representing a user's info from a third-party identity provider
/// such as Google or Facebook.
abstract class UserInfo {
  /// The display name for the linked provider.
  String get displayName;

  /// The email for the linked provider.
  String get email;

  /// The phone number for the linked provider.
  String get phoneNumber;

  /// The photo URL for the linked provider.
  String get photoURL;

  /// The linked provider ID (for example, "google.com" for the Google provider).
  String get providerId;

  /// The user identifier for the linked provider.
  String get uid;
}

abstract class ListUsersResult {
  String get pageToken;

  List<UserRecord> get users;
}
