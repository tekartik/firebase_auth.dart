// ignore_for_file: implementation_imports
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth/src/auth.dart';
import 'package:tekartik_firebase_auth/src/auth_mixin.dart';

/// Browser sign in options
class AuthBrowserSignInOptions implements AuthSignInOptions {
  bool _isPopup;

  bool get isPopup => _isPopup == true;

  bool get isRedirect => _isPopup != true;

  AuthBrowserSignInOptions({bool isPopup, bool isRedirect}) {
    _isPopup = isPopup ?? (isRedirect == null ? null : !isRedirect);
  }
}

abstract class AuthBrowser with AuthMixin {
  Stream<User> get onAuthStateChanged;

  @override
  Future signOut();

  @deprecated
  Future signInWithRedirect(AuthProvider authProvider);

  @deprecated
  Future<UserCredential> signInPopup(AuthProvider authProvider);
}

abstract class AuthServiceBrowser implements AuthService {}
