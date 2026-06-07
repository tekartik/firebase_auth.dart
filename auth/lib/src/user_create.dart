/// CreateUserRequest class with to create a user record
abstract class FirebaseAuthCreateUserRequest {
  /// The user's `uid`.
  String? get uid;

  /// Whether or not the user is disabled.
  bool? get disabled;

  /// The user's display name.
  String? get displayName;

  /// The user's primary email.
  String? get email;

  /// Whether or not the user's primary email is verified.
  bool? get emailVerified;

  /// The user's unhashed password.
  String? get password;

  /// The user's primary phone number.
  String? get phoneNumber;

  /// The user's photo URL.
  String? get photoURL;

  /// Factory constructor
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
