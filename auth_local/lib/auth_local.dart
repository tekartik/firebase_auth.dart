import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth_local/src/auth_local.dart' as auth_local;
import 'package:tekartik_firebase_local/firebase_local.dart';

export 'package:tekartik_firebase_auth_local/src/auth_local.dart'
    show
        FirebaseAuthServiceLocal,
        AuthLocal,
        localAdminUser,
        localRegularUser,
        AuthLocalSignInOptions,
        AuthLocalProvider,
        UserRecordLocal;

FirebaseAuthService get authServiceLocal => auth_local.authService;

@Deprecated('Use authServiceLocal')
FirebaseAuthService get authService => authServiceLocal;

/// For unit test
FirebaseAuthService newAuthServiceLocal() => auth_local.AuthServiceLocal();

/// Quick firestore test helper
FirebaseAuth newAuthLocal() =>
    newAuthServiceLocal().auth(newFirebaseAppLocal());
