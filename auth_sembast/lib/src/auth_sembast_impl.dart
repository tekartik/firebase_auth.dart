import 'package:path/path.dart' as p;
import 'package:tekartik_app_cv_sembast/app_cv_sembast.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_auth/auth_mixin.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

const _authSembastProviderId = 'sembast';

/// Firebase auth Sembast service
abstract class FirebaseAuthServiceSembast implements FirebaseAuthService {
  /// Constructor
  factory FirebaseAuthServiceSembast(
          {required DatabaseFactory databaseFactory}) =>
      FirebaseAuthServiceSembastImpl(databaseFactory: databaseFactory);
}

var _cvInitialized = () {
  cvAddConstructors([DbUser.new, DbCurrentUser.new]);
}();

/// Firebase auth Sembast implementation
class FirebaseAuthServiceSembastImpl
    with FirebaseProductServiceMixin<FirebaseAuth>, FirebaseAuthServiceMixin
    implements FirebaseAuthServiceSembast {
  @override
  bool get supportsListUsers => false; // For now

  @override
  bool get supportsCurrentUser => true;

  /// Database factory
  final DatabaseFactory databaseFactory;

  /// Constructor
  FirebaseAuthServiceSembastImpl({required this.databaseFactory}) {
    // ignore: unnecessary_statements
    _cvInitialized;
  }

  @override
  FirebaseAuthSembast auth(FirebaseApp app) {
    return getInstance(app, () {
      assert(app is FirebaseAppLocal, 'invalid app type - not AppLocal');
      // final appLocal = app as AppLocal;
      return FirebaseAuthSembastImpl(this, app as FirebaseAppLocal);
    }) as FirebaseAuthSembast;
  }
}

/// Firebase auth Sembast
abstract class FirebaseAuthSembast implements FirebaseAuth {
  /// Set/Create user
  Future<void> setUser(String uid,
      {required String email, bool? emailVerified});
}

/// User record
class DbUser extends DbStringRecordBase {
  /// Email
  final email = CvField<String>('email');

  /// Email verified
  final emailVerified = CvField<bool>('emailVerified');

  @override
  CvFields get fields => [email, emailVerified];
}

/// User mode
final dbUserModel = DbUser();

/// Current user info
class DbCurrentUser extends DbStringRecordBase {
  /// Uid
  final uid = CvField<String>('uid');

  @override
  CvFields get fields => [uid];
}

var _currentUserStore = cvStringStoreFactory.store<DbCurrentUser>('info');
var _currentUserRecord = _currentUserStore.record('currentUser');
var _userStore = cvStringStoreFactory.store<DbUser>('user');

