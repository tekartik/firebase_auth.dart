import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth_rest/src/auth_rest.dart' as auth_rest;
export 'package:tekartik_firebase_auth_rest/src/auth_rest.dart'
    show AuthRest, AuthRestProvider, UserRecordRest;

AuthService get authServiceRest => auth_rest.authService;
AuthService get authService => authServiceRest;

/// Build an authorization header.
String getAuthorizationHeader(String token) => 'Bearer $token';

/// Parse authorization header
String parseAuthorizationHeaderToken(String authorization) {
  var parts = authorization.split(' ');
  return parts[1];
}
