import 'dart:async';

import 'package:tekartik_common_utils/stream/subject.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_auth/auth.dart';

import 'auth.dart';

/// Compat.
typedef AuthServiceMixin = FirebaseAuthServiceMixin;

/// Firebase auth service mixin
mixin FirebaseAuthServiceMixin implements FirebaseAuthService {}

/// Compat.
typedef AuthMixin = FirebaseAuthMixin;

/// Firebase auth mixin
mixin FirebaseAuthMixin implements FirebaseAuth, FirebaseAppProduct {
  final _currentUserSubject = Subject<User?>();

  /// Add current user
  void currentUserAdd(User? user) {
    _currentUserSubject.add(user);
  }

  //void currentUserTokenAdd(String tokenId)

  @override
  User? get currentUser => _currentUserSubject.value;

  @override
  Stream<User?> get onCurrentUser => _currentUserSubject.stream;

  /// Close current user
  Future<void> currentUserClose() async {
    await _currentUserSubject.close();
  }

  @override
  Future<ListUsersResult> listUsers({int? maxResults, String? pageToken}) {
    throw UnsupportedError('$runtimeType.listUsers not supported');
  }

  @override
  Future<UserRecord?> getUser(String uid) {
    throw UnsupportedError('$runtimeType.getUser not supported');
  }

  @override
  Future<List<UserRecord>> getUsers(List<String> uids) {
    throw UnsupportedError('$runtimeType.getUsers not supported');
  }

  @override
  Future<UserRecord?> getUserByEmail(String email) {
    throw UnsupportedError('$runtimeType.getUser not supported');
  }

  @override
  Future<AuthSignInResult> signIn(AuthProvider authProvider,
      {AuthSignInOptions? options}) {
    throw UnsupportedError('$runtimeType.signIn not supported');
  }

  @override
  Future signOut() {
    throw UnsupportedError('$runtimeType.signIn not supported');
  }

  @override
  Future<DecodedIdToken> verifyIdToken(String idToken, {bool? checkRevoked}) {
    throw UnsupportedError('$runtimeType.verifyIdToken not supported');
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword(
      {required String email, required String password}) {
    throw UnsupportedError(
        '$runtimeType.signInWithEmailAndPassword not supported');
  }
}

/// Firebase user mixin
mixin FirebaseUserMixin implements User {
  @override
  String? get displayName => null;

  @override
  String? get email => null;

  @override
  bool get emailVerified => false;

  @override
  bool get isAnonymous => false;

  @override
  String? get phoneNumber => null;

  @override
  String? get photoURL => null;

  @override
  String? get providerId => null;
}

/// Firebase user credential mixin
mixin FirebaseUserCredentialMixin implements UserCredential {
  @override
  FirebaseUser get user =>
      throw UnimplementedError('FirebaseUserCredential.user');
}

/// Firebase auth credential mixin
mixin FirebaseAuthCredentialMixin implements FirebaseAuthCredential {
  // @override String get providerId => throw UnimplementedError('FirebaseAuthCredential.providerId');
}
