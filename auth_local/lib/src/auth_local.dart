import 'dart:async';

import 'package:meta/meta.dart';
import 'package:tekartik_common_utils/int_utils.dart';
import 'package:tekartik_common_utils/list_utils.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
// ignore: implementation_imports
import 'package:tekartik_firebase_auth/src/auth_mixin.dart';

class ListUsersResultLocal implements ListUsersResult {
  @override
  final String pageToken;

  @override
  final List<UserRecord> users;

  ListUsersResultLocal({@required this.pageToken, @required this.users});
}

class UserRecordLocal implements UserRecord {
  @override
  dynamic get customClaims => null;

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

UserInfo adminUserInfo = UserInfoLocal()
  ..displayName = 'admin'
  ..uid = "1";

UserRecordLocal adminUser = UserRecordLocal()
  ..displayName = 'admin'
  ..email = 'admin@example.com'
  ..uid = "1";

List<UserRecordLocal> allUsers = [
  adminUser,
  UserRecordLocal()
    ..displayName = 'user'
    ..email = 'user@example.com'
    ..uid = "2"
];

class UserInfoLocal implements UserInfo, UserInfoWithIdToken {
  @override
  String displayName;

  @override
  String email;

  @override
  String get phoneNumber => null;

  @override
  String get photoURL => null;

  @override
  String get providerId => null;

  @override
  String uid;

  @override
  String toString() => '$uid $email $displayName';

  @override
  Future<String> getIdToken({bool forceRefresh}) async => uid;
}

class AuthLocal with AuthMixin {
  final AppLocal appLocal;

  AuthLocal(this.appLocal) {
    currentUserAdd(adminUserInfo);
  }

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

  @override
  Future<UserRecord> getUser(String uid) async {
    for (var user in allUsers) {
      if (user.uid == uid) {
        return user;
      }
    }
    return null;
  }

  @override
  Future<UserRecord> getUserByEmail(String email) async {
    for (var user in allUsers) {
      if (user.email == email) {
        return user;
      }
    }
    return null;
  }
}

class AuthServiceLocal implements AuthService {
  @override
  bool get supportsListUsers => true;

  @override
  AuthLocal auth(App app) {
    assert(app is AppLocal, 'invalid app type - not AppLocal');
    final appLocal = app as AppLocal;
    return AuthLocal(appLocal);
  }

  @override
  bool get supportsCurrentUser => true;
}

AuthServiceLocal _authServiceLocal;

AuthServiceLocal get authServiceLocal =>
    _authServiceLocal ??= AuthServiceLocal();

AuthService get authService => authServiceLocal;
