/// The set of properties used to create a new user, passed to
/// [FirebaseAuthAdmin.createUser].
///
/// All properties are optional; omitting one leaves the corresponding value
/// unset (or backend-default) on the created user.
abstract class FirebaseAuthCreateUserRequest {
  /// The uid to assign to the new user, or `null` to let the backend
  /// generate one automatically.
  String? get uid;

  /// Whether the new user should be created disabled (`true`) or enabled
  /// (`false`/`null`). A disabled user cannot sign in.
  bool? get disabled;

  /// The display name to set on the new user, or `null` to leave it unset.
  String? get displayName;

  /// The primary email to set on the new user, or `null` to leave it unset.
  String? get email;

  /// Whether the primary [email] should be marked as verified (`true`) or
  /// not (`false`/`null`).
  bool? get emailVerified;

  /// The unhashed password to set for the new user, or `null` to create the
  /// user without a password (for example for providers other than
  /// email/password).
  String? get password;

  /// The primary phone number to set on the new user, or `null` to leave it
  /// unset.
  String? get phoneNumber;

  /// The photo URL to set on the new user, or `null` to leave it unset.
  String? get photoURL;

  /// Creates an immutable [FirebaseAuthCreateUserRequest] from the given
  /// field values. See the corresponding getters for the meaning of each
  /// parameter; all of them are optional and default to unset.
  factory FirebaseAuthCreateUserRequest({
    String? uid,
    bool? disabled,
    String? displayName,
    String? email,
    bool? emailVerified,
    String? password,
    String? phoneNumber,
    String? photoURL,
  }) {
    return _CreateUserRequest(
      uid: uid,
      disabled: disabled,
      displayName: displayName,
      email: email,
      emailVerified: emailVerified,
      password: password,
      phoneNumber: phoneNumber,
      photoURL: photoURL,
    );
  }
}

class _CreateUserRequest implements FirebaseAuthCreateUserRequest {
  @override
  final String? uid;
  @override
  final bool? disabled;
  @override
  final String? displayName;
  @override
  final String? email;
  @override
  final bool? emailVerified;
  @override
  final String? password;
  @override
  final String? phoneNumber;
  @override
  final String? photoURL;

  _CreateUserRequest({
    this.uid,
    this.disabled,
    this.displayName,
    this.email,
    this.emailVerified,
    this.password,
    this.phoneNumber,
    this.photoURL,
  });
}
