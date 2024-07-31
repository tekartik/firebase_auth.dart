import 'package:sembast/sembast.dart';
import 'package:tekartik_firebase/firebase.dart';
// ignore: implementation_imports
import 'package:tekartik_firebase_auth_local/src/auth_local.dart';

/// Firebase auth Sembast service
class FirebaseAuthServiceSembast extends AuthServiceLocal {
  /// Constructor
  factory FirebaseAuthServiceSembast(
          {required DatabaseFactory databaseFactory}) =>
      FirebaseAuthServiceSembastImpl(databaseFactory: databaseFactory);
}

/// Firebase auth Sembast implementation
class FirebaseAuthServiceSembastImpl extends AuthServiceLocal
    implements FirebaseAuthServiceSembast {
  /// Database factory
  final DatabaseFactory databaseFactory;

  /// Constructor
  FirebaseAuthServiceSembastImpl({required this.databaseFactory});
  @override
  FirebaseAuthSembast auth(FirebaseApp app) {
    return getInstance(app, () {
      // assert(app is AppLocal, 'invalid app type - not AppLocal');
      // final appLocal = app as AppLocal;
      return FirebaseAuthSembastImpl(this, app);
    });
  }
}

/// Firebase auth Sembast
abstract class FirebaseAuthSembast implements AuthLocal {}

/// Firebase auth Sembast implementation
class FirebaseAuthSembastImpl extends AuthLocalImpl
    implements FirebaseAuthSembast {
  /// The service
  final FirebaseAuthServiceSembast authServiceSembast;

  /// Constructor
  FirebaseAuthSembastImpl(this.authServiceSembast, super.app);
}
