import 'dart:async';

import 'package:firebase/firebase.dart' as native;
import 'package:tekartik_browser_utils/browser_utils_import.dart' hide Blob;
import 'package:tekartik_firebase/firebase.dart' as common;
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth/src/auth.dart';
import 'package:tekartik_firebase_auth/src/auth_mixin.dart';
import 'package:tekartik_firebase_browser/src/firebase_browser.dart'
    as firebase_browser;

import 'auth_browser_api.dart';
// ignore_for_file: implementation_imports

abstract class GoogleAuthProvider extends AuthProvider {
  factory GoogleAuthProvider() => GoogleAuthProviderImpl();

  void addScope(String scope);
}

class GoogleAuthProviderImpl extends AuthProviderImpl
    implements GoogleAuthProvider {
  GoogleAuthProviderImpl() : super(native.GoogleAuthProvider()) {
    _nativeAuthProvider = nativeAuthProvider as native.GoogleAuthProvider;
  }

  native.GoogleAuthProvider _nativeAuthProvider;

  /// Adds additional OAuth 2.0 scopes that you want to request from the
  /// authentication provider.
  @override
  void addScope(String scope) {
    _nativeAuthProvider = _nativeAuthProvider.addScope(scope);
  }
}

class AuthServiceBrowserImpl
    with AuthServiceMixin
    implements AuthServiceBrowser {
  @override
  Auth auth(common.App app) {
    return getInstance(app, () {
      assert(app is firebase_browser.AppBrowser, 'invalid firebase app type');
      final appBrowser = app as firebase_browser.AppBrowser;
      return AuthBrowserImpl(appBrowser.nativeApp.auth());
    });
  }

  @override
  bool get supportsListUsers => false;

  @override
  bool get supportsCurrentUser => true;
}

AuthServiceBrowser _firebaseAuthServiceBrowser;

AuthService get authService =>
    _firebaseAuthServiceBrowser ??= AuthServiceBrowserImpl();

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
  User get user => wrapUser(nativeInstance.user);

  @override
  // TODO: implement credential
  AuthCredential get credential => null;
}

class AuthCredentialImpl implements AuthCredential {
  final native.OAuthCredential nativeInstance;

  AuthCredentialImpl(this.nativeInstance);

  @override
  String get providerId => nativeInstance.providerId;
}

class UserImpl extends UserInfoBrowser implements User {
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
AuthCredential wrapAuthCredential(native.OAuthCredential nativeInstance) =>
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

  void _listenToCurrentUser() {
    onAuthStateChangedSubscription?.cancel();
    onAuthStateChangedSubscription = onAuthStateChanged.listen((user) {
      currentUserAdd(user);
    });
  }

  @override
  Future<User> reloadCurrentUser() async {
    await nativeAuth.currentUser?.reload();
    _listenToCurrentUser();
    return wrapUser(nativeAuth.currentUser);
  }

  AuthBrowserImpl(this.nativeAuth) {
    // Handle the case where we never receive the information
    // This happens if we register late, simple wait 5s
    var _seeded = false;
    // Register right away to feed our current user controller
    final nativeCurrentUser = nativeAuth.currentUser;
    // Handle when already known on start
    if (nativeCurrentUser != null) {
      _seeded = true;
      currentUserAdd(wrapUser(nativeCurrentUser));
    }
    onAuthStateChangedSubscription = onAuthStateChanged.listen((user) {
      _seeded = true;
      currentUserAdd(user);
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
  Stream<User> get onAuthStateChanged =>
      nativeAuth.onAuthStateChanged.transform(
          StreamTransformer.fromHandlers(handleData: (nativeUser, sink) {
        sink.add(wrapUser(nativeUser));
      }));

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
    var isPopup = (options as AuthBrowserSignInOptions)?.isPopup == true;
    if (isPopup) {
      var credential = wrapUserCredential(
          await nativeAuth.signInWithPopup(unwrapAuthProvider(authProvider)));
      return AuthSignInResultImpl(credential: credential, hasNoInfo: false);
    } else {
      await nativeAuth.signInWithRedirect(unwrapAuthProvider(authProvider));
      return null;
    }
  }

  @override
  String toString() => 'AuthBrowser(${nativeAuth?.app?.options?.projectId})';
}

UserInfoBrowser wrapUserInfo(native.User nativeUser) =>
    nativeUser != null ? UserInfoBrowser(nativeUser) : null;

UserBrowser wrapUser(native.User nativeUser) =>
    nativeUser != null ? UserBrowser(nativeUser) : null;

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

class UserBrowser extends UserInfoBrowser implements User {
  UserBrowser(native.User nativeUser) : super(nativeUser);

  @override
  bool get emailVerified => nativeUser.emailVerified;

  @override
  bool get isAnonymous => nativeUser.isAnonymous;
}
