import 'package:cv/cv.dart';

/// Init builders
void initAuthSimBuilders() {
  cvAddConstructors([
    UserSetRequest.new,
    UserGetRequest.new,
    UserGetByEmailRequest.new,
    UserGetResponse.new,
    UserSignInEmailPasswordRequest.new,
    UserSignInAnonymouslyRequest.new,
    UserSignOutRequest.new,
  ]);
}

/// User in subscription
const paramUserRecord = 'user';

/// Auth user set
const methodAuthUserSet = 'auth/user/set';

/// Auth user delete
const methodAuthUserDelete = 'auth/user/delete';

/// Auth user get
const methodAuthUserGet = 'auth/user/get';

/// Auth user get by email
const methodAuthUserGetByEmail = 'auth/get_by_email';

/// Auth user get listen
const methodAuthUserGetListen = 'auth/get/listen'; // first query then next
/// Auth user get stream
const methodAuthUserGetStream = 'auth/get/stream'; // next query
/// Cancel get
const methodAuthUserGetCancel = 'auth/get/cancel'; // query and notification

/// Signin email password
const methodAuthSignInEmailPassword = 'auth/sign_in/email_password';

/// Signin anonymously
const methodAuthSignInAnonymously = 'auth/sign_in/anonymous';

/// Signout sign out
const methodAuthSignOut = 'auth/sign_out';

/// User sign in email password
class UserSignInEmailPasswordRequest extends CvModelBase {
  /// email
  final email = CvField<String>('email');

  /// password
  final password = CvField<String>('password');

  @override
  CvFields get fields => [email, password];
}

/// User sign in email password
class UserSignInAnonymouslyRequest extends CvModelBase {
  @override
  CvFields get fields => [];
}

/// User sign in email password
class UserSignOutRequest extends CvModelBase {
  /// optional userId
  final userId = CvField<String>('userId');

  @override
  CvFields get fields => [userId];
}

/// getUser/getUserStream
class UserGetRequest extends CvModelBase {
  /// User id
  final userId = CvField<String>('userId');

  @override
  CvFields get fields => [userId];
}

/// getUserByEmail
class UserGetByEmailRequest extends CvModelBase {
  /// User email
  final email = CvField<String>('email');

  @override
  CvFields get fields => [email];
}

/// setUser
class UserSetRequest extends UserGetResponse {
  @override
  CvFields get fields => [...super.fields];
}

/// getUser response
class UserGetResponse extends CvModelBase {
  /// User id
  final userId = CvField<String>('userId');

  /// User email
  final email = CvField<String>('email');

  /// User anonymous
  final anonymous = CvField<bool>('anonymous');

  /// Email verified
  final emailVerified = CvField<bool>('emailVerified');

  /// name
  final name = CvField<String>('name');

  @override
  CvFields get fields => [userId, email, anonymous, emailVerified, name];
}
