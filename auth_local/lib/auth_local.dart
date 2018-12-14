import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth_local/src/auth_local.dart' as _;

AuthService get authServiceLocal => _.authService;
AuthService get authService => authServiceLocal;
