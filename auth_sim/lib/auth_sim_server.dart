/// Server side of the firebase auth sim: register
/// `FirebaseAuthSimPlugin(firebaseAuthSimServerService:
/// FirebaseAuthSimServerService(), firebaseAuthService: <a local auth>)` in
/// `firebaseSimServe(..., plugins: [...])` (Dart VM only).
library;

export 'src/auth_sim_plugin.dart' show FirebaseAuthSimPlugin;
export 'src/auth_sim_server_service.dart' show FirebaseAuthSimServerService;
