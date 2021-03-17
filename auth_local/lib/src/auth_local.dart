import 'dart:async';

import 'package:tekartik_common_utils/int_utils.dart';
import 'package:tekartik_common_utils/list_utils.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth/src/auth_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_local/firebase_local.dart';

abstract class AuthLocalProvider implements AuthProvider {
  factory AuthLocalProvider() {
    return AuthLocalProviderImpl();
  }
}

const localProviderId = '_local';

class AuthLocalProviderImpl implements AuthLocalProvider {
  @override
  String get providerId => localProviderId;
}

class AuthLocalSignInOptions implements AuthSignInOptions {
  final UserRecordLocal _userRecordLocal;

  AuthLocalSignInOptions(this._userRecordLocal);
}

class ListUsersResultLocal implements ListUsersResult {
  @override
  final String pageToken;

  @override
  final List<UserRecord> users;

  ListUsersResultLocal({required this.pageToken, required this.users});
}

class AuthSignInResultImpl implements AuthSignInResult {
  @override
  final UserCredential credential;

  AuthSignInResultImpl(this.credential);

  @override
  bool get hasInfo => true;
}

class UserCredentialImpl implements UserCredential {
  @override
  final AuthCredential credential;

  @override
  final User user;

  UserCredentialImpl(this.credential, this.user);
}

class AuthCredentialImpl implements AuthCredential {
  @override
  String get providerId => localProviderId;
}

class UserRecordLocal implements UserRecord {
  UserRecordLocal({required this.uid});

  @override
  dynamic get customClaims => null;

  @override
  late bool disabled;

  @override
  String? displayName;

  @override
  String? email;

  @override
  late bool emailVerified;

  @override
  UserMetadata? get metadata => null;

  @override
  String? get passwordHash => null;

  @override
  String? get passwordSalt => null;

  @override
  String? get phoneNumber => null;

  @override
  String? get photoURL => null;

  @override
  List<UserInfo>? get providerData => null;

  @override
  String? get tokensValidAfterTime => null;

  @override
  final String uid;

  UserInfo toUserInfo() {
    return UserInfoLocal(uid: uid)
      ..email = email
      ..displayName = displayName;
  }

  User toUser() {
    return UserLocal(uid: uid)
      ..email = email
      ..displayName = displayName;
  }
}

UserRecordLocal localAdminUser = UserRecordLocal(uid: '1')
  ..displayName = 'admin'
  ..email = 'admin@example.com'
  ..emailVerified = true;

User adminUserInfo = localAdminUser.toUser();

UserRecordLocal localRegularUser = UserRecordLocal(uid: '2')
  ..displayName = 'user'
  ..email = 'user@example.com'
  ..emailVerified = true;

List<UserRecordLocal> allUsers = [
  localAdminUser,
  localRegularUser,
];

class UserInfoLocal implements UserInfo, UserInfoWithIdToken {
  @override
  String? displayName;

  @override
  String? email;

  UserInfoLocal({required this.uid});

  @override
  String? get phoneNumber => null;

  @override
  String? get photoURL => null;

  @override
  String get providerId => localProviderId;

  @override
  final String uid;

  @override
  String toString() => '$uid $email $displayName';

  @override
  Future<String> getIdToken({bool? forceRefresh}) async => uid;
}

class UserLocal extends UserInfoLocal implements User {
  UserLocal({required String uid}) : super(uid: uid);

  @override
  bool get emailVerified => true;

  @override
  bool get isAnonymous => false;
}

abstract class AuthLocal implements Auth {}

class AuthLocalImpl with AuthMixin implements AuthLocal {
  final AppLocal? _appLocal;

  // ignore: unused_field
  final App _app;

  AuthLocalImpl(this._app) : _appLocal = (_app is AppLocal ? _app : null) {
    currentUserAdd(adminUserInfo);
  }

  //String get localPath => _appLocal?.localPath;

  @override
  Future<ListUsersResult> listUsers(
      {int? maxResults, String? pageToken}) async {
    var startIndex = parseInt(pageToken, 0)!;
    var lastIndex = startIndex + (maxResults ?? 10);
    var result = ListUsersResultLocal(
        pageToken: lastIndex.toString(),
        users: listSubList(allUsers, startIndex, lastIndex));

    return result;
  }

  @override
  Future<UserRecord?> getUser(String? uid) async {
    for (var user in allUsers) {
      if (user.uid == uid) {
        return user;
      }
    }
    return null;
  }

  @override
  Future<List<UserRecord?>> getUsers(List<String> uids) async {
    var list = <UserRecord?>[];
    for (var uid in uids) {
      list.add(await getUser(uid));
    }
    return list;
  }

  @override
  Future<UserRecord?> getUserByEmail(String email) async {
    for (var user in allUsers) {
      if (user.email == email) {
        return user;
      }
    }
    return null;
  }

  @override
  Future<AuthSignInResult> signIn(AuthProvider authProvider,
      {AuthSignInOptions? options}) async {
    var localOptions = options as AuthLocalSignInOptions?;
    var uid = localOptions?._userRecordLocal.uid;
    var userRecord = await getUser(uid) as UserRecordLocal?;

    if (userRecord == null) {
      throw StateError('user $uid not found');
      // return AuthSignInResultImpl(null);
    } else {
      var user = userRecord.toUser();
      currentUserAdd(user);
      return AuthSignInResultImpl(
          UserCredentialImpl(AuthCredentialImpl(), user));
    }
  }

  @override
  Future signOut() async {
    currentUserAdd(null);
  }

  @override
  String toString() => _appLocal?.name ?? 'local';

  @override
  Future<DecodedIdToken> verifyIdToken(String idToken,
      {bool? checkRevoked}) async {
    // The id token is the uid itself
    return DecodedIdTokenLocal(uid: idToken);
  }

  @override
  Future<User?> reloadCurrentUser() async {
    // No-op on local
    return currentUser;
  }
}

class DecodedIdTokenLocal implements DecodedIdToken {
  @override
  final String uid;

  DecodedIdTokenLocal({required this.uid});
}

class AuthServiceLocal with AuthServiceMixin implements AuthService {
  @override
  bool get supportsListUsers => true;

  @override
  Auth auth(App app) {
    return getInstance(app, () {
      // assert(app is AppLocal, 'invalid app type - not AppLocal');
      // final appLocal = app as AppLocal;
      return AuthLocalImpl(app);
    });
  }

  @override
  bool get supportsCurrentUser => true;
}

AuthServiceLocal? _authServiceLocal;

AuthServiceLocal get authServiceLocal =>
    _authServiceLocal ??= AuthServiceLocal();

AuthService get authService => authServiceLocal;
