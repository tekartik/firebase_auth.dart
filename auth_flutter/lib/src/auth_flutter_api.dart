import 'package:tekartik_firebase_auth/auth.dart';

abstract class AuthFlutter {
  Future<User> googleSignIn();
}

abstract class AuthServiceFlutter implements AuthService {}
