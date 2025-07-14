import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth_sim/src/auth_sim_service.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';

/// Auth sim plugin
class FirebaseAuthSimPlugin implements FirebaseSimPlugin {
  /// Firebase auth sim service
  final FirebaseAuthSimService firebaseAuthSimService;

  /// Firebase auth service
  final FirebaseAuthService firebaseAuthService;

  /// Auth sim plugin
  FirebaseAuthSimPlugin({
    required this.firebaseAuthSimService,
    required this.firebaseAuthService,
  }) {
    firebaseAuthSimService.firebaseAuthSimPlugin = this;
  }

  @override
  FirebaseSimServiceBase get simService => firebaseAuthSimService;
}
