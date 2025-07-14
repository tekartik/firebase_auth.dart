import 'package:sembast/sembast.dart';
import 'package:tekartik_firebase_auth/auth_mixin.dart';
import 'package:tekartik_firebase_auth_sim/src/auth_sim.dart';
import 'package:tekartik_firebase_sim/firebase_sim.dart';

import 'auth_sim_message.dart';

/// Auth service sim
abstract class FirebaseAuthServiceSim implements FirebaseAuthService {
  /// database factory to store local current user id
  factory FirebaseAuthServiceSim({required DatabaseFactory databaseFactory}) =>
      _FirebaseAuthServiceSim(databaseFactory: databaseFactory);
}

class _FirebaseAuthServiceSim
    with FirebaseProductServiceMixin<FirebaseAuth>, FirebaseAuthServiceMixin
    implements FirebaseAuthServiceSim {
  final DatabaseFactory databaseFactory;

  _FirebaseAuthServiceSim({required this.databaseFactory}) {
    initAuthSimBuilders();
  }
  @override
  FirebaseAuth auth(App app) {
    return getInstance(app, () {
      assert(app is FirebaseAppSim, 'app not compatible (${app.runtimeType})');
      return FirebaseAuthSim(
        appSim: app as FirebaseAppSim,
        authServiceSim: this,
      );
    });
  }

  @override
  bool get supportsCurrentUser => true;

  @override
  bool get supportsListUsers => true;
}

/// Private extension
extension DatabasFirebaseAuthServiceSimPrvExt on FirebaseAuthServiceSim {
  /// Database factory
  DatabaseFactory get databaseFactory =>
      (this as _FirebaseAuthServiceSim).databaseFactory;
}
