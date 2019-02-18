import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth_browser/src/auth_browser.dart'
    as auth_browser;
export 'package:tekartik_firebase_auth_browser/src/auth_browser.dart'
    show AuthBrowser;
export 'package:firebase/firebase.dart'
    show User, UserCredential, GoogleAuthProvider;

AuthService get authServiceBrowser => auth_browser.authService;
AuthService get authService => authServiceBrowser;
