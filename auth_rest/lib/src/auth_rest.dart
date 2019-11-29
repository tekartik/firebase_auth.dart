import 'dart:async';

import 'package:meta/meta.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth/src/auth_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_auth_rest/src/identitytoolkit/v3.dart'
    hide UserInfo;
import 'package:tekartik_firebase_auth_rest/src/identitytoolkit/v3.dart' as api;
import 'package:tekartik_firebase_rest/firebase_rest.dart';

bool debugRest = false; // devWarning(true); // false

abstract class AuthRestProvider implements AuthProvider {
  factory AuthRestProvider() {
    return AuthLocalProviderImpl();
  }
}

const localProviderId = '_local';

class AuthLocalProviderImpl implements AuthRestProvider {
  @override
  String get providerId => localProviderId;
}

/*
class AuthLocalSignInOptions implements AuthSignInOptions {
  final UserRecordRest _userRecordLocal;

  AuthLocalSignInOptions(this._userRecordLocal);
}

 */

class ListUsersResultRest implements ListUsersResult {
  @override
  final String pageToken;

  @override
  final List<UserRecord> users;

  ListUsersResultRest({@required this.pageToken, @required this.users});
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

class UserRecordRest implements UserRecord {
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
  String photoURL;

  @override
  List<UserInfo> get providerData => null;

  @override
  String get tokensValidAfterTime => null;

  @override
  String uid;

  UserInfo toUserInfo() {
    return UserInfoRest()
      ..uid = uid
      ..email = email
      ..displayName = displayName;
  }

  User toUser() {
    return UserRest()
      ..uid = uid
      ..email = email
      ..displayName = displayName;
  }

  @override
  String toString() {
    return 'email: $email ($emailVerified) $displayName, $uid';
  }
}

class UserInfoRest implements UserInfo, UserInfoWithIdToken {
  @override
  String displayName;

  @override
  String email;

  @override
  String get phoneNumber => null;

  @override
  String get photoURL => null;

  @override
  String get providerId => localProviderId;

  @override
  String uid;

  @override
  String toString() => '$uid $email $displayName';

  @override
  Future<String> getIdToken({bool forceRefresh}) async => uid;
}

/// Top level class
class UserRest extends UserInfoRest implements User {
  @override
  final bool emailVerified;

  UserRest({this.emailVerified});

  @override
  bool get isAnonymous => false;

  @override
  String toString() {
    return super.toString() + ", emailVerified: $emailVerified";
  }
}

/// Custom auth rest
abstract class AuthRest implements Auth {
  /// Custom AuthRest
  factory AuthRest(
      {@required AppRest appRest, String rootUrl, String servicePathBase}) {
    return AuthRestImpl(appRest,
        rootUrl: rootUrl, servicePathBase: servicePathBase);
  }
}

class AuthRestImpl with AuthMixin implements AuthRest {
  final AppRest _appRest;

  // ignore: unused_field
  final App _app;
  IdentitytoolkitApi _identitytoolkitApi;
  String rootUrl;
  String servicePathBase;

  IdentitytoolkitApi get identitytoolkitApi => _identitytoolkitApi ??= () {
        if (rootUrl != null || servicePathBase != null) {
          String defaultRootUrl = "https://www.googleapis.com/";

          String defaultServicePath = "identitytoolkit/v3/relyingparty/";
          return IdentitytoolkitApi(_appRest.authClient,
              servicePath: servicePathBase == null
                  ? defaultServicePath
                  : '$servicePathBase/$defaultServicePath',
              rootUrl: rootUrl ?? defaultRootUrl);
        } else {
          return IdentitytoolkitApi(_appRest.authClient);
        }
      }();

  AuthRestImpl(this._app, {this.rootUrl, this.servicePathBase})
      : _appRest = (_app is AppRest ? _app : null);

  //String get localPath => _appLocal?.localPath;

  @override
  Stream<User> get onCurrentUser => throw UnsupportedError('onCurrentUser');
  @override
  Future<ListUsersResult> listUsers({int maxResults, String pageToken}) async {
    throw UnsupportedError('listUsers');
  }

  @override
  Future<UserRecord> getUser(String uid) async {
    var request = IdentitytoolkitRelyingpartyGetAccountInfoRequest()
      ..localId = [uid];
    if (debugRest) {
      print('getAccountInfoRequest: ${jsonPretty(request.toJson())}');
    }
    var result = await identitytoolkitApi.relyingparty.getAccountInfo(request);
    if (debugRest) {
      print('getAccountInfo: ${jsonPretty(result.toJson())}');
    }
    if (result.users?.isNotEmpty ?? false) {
      var restUserInfo = result.users.first;
      return toUserRecord(restUserInfo);
    }
    return null;
  }

  UserRecord toUserRecord(api.UserInfo restUserInfo) {
    var userRecord = UserRecordRest();
    userRecord.email = restUserInfo.email;
    userRecord.displayName = restUserInfo.displayName;
    userRecord.uid = restUserInfo.localId;
    userRecord.photoURL = restUserInfo.photoUrl;
    userRecord.emailVerified = restUserInfo.emailVerified;
    return userRecord;
  }

  @override
  Future<List<UserRecord>> getUsers(List<String> uids) async {
    var request = IdentitytoolkitRelyingpartyGetAccountInfoRequest()
      ..localId = uids;
    if (debugRest) {
      print('getAccountInfoRequest: ${jsonPretty(request.toJson())}');
    }
    var result = await identitytoolkitApi.relyingparty.getAccountInfo(request);
    if (debugRest) {
      print('getAccountInfo: ${jsonPretty(result.toJson())}');
    }
    return result?.users
        ?.map((restUserInfo) => toUserRecord(restUserInfo))
        ?.toList(growable: false);
  }

  @override
  Future<UserRecord> getUserByEmail(String email) async {
    throw UnsupportedError('getUserByEmail');
  }

  @override
  Future<AuthSignInResult> signIn(AuthProvider authProvider,
      {AuthSignInOptions options}) async {
    throw UnsupportedError('signIn');
  }

  @override
  Future signOut() async {
    throw UnsupportedError('signOut');
  }

  @override
  String toString() => _appRest?.name ?? 'local';

  @override
  Future<DecodedIdToken> verifyIdToken(String idToken,
      {bool checkRevoked}) async {
    throw UnsupportedError('verifyIdToken');
  }
}

class DecodedIdTokenLocal implements DecodedIdToken {
  @override
  final String uid;

  DecodedIdTokenLocal({this.uid});
}

class AuthServiceRest with AuthServiceMixin implements AuthService {
  @override
  bool get supportsListUsers => false;

  @override
  Auth auth(App app) {
    return getInstance(app, () {
      // assert(app is AppLocal, 'invalid app type - not AppLocal');
      // final appLocal = app as AppLocal;
      return AuthRestImpl(app);
    });
  }

  @override
  bool get supportsCurrentUser => false;
}

AuthServiceRest _authServiceRest;

AuthServiceRest get authServiceLocal => _authServiceRest ??= AuthServiceRest();

AuthService get authService => authServiceLocal;
