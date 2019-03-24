import 'dart:async';

import 'package:firebase/firebase.dart' as native;
import 'package:tekartik_browser_utils/browser_utils_import.dart' hide Blob;
import 'package:tekartik_firebase/firebase.dart' as common;
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth/src/auth.dart';
import 'package:tekartik_firebase_auth/src/auth_mixin.dart';
import 'package:tekartik_firebase_browser/src/firebase_browser.dart' as native;

// ignore_for_file: implementation_imports

class AuthBrowserSignInOptions implements AuthSignInOptions {
  bool _isPopup;

  bool get isPopup => _isPopup == true;

  bool get isRedirect => _isPopup != true;

  AuthBrowserSignInOptions({bool isPopup, bool isRedirect}) {
    _isPopup = isPopup ?? (isRedirect == null ? null : !isRedirect);
  }
}

abstract class GoogleAuthProvider extends AuthProvider {
  factory GoogleAuthProvider() => GoogleAuthProviderImpl();
}

class GoogleAuthProviderImpl extends AuthProviderImpl
    implements GoogleAuthProvider {
  static final native.GoogleAuthProvider nativeGoogleAuthProviderInstance =
      native.GoogleAuthProvider();

  GoogleAuthProviderImpl() : super(nativeGoogleAuthProviderInstance);
}

abstract class AuthBrowser with AuthMixin {
  Stream<native.User> get onAuthStateChanged;

  @override
  Future signOut();

  @deprecated
  Future signInWithRedirect(AuthProvider authProvider);

  @deprecated
  Future<UserCredential> signInPopup(AuthProvider authProvider);
}

class AuthServiceBrowser implements AuthService {
  @override
  Auth auth(common.App app) {
    assert(app is native.AppBrowser, 'invalid firebase app type');
    final appBrowser = app as native.AppBrowser;
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

class AuthProviderImpl implements AuthProvider {
  final native.AuthProvider nativeAuthProvider;

  AuthProviderImpl(this.nativeAuthProvider);

  @override
  String get providerId => nativeAuthProvider.providerId;
}

class UserCredentialImpl implements UserCredential {
  final native.UserCredential nativeInstance;

  UserCredentialImpl(this.nativeInstance);

  //@override
  //AuthCredential get credential => wrapAuthCredential(nativeInstance.credential);

  @override
  UserInfo get user => wrapUserInfo(nativeInstance.user);

  @override
  // TODO: implement credential
  AuthCredential get credential => null;
}

class AuthCredentialImpl implements AuthCredential {
  final native.AuthCredential nativeInstance;

  AuthCredentialImpl(this.nativeInstance);

  @override
  String get providerId => nativeInstance.providerId;
}

class UserImpl extends UserInfoBrowser implements UserInfoWithStatus {
  UserImpl(native.User nativeUser) : super(nativeUser);

  @override
  bool get emailVerified => nativeUser.emailVerified;

  @override
  bool get isAnonymous => nativeUser.isAnonymous;
}

class AuthSignInResultImpl implements AuthSignInResult {
  @override
  final UserCredential credential;

  @override
  final bool hasInfo;

  AuthSignInResultImpl({this.credential, bool hasNoInfo})
      : hasInfo = hasNoInfo ?? credential == null;
}

//User wrapUser(native.User nativeInstance) => nativeInstance != null ? UserImpl(nativeInstance) : null;
AuthCredential wrapAuthCredential(native.AuthCredential nativeInstance) =>
    nativeInstance != null ? AuthCredentialImpl(nativeInstance) : null;

UserCredential wrapUserCredential(native.UserCredential nativeInstance) =>
    nativeInstance != null ? UserCredentialImpl(nativeInstance) : null;

AuthProvider wrapAuthProvider(native.AuthProvider nativeInstance) =>
    nativeInstance != null ? AuthProviderImpl(nativeInstance) : null;

native.AuthProvider unwrapAuthProvider(AuthProvider authProvider) =>
    authProvider != null
        ? (authProvider as AuthProviderImpl).nativeAuthProvider
        : null;

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
    //TODO cache id token when refreshed?
    //nativeAuth.onIdTokenChanged.listen((user) {
    //  user?.getIdToken();
    //});
  }

  @override
  Stream<native.User> get onAuthStateChanged => nativeAuth.onAuthStateChanged;

  @override
  Future signOut() => nativeAuth.signOut();

  @override
  Future<UserCredential> signInPopup(AuthProvider authProvider) async =>
      (await signIn(authProvider,
              options: AuthBrowserSignInOptions(isPopup: true)))
          ?.credential;

  @override
  Future signInWithRedirect(AuthProvider authProvider) =>
      signIn(authProvider, options: AuthBrowserSignInOptions(isRedirect: true));

  @override
  Future close(common.App app) async {
    await super.close(app);
    await onAuthStateChangedSubscription?.cancel();
  }

  @override
  Future<AuthSignInResult> signIn(AuthProvider authProvider,
      {AuthSignInOptions options}) async {
    bool isPopup = (options as AuthBrowserSignInOptions)?.isPopup == true;
    if (isPopup) {
      var credential = wrapUserCredential(
          await nativeAuth.signInWithPopup(unwrapAuthProvider(authProvider)));
      return AuthSignInResultImpl(credential: credential, hasNoInfo: false);
    } else {
      await nativeAuth.signInWithRedirect(unwrapAuthProvider(authProvider));
      return null;
    }
  }
}

UserInfoBrowser wrapUserInfo(native.User nativeUser) =>
    nativeUser != null ? UserInfoBrowser(nativeUser) : null;

abstract class UserInfoMixin {}

class UserInfoBrowser implements UserInfo, UserInfoWithIdToken {
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

  @override
  Future<String> getIdToken({bool forceRefresh}) =>
      nativeUser.getIdToken(forceRefresh == true);
}
