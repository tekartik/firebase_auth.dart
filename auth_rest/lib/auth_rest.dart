import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth_rest/src/auth_rest.dart' as auth_rest;

export 'package:tekartik_firebase_auth_rest/src/auth_rest.dart'
    show
        AuthRest,
        AuthRestExt,
        // ignore: deprecated_member_use_from_same_package
        AuthRestProvider,
        UserRecordRest,
        PromptUserForConsentRest,
        AuthProviderRest;
export 'package:tekartik_firebase_auth_rest/src/google_auth_rest.dart'
    show GoogleAuthOptions;

AuthService get authServiceRest => auth_rest.authService;
@Deprecated('Use authServiceRest')
AuthService get authService => authServiceRest;

/// Build an authorization header.
String getAuthorizationHeader(String token) => 'Bearer $token';

/// Parse authorization header
String parseAuthorizationHeaderToken(String authorization) {
  var parts = authorization.split(' ');
  return parts[1];
}
