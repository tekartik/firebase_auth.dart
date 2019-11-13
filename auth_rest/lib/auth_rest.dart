import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth_rest/src/auth_rest.dart' as auth_rest;
export 'package:tekartik_firebase_auth_rest/src/auth_rest.dart'
    show AuthRest, AuthRestProvider, UserRecordRest;

AuthService get authServiceRest => auth_rest.authService;
AuthService get authService => authServiceRest;
