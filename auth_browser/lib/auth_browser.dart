import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth_browser/src/auth_browser.dart'
    as auth_browser;
export 'package:tekartik_firebase_auth_browser/src/auth_browser.dart'
    show AuthBrowser, GoogleAuthProvider, AuthBrowserSignInOptions;

AuthService get authServiceBrowser => auth_browser.authService;
AuthService get authService => authServiceBrowser;
