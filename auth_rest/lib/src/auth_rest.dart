import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth/src/auth_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_auth_rest/src/identitytoolkit/v3.dart'
    hide UserInfo;
import 'package:tekartik_firebase_auth_rest/src/identitytoolkit/v3.dart' as api;
import 'package:tekartik_firebase_rest/firebase_rest.dart';

import 'google_auth_rest.dart';

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

  ListUsersResultRest({required this.pageToken, required this.users});
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

  @override
  String toString() => '$user $credential';
}

class AuthCredentialImpl implements AuthCredential {
  @override
  final String providerId;

  AuthCredentialImpl({this.providerId = localProviderId});
}

class UserRecordRest implements UserRecord {
  UserRecordRest({required this.disabled, required this.emailVerified});

  @override
  dynamic get customClaims => null;

  @override
  final bool disabled;

  @override
  String? displayName;

  @override
  String? email;

  @override
  final bool emailVerified;

  @override
  UserMetadata? get metadata => null;

  @override
  String? get passwordHash => null;

  @override
  String? get passwordSalt => null;

  @override
  String? get phoneNumber => null;

  @override
  String? photoURL;

  @override
  List<UserInfo>? get providerData => null;

  @override
  String? get tokensValidAfterTime => null;

  @override
  late String uid;

  UserInfo toUserInfo() {
    return UserInfoRest(uid: uid, provider: null)
      ..email = email
      ..displayName = displayName;
  }

  User toUser() {
    return UserRest(uid: uid, emailVerified: emailVerified, provider: null)
      ..email = email
      ..displayName = displayName;
  }

  @override
  String toString() {
    return 'email: $email ($emailVerified) $displayName, $uid';
  }
}

class UserInfoRest implements UserInfo, UserInfoWithIdToken {
  AccessCredentials? accessCredentials; // For current user only
  final AuthProviderRest? provider;
  @override
  String? displayName;

  @override
  String? email;

  UserInfoRest({required this.uid, this.provider});

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
  Future<String> getIdToken({bool? forceRefresh}) async {
    if (provider != null) {
      return provider!.getIdToken(forceRefresh: forceRefresh);
    }
    throw UnsupportedError('message');
  }
}

/// Top level class
class UserRest extends UserInfoRest implements User {
  @override
  final bool emailVerified;

  UserRest(
      {required this.emailVerified,
      required String uid,
      required AuthProviderRest? provider})
      : super(uid: uid, provider: provider);

  @override
  bool get isAnonymous => false;

  @override
  String toString() {
    return super.toString() + ', emailVerified: $emailVerified';
  }
}

/// Custom auth rest
abstract class AuthRest implements Auth {
  Client? get client;

  /// Custom AuthRest
  factory AuthRest(
      {required AppRest appRest, String? rootUrl, String? servicePathBase}) {
    return AuthRestImpl(appRest,
        rootUrl: rootUrl, servicePathBase: servicePathBase);
  }

  void addProvider(AuthProviderRest authProviderRest);
}

/// Common management
mixin AuthRestMixin {
  final providers = <AuthProviderRest>[];
  void addProvider(AuthProviderRest authProviderRest) {
    providers.add(authProviderRest);
  }
}

class AuthRestImpl with AuthMixin, AuthRestMixin implements AuthRest {
  @override
  Client? client;
  AuthSignInResultRest? signInResultRest;
  final AppRest? _appRest;

  // ignore: unused_field
  final App _app;
  IdentityToolkitApi? _identitytoolkitApi;
  String? rootUrl;
  String? servicePathBase;

  @override
  User? get currentUser {
    var result = signInResultRest;
    if (result != null) {
      return UserRest(
          provider: result.provider,
          emailVerified: result.credential.user.emailVerified,
          uid: result.credential.user.uid);
    }
    return null;
  }

