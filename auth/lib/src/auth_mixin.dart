import 'dart:async';

import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_common_utils/stream/subject.dart';

mixin AuthMixin implements Auth, FirebaseAppService {
  final _currentUserSubject = Subject<UserInfo>();

  void currentUserAdd(UserInfo userInfo) {
    _currentUserSubject.add(userInfo);
  }

  //void currentUserTokenAdd(String tokenId)

  @override
  UserInfo get currentUser => _currentUserSubject.value;

  @override
  Stream<UserInfo> get onCurrentUserChanged => onCurrentUser;
  @override
  Stream<UserInfo> get onCurrentUser => _currentUserSubject.stream;

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
}
