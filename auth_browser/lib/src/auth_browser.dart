import 'dart:async';

import 'package:firebase/firebase.dart' as native;
import 'package:firebase/src/interop/auth_interop.dart';
import 'package:tekartik_browser_utils/browser_utils_import.dart' hide Blob;
import 'package:tekartik_firebase/firebase.dart' as common;
import 'package:tekartik_firebase_browser/src/firebase_browser.dart';
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth/src/auth.dart';

abstract class AuthBrowser extends Auth {
  Stream<native.User> get onAuthStateChanged;

  Future signOut();

  Future signInWithRedirect(native.AuthProvider authProvider);

  Future<native.UserCredential> signInPopup(native.AuthProvider authProvider);
}

class AuthServiceBrowser implements AuthService {
  @override
  Auth auth(common.App app) {
    assert(app is AppBrowser, 'invalid firebase app type');
    AppBrowser appBrowser = app;
    return AuthBrowserImpl(appBrowser.nativeApp.auth());
  }

  @override
  bool get supportsListUsers => false;

  @override
  bool get supportsCurrentUser => true;
}

AuthServiceBrowser _firebaseAuthServiceBrowser;

AuthService get authService =>
    _firebaseAuthServiceBrowser ??= AuthServiceBrowser();

class AuthBrowserImpl implements Auth, AuthBrowser {
  final native.Auth nativeAuth;

  AuthBrowserImpl(this.nativeAuth);

  Stream<native.User> get onAuthStateChanged => nativeAuth.onAuthStateChanged;

  @override
  Future signOut() => nativeAuth.signOut();

  @override
  Future<ListUsersResult> listUsers({int maxResults, String pageToken}) {
    throw UnsupportedError('listUsers not supported in the browser');
  }

  @override
  Future<native.UserCredential> signInPopup(
          native.AuthProvider<AuthProviderJsImpl> authProvider) =>
      nativeAuth.signInWithPopup(authProvider);

  @override
  Future signInWithRedirect(
          native.AuthProvider<AuthProviderJsImpl> authProvider) =>
      nativeAuth.signInWithRedirect(authProvider);

  Stream<UserInfo> get onCurrentUserChanged {
    return nativeAuth.onAuthStateChanged.transform<UserInfo>(
        StreamTransformer.fromHandlers(
            handleData: (native.User nativeUser, sink) {
      sink.add(wrapUserInfo(nativeUser));
    }));
  }

  @override
  UserInfo get currentUser => wrapUserInfo(nativeAuth.currentUser);
}

UserInfoBrowser wrapUserInfo(native.User nativeUser) =>
    nativeUser != null ? UserInfoBrowser(nativeUser) : null;

class UserInfoBrowser implements UserInfo {
  final native.User nativeUser;

  UserInfoBrowser(this.nativeUser);

  @override
  String get displayName => nativeUser.displayName;

  @override
  String get email => nativeUser.email;

  @override
  String get phoneNumber => nativeUser.phoneNumber;

  @override
  String get photoURL => nativeUser.photoURL;

  @override
  String get providerId => nativeUser.providerId;

  @override
  String get uid => nativeUser.uid;

  @override
  String toString() {
    return '$uid $email $displayName';
  }
}
