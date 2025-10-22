import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth_sim/src/auth_sim_server_service.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server_mixin.dart';

/// Auth sim plugin
class FirebaseAuthSimPlugin
    with FirebaseSimPluginDefaultMixin
    implements FirebaseSimPlugin {
  /// Firebase auth sim service
  final FirebaseAuthSimServerService firebaseAuthSimServerService;

  /// Firebase auth service
  final FirebaseAuthService firebaseAuthService;

  /// Auth sim plugin
  FirebaseAuthSimPlugin({
    required this.firebaseAuthSimServerService,
    required this.firebaseAuthService,
  }) {
    firebaseAuthSimServerService.firebaseAuthSimPlugin = this;
  }

  @override
  FirebaseSimServerService get simService => firebaseAuthSimServerService;
}
