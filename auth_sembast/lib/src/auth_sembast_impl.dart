import 'package:path/path.dart' as p;
import 'package:sembast/timestamp.dart';
import 'package:tekartik_app_cv_sembast/app_cv_sembast.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_auth/auth_admin.dart';
import 'package:tekartik_firebase_auth/auth_mixin.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

const _authSembastProviderId = 'sembast';

/// Firebase auth Sembast service
abstract class FirebaseAuthServiceSembast implements FirebaseAuthService {
  /// Constructor
  factory FirebaseAuthServiceSembast({
    required DatabaseFactory databaseFactory,
  }) => FirebaseAuthServiceSembastImpl(databaseFactory: databaseFactory);
}

/// Init db builders
void firebaseAuthSembastInitDbBuilders() {
  cvAddConstructors([DbUser.new, DbCurrentUser.new]);
}

var _cvInitialized = () {
  firebaseAuthSembastInitDbBuilders();
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
        })
        as FirebaseAuthSembast;
  }
}

/// Firebase auth Sembast
abstract class FirebaseAuthSembast
    implements FirebaseAuth, FirebaseAuthLocalAdmin, FirebaseAuthAdmin {}

/// User record
class DbUser extends DbStringRecordBase {
  /// Creation date
  final created = CvField<Timestamp>('created');

  /// Name
  final name = CvField<String>('name');

  /// Email
  final email = CvField<String>('email');

  /// Email verified
  final emailVerified = CvField<bool>('emailVerified');

  /// Anonymous
  final isAnonymous = CvField<bool>('isAnonymous');

  /// Disabled
  final disabled = CvField<bool>('disabled');

  /// Phone number
  final phoneNumber = CvField<String>('phoneNumber');

  /// Photo URL
  final photoURL = CvField<String>('photoURL');

  /// Local password
  final localPassword = CvField<String>('localPassword');