/// Firebase auth Sembast implementation
class FirebaseAuthSembastImpl
    with FirebaseAppProductMixin<FirebaseAuth>, FirebaseAuthMixin
    implements FirebaseAuthSembast {
  StreamSubscription? _currentUserRecordSubscription;
  StreamSubscription? _currentUserSubscription;

  @override
  Future<void> setUser(String uid,
      {required String email, bool? emailVerified}) async {
    await _ready;
    await _database.transaction((txn) async {
      await _userStore.delete(txn, finder: Finder(filter: _emailFilter(email)));
      await _userStore.record(uid).put(
          txn,
          DbUser()
            ..email.v = email
            ..emailVerified.v = emailVerified);
    });
  }

  UserRecord? _dbUserToRecordOrNull(DbUser? dbUser) {
    return dbUser == null ? null : _UserRecordSembast(dbUser);
  }

  @override
  Future<UserRecord?> getUserByEmail(String email) async {
    await _ready;
    var dbUser = await _database.transaction((txn) async {
      return _txnGetUserByEmail(txn, email);
    });
    return _dbUserToRecordOrNull(dbUser);
  }

  Filter _emailFilter(String email) {
    return Filter.equals(dbUserModel.email.name, email);
  }

  Future<DbUser?> _txnGetUserByEmail(Transaction txn, String email) async {
    await _ready;
    var dbUser = await _userStore.findFirst(txn,
        finder: Finder(filter: _emailFilter(email)));
    return dbUser;
  }

  @override
  Future<UserRecord?> getUser(String uid) async {
    await _ready;
    var dbUser = await _userStore.record(uid).get(_database);
    return _dbUserToRecordOrNull(dbUser);
  }

  /// Sembast database
  late Database _database;

  /// App local
  final FirebaseAppLocal appLocal;
  late final _ready = () async {
    _database = await authServiceSembast.databaseFactory
        .openDatabase(p.join(appLocal.localPath, 'auth.db'));
    _currentUserRecordSubscription =
        _currentUserRecord.onRecord(_database).listen((record) {
      _currentUserSubscription?.cancel();
      var uid = record?.uid.v;

      if (uid != null) {
        _currentUserSubscription =
            _userStore.record(uid).onRecord(_database).listen((record) {
          var dbUser = record;
          if (dbUser != null) {
            currentUserAdd(_FirebaseUserSembast(dbUser));
          } else {
            _currentUserRecord.delete(_database);
          }
        });
      } else {
        currentUserAdd(null);
      }
    });
  }();

  /// The service
  final FirebaseAuthServiceSembastImpl authServiceSembast;

  /// Constructor
  FirebaseAuthSembastImpl(this.authServiceSembast, this.appLocal);

  @override
  Future<UserCredential> signInWithEmailAndPassword(
      {required String email, required String password}) async {
    await _ready;
    var dbUser = await _database.transaction((txn) async {
      var dbUser = await _userStore.findFirst(txn,
          finder: Finder(filter: Filter.equals(dbUserModel.email.name, email)));
      dbUser ??= await _userStore.add(txn, DbUser()..email.v = email);
      await _currentUserRecord.put(txn, DbCurrentUser()..uid.v = dbUser.id);
      // Also set the current user directly
      currentUserAdd(_FirebaseUserSembast(dbUser));
      return dbUser;
    });

    return _FirebaseUserCredentialSembast(dbUser);
  }

  @override
  Future<void> signOut() async {
    // ignore: unnecessary_statements
    await _ready;
    await _currentUserRecord.delete(_database);
    currentUserAdd(null);
  }

  @override
  Stream<User?> get onCurrentUser {
    _ready.unawait();
    return super.onCurrentUser;
  }

  @override
  Future<User?> reloadCurrentUser() {
    // TODO: implement reloadCurrentUser
    throw UnimplementedError();
  }

  /// Dispose
  @override
  void dispose() {
    _currentUserRecordSubscription?.cancel();
    _currentUserSubscription?.cancel();
    super.dispose();
  }

  @override
  FirebaseApp get app => appLocal;

  @override
  FirebaseAuthService get service => authServiceSembast;
}

/// User Sembast
class _FirebaseUserSembast with FirebaseUserMixin {
  @override
  String get uid => _dbUser.id;

  @override
  String? get email => _dbUser.email.v;

  @override
  String? get displayName => null;

  final DbUser _dbUser;

  _FirebaseUserSembast(this._dbUser);
}

/// User credential Sembast
class _FirebaseUserCredentialSembast with FirebaseUserCredentialMixin {
  final DbUser _dbUser;

  /// Constructor
  _FirebaseUserCredentialSembast(this._dbUser);

  @override
  late final user = _FirebaseUserSembast(_dbUser);

  @override
  late final credential = _FirebaseAuthCredentialSembast();
}

class _FirebaseAuthCredentialSembast
    with FirebaseAuthCredentialMixin
    implements FirebaseAuthCredential {
  @override
  String get providerId => _authSembastProviderId;
}

class _UserRecordSembast with FirebaseUserRecordDefaultMixin {
  final DbUser dbUser;

  _UserRecordSembast(this.dbUser);

  @override
  String? get displayName => null;

  @override
  String get uid => dbUser.id;

  @override
  bool get emailVerified => dbUser.emailVerified.v ?? false;

  @override
  String? get email => dbUser.email.v;
}
