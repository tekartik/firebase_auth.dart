import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth_local/src/auth_local.dart' as auth_local;

AuthService get authServiceLocal => auth_local.authService;
AuthService get authService => authServiceLocal;
