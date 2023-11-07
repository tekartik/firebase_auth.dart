import 'dart:async';

import 'package:tekartik_common_utils/stream/subject.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_auth/auth.dart';

mixin AuthServiceMixin implements FirebaseAuthService {
  /// Most implementation need a single instance, keep it in memory!
  static final _instances = <App, FirebaseAuth?>{};

  T getInstance<T extends FirebaseAuth?>(
      App app, T Function() createIfNotFound) {
    var instance = _instances[app] as T?;
    if (instance == null) {
      instance = createIfNotFound();
      _instances[app] = instance;
    }
    return instance!;
  }
}

mixin AuthMixin implements FirebaseAuth, FirebaseAppService {
  final _currentUserSubject = Subject<User?>();

  void currentUserAdd(User? user) {
    _currentUserSubject.add(user);
  }

  //void currentUserTokenAdd(String tokenId)

  @override
  User? get currentUser => _currentUserSubject.value;

  @override
  Stream<User?> get onCurrentUser => _currentUserSubject.stream;

  Future<void> currentUserClose() async {
    await _currentUserSubject.close();
  }

  @override
  Future init(App app) async => null;

  @override
  Future close(App? app) async {
    await currentUserClose();
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
}
