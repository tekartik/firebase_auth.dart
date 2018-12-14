import 'dart:async';

import 'package:meta/meta.dart';
import 'package:tekartik_common_utils/int_utils.dart';
import 'package:tekartik_common_utils/list_utils.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

class ListUsersResultLocal implements ListUsersResult {
  @override
  final String pageToken;

  @override
  final List<UserRecord> users;

  ListUsersResultLocal({@required this.pageToken, @required this.users});
}

class UserRecordLocal implements UserRecord {
  @override
  get customClaims => null;

  @override
  bool disabled;

  @override
  String displayName;

  @override
  String email;

  @override
  bool emailVerified;

  @override
  UserMetadata get metadata => null;

  @override
  String get passwordHash => null;

  @override
  String get passwordSalt => null;

  @override
  String get phoneNumber => null;

  @override
  String get photoURL => null;

  @override
  List<UserInfo> get providerData => null;

  @override
  String get tokensValidAfterTime => null;

  @override
  String uid;
}

List<UserRecordLocal> allUsers = [
  UserRecordLocal()
    ..displayName = 'admin'
    ..uid = "1",
  UserRecordLocal()
    ..displayName = 'user'
    ..uid = "2"
];

class AuthLocal implements Auth {
  final AppLocal appLocal;

  AuthLocal(this.appLocal);

  String get localPath => appLocal.localPath;

  @override
  Future<ListUsersResult> listUsers({int maxResults, String pageToken}) async {
    int startIndex = parseInt(pageToken, 0);
    int lastIndex = startIndex + (maxResults ?? 10);
    var result = ListUsersResultLocal(
        pageToken: lastIndex.toString(),
        users: listSubList(allUsers, startIndex, lastIndex));

    return result;
  }
}

class AuthServiceLocal implements AuthService {
  @override
  bool get supportsListUsers => true;

  @override
  AuthLocal auth(App app) {
    assert(app is AppLocal, 'invalid app type - not AppLocal');
    AppLocal appLocal = app;
    return AuthLocal(appLocal);
  }
}

AuthServiceLocal _authServiceLocal;

AuthServiceLocal get authServiceLocal =>
    _authServiceLocal ??= AuthServiceLocal();

AuthService get authService => authServiceLocal;