  @override
  CvFields get fields => [
    created,
    name,
    email,
    emailVerified,
    isAnonymous,
    disabled,
    phoneNumber,
    photoURL,
    localPassword,
  ];
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

/// Current user id
var firebaseAuthCurrentUserRecord = _currentUserStore.record('currentUser');
var _userStore = cvStringStoreFactory.store<DbUser>('user');

/// Firebase auth Sembast implementation
class FirebaseAuthSembastImpl
    with
        FirebaseAppProductMixin<FirebaseAuth>,
        FirebaseAuthMixin,
        FirebaseAuthLocalAdminDefaultMixin
    implements FirebaseAuthSembast {
  StreamSubscription? _currentUserRecordSubscription;
  StreamSubscription? _currentUserSubscription;

  @override
  Future<void> setUser(
    String uid, {
    String? email,
    bool? emailVerified,
    bool? isAnonymous,
  }) async {
    await _ready;
    await _database.transaction((txn) async {
      if (email != null) {
        await _userStore.delete(
          txn,
          finder: Finder(filter: _emailFilter(email)),
        );
      }
      await _userStore
          .record(uid)
          .put(
            txn,

            DbUser()
              ..email.v = email
              ..emailVerified.setValue(emailVerified)
              ..isAnonymous.setValue(isAnonymous),
          );
    });
  }

  @override
  Future<UserRecord> createUser(FirebaseAuthCreateUserRequest request) async {
    await _ready;
    var dbUser = await _database.transaction((txn) async {
      var uid = request.uid;
      if (uid != null) {
        var existing = await _userStore.record(uid).get(txn);
        if (existing != null) {
          throw StateError('uid-already-exists');
        }
      }
      var email = request.email;
      if (email != null) {
        var existing = await _userStore.findFirst(
          txn,
          finder: Finder(filter: _emailFilter(email)),
        );
        if (existing != null) {
          throw StateError('email-already-exists');
        }
      }

      var created = Timestamp.now();
      var user = DbUser()
        ..created.v = created
        ..name.v = request.displayName
        ..email.v = email
        ..emailVerified.v = request.emailVerified
        ..isAnonymous.v = false
        ..disabled.v = request.disabled
        ..phoneNumber.v = request.phoneNumber
        ..photoURL.v = request.photoURL
        ..localPassword.v = request.password;

      if (uid != null) {
        await _userStore.record(uid).put(txn, user);
        return (await _userStore.record(uid).get(txn))!;
      } else {
        var added = await _userStore.add(txn, user);
        return added;
      }
    });
    return _UserRecordSembast(dbUser);
  }

  @override
  Future<void> deleteUser(String uid) async {
    await _ready;
    await _database.transaction((txn) async {
      await _userStore.record(uid).delete(txn);
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
    var dbUser = await _userStore.findFirst(
      txn,
      finder: Finder(filter: _emailFilter(email)),
    );
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
    _database = await authServiceSembast.databaseFactory.openDatabase(
      p.join(appLocal.localPath, 'auth.db'),
    );
    _currentUserRecordSubscription = firebaseAuthCurrentUserRecord
        .onRecord(_database)
        .listen((record) {
          _currentUserSubscription?.cancel();
          var uid = record?.uid.v;

          if (uid != null) {
            _currentUserSubscription = _userStore
                .record(uid)
                .onRecord(_database)
                .listen((record) {
                  var dbUser = record;
                  if (dbUser != null) {
                    currentUserAdd(_FirebaseUserSembast(this, dbUser));
                  } else {
                    firebaseAuthCurrentUserRecord.delete(_database);
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
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await createUser(
      FirebaseAuthCreateUserRequest(email: email, password: password),
    );

    return signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _ready;
    var dbUser = await _database.transaction((txn) async {
      var dbUser = await _txnGetSignInWithEmailAndPasswordUserCredentialOrThrow(
        txn,
        email: email,
        password: password,
      );
      await firebaseAuthCurrentUserRecord.put(
        txn,

        DbCurrentUser()..uid.v = dbUser.id,
      );
      // Also set the current user directly
      currentUserAdd(_FirebaseUserSembast(this, dbUser));
      return dbUser;
    });

    return _FirebaseUserCredentialSembast(this, dbUser);
  }

  Future<DbUser> _txnGetSignInWithEmailAndPasswordUserCredentialOrThrow(
    Transaction txn, {
    required String email,
    required String password,
  }) async {
    var dbUser = await _userStore.findFirst(
      txn,
      finder: Finder(filter: Filter.equals(dbUserModel.email.name, email)),
    );
    if (dbUser == null) {
      throw StateError('user-not-found');
    }
    if (dbUser.localPassword.v != null && dbUser.localPassword.v != password) {
      throw StateError('wrong-password');
    }
    return dbUser;
  }

  Future<DbUser> _txnGetSignInWithEmailAndPasswordUserCredential(
    Transaction txn, {
    required String email,
    required String password,
  }) async {
    var dbUser = await _userStore.findFirst(
      txn,
      finder: Finder(filter: Filter.equals(dbUserModel.email.name, email)),
    );
    dbUser ??= await _userStore.add(txn, DbUser()..email.v = email);
    return dbUser;
  }

  @override
  Future<UserCredential> getSignInWithEmailAndPasswordUserCredential({
    required String email,
    required String password,
  }) async {
    await _ready;
    var dbUser = await _database.transaction((txn) async {
      var dbUser = await _txnGetSignInWithEmailAndPasswordUserCredential(
        txn,
        email: email,
        password: password,
      );
      return dbUser;
    });

    return _FirebaseUserCredentialSembast(this, dbUser);
  }

  Future<DbUser> _txnGetSignInAnonymouslyUserCredential(Transaction txn) async {
    /// Delete old existing
    await _userStore.delete(
      txn,
      finder: Finder(
        filter: Filter.and([
          Filter.equals(dbUserModel.isAnonymous.name, true),
          Filter.or([
            Filter.isNull(dbUserModel.created.name),
            Filter.lessThan(
              dbUserModel.created.name,
              Timestamp.now().addDuration(const Duration(days: 30)),
            ),
          ]),
        ]),
      ),
    );
    var created = Timestamp.now();
    var dbUser = await _userStore.add(
      txn,

      DbUser()
        ..created.v = created
        ..name.v = 'Anonymous ${created.toIso8601String()}'
        ..isAnonymous.v = true,
    );
    return dbUser;
  }

  @override
  Future<UserCredential> signInAnonymously() async {
    await _ready;
    var dbUser = await _database.transaction((txn) async {
      var dbUser = await _txnGetSignInAnonymouslyUserCredential(txn);
      await firebaseAuthCurrentUserRecord.put(
        txn,

        DbCurrentUser()..uid.v = dbUser.id,
      );
      // Also set the current user directly
      currentUserAdd(_FirebaseUserSembast(this, dbUser));
      return dbUser;
    });

    return _FirebaseUserCredentialSembast(this, dbUser);
  }

  @override
  Future<UserCredential> getSignInAnonymouslyUserCredential() async {
    await _ready;
    var dbUser = await _database.transaction((txn) async {
      var dbUser = await _txnGetSignInAnonymouslyUserCredential(txn);
      return dbUser;
    });

    return _FirebaseUserCredentialSembast(this, dbUser);
  }

  @override
  Future<void> signOut() async {
    // ignore: unnecessary_statements
    await _ready;

    await _database.transaction((txn) async {
      var currentUser = await firebaseAuthCurrentUserRecord.get(txn);
      if (currentUser != null) {
        var id = currentUser.uid.v!;

        var record = _userStore.record(id);
        var dbUser = await record.get(txn);
        if (dbUser?.isAnonymous.v == true) {
          await record.delete(txn);
        }

        await firebaseAuthCurrentUserRecord.delete(txn);
      }
    });

    currentUserAdd(null);
  }

  @override
  Stream<User?> get onCurrentUser {
    _ready.unawait();
    return super.onCurrentUser;
  }

  @override
  Future<User?> reloadCurrentUser() async {
    return currentUser;
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

  @override
  Stream<UserRecord?> onUserRecord(String uid) async* {
    await _ready;
    yield* _userStore.record(uid).onRecord(_database).map((record) {
      if (record == null) {
        return null;
      }
      return _UserRecordSembast(record);
    });
  }
}

/// User Sembast
class _FirebaseUserSembast with FirebaseUserMixin {
  final FirebaseAuthSembast auth;
  @override
  String get uid => _dbUser.id;

  @override
  String? get email => _dbUser.email.v;

  @override
  bool get isAnonymous => _dbUser.isAnonymous.v ?? false;
  @override
  bool get emailVerified => _dbUser.emailVerified.v ?? false;

  @override
  String? get displayName => _dbUser.name.v;

  final DbUser _dbUser;

  _FirebaseUserSembast(this.auth, this._dbUser);

  @override
  Future<void> delete() async {
    await auth.deleteUser(uid);
    await auth.signOut();
  }
}

/// User credential Sembast
class _FirebaseUserCredentialSembast with FirebaseUserCredentialMixin {
  final FirebaseAuthSembast auth;
  final DbUser _dbUser;

  /// Constructor
  _FirebaseUserCredentialSembast(this.auth, this._dbUser);

  @override
  late final user = _FirebaseUserSembast(auth, _dbUser);

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
  String? get displayName => dbUser.name.v;

  @override
  String get uid => dbUser.id;

  @override
  bool get emailVerified => dbUser.emailVerified.v ?? false;

  @override
  bool get isAnonymous => dbUser.isAnonymous.v ?? false;

  @override
  String? get email => dbUser.email.v;

  @override
  bool get disabled => dbUser.disabled.v ?? false;

  @override
  String? get phoneNumber => dbUser.phoneNumber.v;

  @override
  String? get photoURL => dbUser.photoURL.v;
}
