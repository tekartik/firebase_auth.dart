import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth_local/src/auth_local.dart' as auth_local;
import 'package:tekartik_firebase_local/firebase_local.dart';

export 'package:tekartik_firebase_auth_local/src/auth_local.dart'
    show
        AuthLocal,
        localAdminUser,
        localRegularUser,
        AuthLocalSignInOptions,
        AuthLocalProvider,
        UserRecordLocal;

AuthService get authServiceLocal => auth_local.authService;
@Deprecated('Use authServiceLocal')
AuthService get authService => authServiceLocal;

/// For unit test
AuthService newAuthServiceLocal() => auth_local.AuthServiceLocal();

/// Quick firestore test helper
Auth newAuthLocal() => newAuthServiceLocal().auth(newFirebaseAppLocal());
