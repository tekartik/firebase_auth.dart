/// Decodes ([FirebaseAuthInfo.fromIdToken]) and verifies
/// ([FirebaseAuthInfo.verify]) a Firebase Authentication ID token.
///
/// `verify` checks the signature and the time claims only: compare
/// [FirebaseAuthInfo.projectId] with your project id.
library;

export 'package:tekartik_firebase_auth_jwt/src/auth_info.dart'
    show
        FirebaseAuthInfo,
        FirebaseAuthException,
        FirebaseAuthValidationException;