  IdentityToolkitApi get identitytoolkitApi => _identitytoolkitApi ??= () {
        if (rootUrl != null || servicePathBase != null) {
          var defaultRootUrl = 'https://www.googleapis.com/';

          var defaultServicePath = 'identitytoolkit/v3/relyingparty/';
          return IdentityToolkitApi(_appRest!.client!,
              servicePath: servicePathBase == null
                  ? defaultServicePath
                  : '$servicePathBase/$defaultServicePath',
              rootUrl: rootUrl ?? defaultRootUrl);
        } else {
          return IdentityToolkitApi(_appRest!.client!);
        }
      }();

  AuthRestImpl(this._app, {this.rootUrl, this.servicePathBase})
      : _appRest = (_app is AppRest ? _app : null);

  //String get localPath => _appLocal?.localPath;

  // Take first provider
  @override
  Stream<User?> get onCurrentUser {
    for (var provider in providers) {
      try {
        return provider.onCurrentUser.map((event) {
          client = provider.currentAuthClient;
          return event;
        });
      } catch (_) {}
    }
    throw UnsupportedError('onCurrentUser');
  }

  @override
  Future<ListUsersResult> listUsers(
      {int? maxResults, String? pageToken}) async {
    throw UnsupportedError('listUsers');
  }

  @override
  Future<UserRecord?> getUser(String uid) async {
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
      var restUserInfo = result.users!.first;
      return toUserRecord(restUserInfo);
    }
    return null;
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
    var users = (result.users ?? <api.UserInfo>[]);
    return users
        .map((restUserInfo) => toUserRecord(restUserInfo))
        .toList(growable: false);
  }

  @override
  Future<UserRecord> getUserByEmail(String email) async {
    throw UnsupportedError('getUserByEmail');
  }

  @override
  Future<AuthSignInResult> signIn(AuthProvider authProvider,
      {AuthSignInOptions? options}) async {
    if (authProvider is AuthProviderRest) {
      var result = await authProvider.signIn();
      if (result is AuthSignInResultRest) {
        client = result.client;
        // Set in global too.
        // ignore: deprecated_member_use
        (_appRest as AppRest).client = client;
        signInResultRest = result;
      }
      return result;
    } else {
      throw UnsupportedError('signIn');
    }
  }

  @override
  Future signOut() async {
    throw UnsupportedError('signOut');
  }

  @override
  String toString() => _appRest?.name ?? 'local';

  @override
  Future<DecodedIdToken> verifyIdToken(String idToken,
      {bool? checkRevoked}) async {
    throw UnsupportedError('verifyIdToken');
  }

  @override
  Future<User> reloadCurrentUser() {
    throw UnsupportedError('reloadCurrentUser');
  }
}

class DecodedIdTokenLocal implements DecodedIdToken {
  @override
  final String uid;

  DecodedIdTokenLocal({required this.uid});
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
  bool get supportsCurrentUser => true;
}

AuthServiceRest? _authServiceRest;

AuthServiceRest get authServiceLocal => _authServiceRest ??= AuthServiceRest();

AuthService get authService => authServiceLocal;

class AuthAccountApi {
  final String apiKey;
  var client = Client();

  AuthAccountApi({required this.apiKey});

//  Future signInWithIdp() {}
  void dispose() {
    client.close();
  }
}

/// Extra rest information
abstract class AuthProviderRest implements AuthProvider {
  Future<AuthSignInResult> signIn();
  Stream<User?> get onCurrentUser;
  Future<String> getIdToken({bool? forceRefresh});

  /// Current auto client
  AuthClient get currentAuthClient;
}

UserRecord toUserRecord(api.UserInfo restUserInfo) {
  var userRecord = UserRecordRest(
      emailVerified: restUserInfo.emailVerified ?? false, disabled: false);
  userRecord.email = restUserInfo.email;
  userRecord.displayName = restUserInfo.displayName;
  userRecord.uid = restUserInfo.localId!;
  userRecord.photoURL = restUserInfo.photoUrl;
  return userRecord;
}
