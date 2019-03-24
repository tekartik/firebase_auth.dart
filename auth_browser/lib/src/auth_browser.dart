import 'dart:async';

import 'package:firebase/firebase.dart' as native;
// ignore: implementation_imports
import 'package:firebase/src/interop/auth_interop.dart';
import 'package:tekartik_browser_utils/browser_utils_import.dart' hide Blob;
import 'package:tekartik_firebase/firebase.dart' as common;
// ignore: implementation_imports
import 'package:tekartik_firebase_browser/src/firebase_browser.dart';
import 'package:tekartik_firebase_auth/auth.dart';
// ignore: implementation_imports
import 'package:tekartik_firebase_auth/src/auth.dart';
// ignore: implementation_imports
import 'package:tekartik_firebase_auth/src/auth_mixin.dart';

abstract class AuthBrowser with AuthMixin {
  Stream<native.User> get onAuthStateChanged;

  Future signOut();

  Future signInWithRedirect(native.AuthProvider authProvider);

  Future<native.UserCredential> signInPopup(native.AuthProvider authProvider);
}

class AuthServiceBrowser implements AuthService {
  @override
  Auth auth(common.App app) {
    assert(app is AppBrowser, 'invalid firebase app type');
    final appBrowser = app as AppBrowser;
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

class AuthBrowserImpl with AuthMixin implements AuthBrowser {
  final native.Auth nativeAuth;

  StreamSubscription onAuthStateChangedSubscription;

  AuthBrowserImpl(this.nativeAuth) {
    // Handle the case where we never receive the information
    // This happens if we register late, simple wait 5s
    bool _seeded = false;
    // Register right away to feed our current user controller
    final nativeCurrentUser = nativeAuth.currentUser;
    // Handle when already known on start
    if (nativeCurrentUser != null) {
      _seeded = true;
      currentUserAdd(wrapUserInfo(nativeCurrentUser));
    }
    onAuthStateChangedSubscription = onAuthStateChanged.listen((user) {
      _seeded = true;
      currentUserAdd(wrapUserInfo(user));
    });
    if (!_seeded) {
      sleep(3000).then((_) {
        if (!_seeded) {
          currentUserAdd(null);
        }
      });
    }
  }

  @override
  Stream<native.User> get onAuthStateChanged => nativeAuth.onAuthStateChanged;

  @override
  Future signOut() => nativeAuth.signOut();

  @override
  Future<native.UserCredential> signInPopup(
          native.AuthProvider<AuthProviderJsImpl> authProvider) =>
      nativeAuth.signInWithPopup(authProvider);

  @override
  Future signInWithRedirect(
          native.AuthProvider<AuthProviderJsImpl> authProvider) =>
      nativeAuth.signInWithRedirect(authProvider);

  @override
  Future close(common.App app) async {
    await super.close(app);
    await onAuthStateChangedSubscription?.cancel();
  }
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
