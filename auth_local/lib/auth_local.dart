import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth_local/src/auth_local.dart' as auth_local;
export 'package:tekartik_firebase_auth_local/src/auth_local.dart'
    show
        AuthLocal,
        localAdminUser,
        localRegularUser,
        AuthLocalSignInOptions,
        AuthLocalProvider,
        UserRecordLocal;

AuthService get authServiceLocal => auth_local.authService;
AuthService get authService => authServiceLocal;
