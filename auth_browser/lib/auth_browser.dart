@Deprecated('This package will receive no further updates.')
library tekartik_firebase_auth_browser_deprecated;

import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth_browser/src/auth_browser.dart'
    as auth_browser;

export 'package:tekartik_firebase_auth_browser/src/auth_browser.dart'
    show GoogleAuthProvider;
export 'package:tekartik_firebase_auth_browser/src/auth_browser_facebook.dart'
    show FacebookAuthProvider, FacebookAuthCustomParameters;

export 'auth_browser_api.dart';

FirebaseAuthService get authServiceBrowser => auth_browser.authService;

@Deprecated('Use authServiceBrowser')
FirebaseAuthService get authService => authServiceBrowser;
