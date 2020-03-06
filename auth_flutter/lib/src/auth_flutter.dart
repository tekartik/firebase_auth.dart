// ignore_for_file: implementation_imports
import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart' as google_sign_in;
import 'package:firebase_auth/firebase_auth.dart' as native;
import 'package:tekartik_firebase/firebase.dart' as common;
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth/src/auth_mixin.dart';
import 'package:tekartik_firebase_auth_flutter/auth_flutter.dart';
import 'package:tekartik_firebase_flutter/src/firebase_flutter.dart'
    as firebase_flutter;

class AuthServiceFlutterImpl
    with AuthServiceMixin
    implements AuthServiceFlutter {
  @override
  Auth auth(common.App app) {
    return getInstance(app, () {
      assert(app is firebase_flutter.AppFlutter, 'invalid firebase app type');
      final appFlutter = app as firebase_flutter.AppFlutter;
      return AuthFlutterImpl(
          native.FirebaseAuth.fromApp(appFlutter.nativeInstance));
    });
  }

  @override
  bool get supportsListUsers => false;

  @override
  bool get supportsCurrentUser => true;
}

AuthServiceFlutter _firebaseAuthServiceFlutter;

AuthServiceFlutter get authService =>
    _firebaseAuthServiceFlutter ??= AuthServiceFlutterImpl();

UserFlutterImpl wrapUser(native.FirebaseUser nativeUser) =>
    nativeUser != null ? UserFlutterImpl(nativeUser) : null;

class UserFlutterImpl implements User {
  final native.FirebaseUser nativeInstance;

  UserFlutterImpl(this.nativeInstance);

  @override
  String get displayName => nativeInstance.displayName;

  @override
  String get email => nativeInstance.email;

  @override
  bool get emailVerified => nativeInstance.isEmailVerified;

  @override
  bool get isAnonymous => nativeInstance.isAnonymous;

  @override
  String get phoneNumber => nativeInstance.phoneNumber;

  @override
  String get photoURL => nativeInstance.photoUrl;

  @override
  String get providerId => nativeInstance.providerId;

  @override
  String get uid => nativeInstance.uid;

  @override
  String toString() => '$displayName ($email)';
}

class AuthFlutterImpl with AuthMixin implements AuthFlutter {
  final native.FirebaseAuth nativeAuth;

  StreamSubscription onAuthStateChangedSubscription;

  AuthFlutterImpl(this.nativeAuth) {
    onAuthStateChangedSubscription =
        nativeAuth.onAuthStateChanged.listen((user) {
      currentUserAdd(wrapUser(user));
    });
  }

  @override
  Future close(common.App app) async {
    await super.close(app);
    await onAuthStateChangedSubscription?.cancel();
  }

  google_sign_in.GoogleSignIn _googleSignIn;

  /// Google only...
  @override
  Future<User> googleSignIn() async {
    _googleSignIn ??= google_sign_in.GoogleSignIn();
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      return null;
    }
    final googleAuth = await googleUser.authentication;

    final credential = native.GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final nativeUser = (await nativeAuth.signInWithCredential(credential)).user;
    return wrapUser(nativeUser);
  }

  @override
  Future signOut() async {
    await nativeAuth.signOut();
  }

  @override
  String toString() => 'AuthFlutter(${nativeAuth?.app?.name})';
}
