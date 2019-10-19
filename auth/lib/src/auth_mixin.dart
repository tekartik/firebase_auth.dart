import 'dart:async';

import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_common_utils/stream/subject.dart';

mixin AuthServiceMixin implements AuthService {
  /// Most implementation need a single instance, keep it in memory!
  static final _instances = <App, Auth>{};

  T getInstance<T extends Auth>(App app, T Function() createIfNotFound) {
    T instance = _instances[app] as T;
    if (instance == null) {
      instance = createIfNotFound();
      _instances[app] = instance;
    }
    return instance;
  }
}

mixin AuthMixin implements Auth, FirebaseAppService {
  final _currentUserSubject = Subject<User>();

  void currentUserAdd(User user) {
    _currentUserSubject.add(user);
  }

  //void currentUserTokenAdd(String tokenId)

  @override
  User get currentUser => _currentUserSubject.value;

  @override
  Stream<User> get onCurrentUser => _currentUserSubject.stream;

  Future<void> currentUserClose() async {
    await _currentUserSubject.close();
  }

  @override
  Future init(App app) async => null;

  @override
  Future close(App app) async {
    await currentUserClose();
  }

  @override
  Future<ListUsersResult> listUsers({int maxResults, String pageToken}) {
    throw UnsupportedError('listUsers not supported');
  }

  @override
  Future<UserRecord> getUser(String uid) {
    throw UnsupportedError('getUser not supported');
  }

  @override
  Future<UserRecord> getUserByEmail(String email) {
    throw UnsupportedError('getUser not supported');
  }

  @override
  Future<AuthSignInResult> signIn(AuthProvider authProvider,
      {AuthSignInOptions options}) {
    throw UnsupportedError('signIn not supported');
  }

  @override
  Future signOut() {
    throw UnsupportedError('signIn not supported');
  }

  @override
  Future<DecodedIdToken> verifyIdToken(String idToken, {bool checkRevoked}) {
    throw UnsupportedError('verifyIdToken not supported');
  }
}
