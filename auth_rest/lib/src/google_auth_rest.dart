import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth_rest/src/auth_rest.dart';
import 'package:tekartik_firebase_auth_rest/src/fb_api/secureapi.dart';
import 'package:tekartik_firebase_auth_rest/src/identitytoolkit/v3.dart'
    hide UserInfo;

import 'identitytoolkit/v3.dart';

Future<UserRecord?> getUser(AuthClient client, String uid) async {
  var request = IdentitytoolkitRelyingpartyGetAccountInfoRequest()
      //  ..localId = [uid]
      ;
  if (debugRest) {
    print('getAccountInfoRequest2: ${jsonPretty(request.toJson())}');
  }
  var identitytoolkitApi = IdentityToolkitApi(client);
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

mixin GoogleRestAuthProviderMixin implements GoogleRestAuthProvider {
  AuthClient get client;
  String get apiKey;
  final _scopes = <String>[];
  @override
  String get providerId => 'googleapis_auth';

  /// Adds additional OAuth 2.0 scopes that you want to request from the
  /// authentication provider.
  @override
  void addScope(String scope) {
    _scopes.add(scope);
  }

  @override
  Future<String> getIdToken({bool? forceRefresh}) async {
    var secuApi = SecureTokenApi(apiKey: apiKey, client: client);
    var token = await secuApi.getIdToken(forceRefresh: forceRefresh);
    return token;
  }
}

abstract class GoogleRestAuthProvider implements AuthProviderRest {
  void addScope(String scope);
}

class GoogleAuthOptions {
  // The developer key needed for the picker API
  String? developerKey;
  // The Client ID obtained from the Google Cloud Console.
  String? clientId;
  // The Client Secret obtained from the Google Cloud Console.
  String? clientSecret;

  // The API key for auth
  String? apiKey;
  String? projectId;

  GoogleAuthOptions(
      {this.developerKey,
      this.clientId,
      this.clientSecret,
      this.apiKey,
      this.projectId});

  GoogleAuthOptions.fromMap(Map<String, dynamic> map) {
    developerKey = map['developerKey']?.toString();
    apiKey = map['apiKey']?.toString();
    clientId = map['clientId']?.toString();
    clientSecret = map['clientSecret']?.toString();
    projectId = map['projectId']?.toString();
  }

  @override
  String toString() => {
        'developerKey': developerKey,
        'clientId': clientId,
        'clientSecret': clientSecret,
        'projectId': projectId,
        'apiKey': apiKey
      }.toString();
}

class AuthSignInResultRest implements AuthSignInResult {
  final AuthProviderRest provider;
  final AuthClient client;
  @override
  late UserCredential credential;

  @override
  late bool hasInfo;

  AuthSignInResultRest({required this.provider, required this.client});
  @override
  String toString() => 'Result($hasInfo, $credential)';
}
