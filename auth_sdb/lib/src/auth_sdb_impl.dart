import 'package:path/path.dart' as p;
import 'package:tekartik_app_cv_sdb/app_cv_sdb.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_auth/auth_admin.dart';
import 'package:tekartik_firebase_auth/auth_mixin.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

const _authSdbProviderId = 'sdb';

/// Firebase auth Sdb service
abstract class FirebaseAuthServiceSdb implements FirebaseAuthService {
  /// Constructor
  factory FirebaseAuthServiceSdb({required SdbFactory sdbFactory}) =>
      FirebaseAuthServiceSdbImpl(sdbFactory: sdbFactory);
}

/// Init db builders
void firebaseAuthSdbInitDbBuilders() {
  cvAddConstructors([DbUser.new, DbCurrentUser.new]);
}

var _cvInitialized = () {
  firebaseAuthSdbInitDbBuilders();
}();

/// Firebase auth Sdb implementation
class FirebaseAuthServiceSdbImpl
    with FirebaseProductServiceMixin<FirebaseAuth>, FirebaseAuthServiceMixin
    implements FirebaseAuthServiceSdb {
  @override
  bool get supportsListUsers => false; // For now

  @override
  bool get supportsCurrentUser => true;

  /// Sdb factory
  final SdbFactory sdbFactory;

  /// Constructor
  FirebaseAuthServiceSdbImpl({required this.sdbFactory}) {
    // ignore: unnecessary_statements
    _cvInitialized;
  }

  @override
  FirebaseAuthSdb auth(FirebaseApp app) {
    return getInstance(app, () {
          assert(app is FirebaseAppLocal, 'invalid app type - not AppLocal');

          return FirebaseAuthSdbImpl(this, app as FirebaseAppLocal);
        })
        as FirebaseAuthSdb;
  }
}

/// Firebase auth Sdb
abstract class FirebaseAuthSdb
    implements FirebaseAuth, FirebaseAuthLocalAdmin, FirebaseAuthAdmin {}

/// User record
class DbUser extends ScvStringRecordBase {
  /// Creation date
  final created = CvField<SdbTimestamp>('created');

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
class DbCurrentUser extends ScvStringRecordBase {
  /// Uid
  final uid = CvField<String>('uid');

  @override
  CvFields get fields => [uid];
}

var _currentUserStore = scvStringStoreFactory.store<DbCurrentUser>('info');

/// Current user id
var firebaseAuthCurrentUserRecord = _currentUserStore.record('currentUser');
var _userStore = scvStringStoreFactory.store<DbUser>('user');

/// Firebase auth Sdb implementation
class FirebaseAuthSdbImpl
    with
        FirebaseAppProductMixin<FirebaseAuth>,
        FirebaseAuthMixin,
        FirebaseAuthLocalAdminDefaultMixin
    implements FirebaseAuthSdb {
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
    await _database.inStoreTransaction(
      _userStore.rawRef,
      SdbTransactionMode.readWrite,
      (txn) async {
        if (email != null) {
          var existing = await _userStore.findRecords(
            txn,
            filter: _emailFilter(email),
          );
          for (var r in existing) {
            await r.delete(txn);
          }
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
      },
    );
  }

  @override
  Future<UserRecord> createUser(FirebaseAuthCreateUserRequest request) async {
    await _ready;
    var dbUser = await _database.inStoreTransaction(
      _userStore.rawRef,
      SdbTransactionMode.readWrite,
      (txn) async {
        var uid = request.uid;
        if (uid != null) {
          var existing = await _userStore.record(uid).get(txn);
          if (existing != null) {
            throw StateError('uid-already-exists');
          }
        }
        var email = request.email;
        if (email != null) {
          var existing = await _userStore.findRecord(
            txn,
            filter: _emailFilter(email),
          );
          if (existing != null) {
            throw StateError('email-already-exists');
          }
        }

        var created = SdbTimestamp.now();
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
      },
    );
    return _UserRecordSdb(dbUser);
  }

  @override
  Future<void> deleteUser(String uid) async {
    await _ready;
    await _database.inStoreTransaction(
      _userStore.rawRef,
      SdbTransactionMode.readWrite,
      (txn) async {
        await _userStore.record(uid).delete(txn);
      },
    );

    await signOut();
  }

  UserRecord? _dbUserToRecordOrNull(DbUser? dbUser) {
    return dbUser == null ? null : _UserRecordSdb(dbUser);
  }

  @override
  Future<UserRecord?> getUserByEmail(String email) async {
    await _ready;
    var dbUser = await _database.inStoreTransaction(
      _userStore.rawRef,
      SdbTransactionMode.readOnly,
      (txn) async {
        return _txnGetUserByEmail(txn, email);
      },
    );
    return _dbUserToRecordOrNull(dbUser);
  }

  SdbFilter _emailFilter(String email) {
    return SdbFilter.equals(dbUserModel.email.name, email);
  }

  Future<DbUser?> _txnGetUserByEmail(SdbTransaction txn, String email) async {
    var dbUser = await _userStore.findRecord(txn, filter: _emailFilter(email));
    return dbUser;
  }

  @override
  Future<UserRecord?> getUser(String uid) async {
    await _ready;
    var dbUser = await _userStore.record(uid).get(_database);
    return _dbUserToRecordOrNull(dbUser);
  }

  /// Sdb database
  late SdbDatabase _database;

  /// App local
  final FirebaseAppLocal appLocal;
  late final _ready = () async {
    var schema = SdbDatabaseSchema(
      stores: [_currentUserStore.schema(), _userStore.schema()],
    );
    _database = await authServiceSdb.sdbFactory.openDatabase(
      p.join(appLocal.localPath, 'auth.db'),
      options: SdbOpenDatabaseOptions(version: 1, schema: schema),
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
                    currentUserAdd(_FirebaseUserSdb(this, dbUser));
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
  final FirebaseAuthServiceSdbImpl authServiceSdb;

  /// Constructor
  FirebaseAuthSdbImpl(this.authServiceSdb, this.appLocal);

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
    var dbUser = await _database.inStoresTransaction(
      [_currentUserStore.rawRef, _userStore.rawRef],
      SdbTransactionMode.readWrite,
      (txn) async {
        var dbUser =
            await _txnGetSignInWithEmailAndPasswordUserCredentialOrThrow(
              txn,
              email: email,
              password: password,
            );
        await firebaseAuthCurrentUserRecord.put(
          txn,

          DbCurrentUser()..uid.v = dbUser.id,
        );
        // Also set the current user directly
        currentUserAdd(_FirebaseUserSdb(this, dbUser));
        return dbUser;
      },
    );

    return _FirebaseUserCredentialSdb(this, dbUser);
  }

  Future<DbUser> _txnGetSignInWithEmailAndPasswordUserCredentialOrThrow(
    SdbTransaction txn, {
    required String email,
    required String password,
  }) async {
    var dbUser = await _userStore.findRecord(
      txn,
      filter: SdbFilter.equals(dbUserModel.email.name, email),
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
    SdbTransaction txn, {
    required String email,
    required String password,
  }) async {
    var dbUser = await _userStore.findRecord(
      txn,
      filter: SdbFilter.equals(dbUserModel.email.name, email),
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
    var dbUser = await _database.inStoreTransaction(
      _userStore.rawRef,
      SdbTransactionMode.readWrite,
      (txn) async {
        var dbUser = await _txnGetSignInWithEmailAndPasswordUserCredential(
          txn,
          email: email,
          password: password,
        );
        return dbUser;
      },
    );

    return _FirebaseUserCredentialSdb(this, dbUser);
  }

  Future<DbUser> _txnGetSignInAnonymouslyUserCredential(
    SdbTransaction txn,
  ) async {
    /// Delete old existing
    var toDelete = await _userStore.findRecords(
      txn,
      filter: SdbFilter.and([
        SdbFilter.equals(dbUserModel.isAnonymous.name, true),
        SdbFilter.or([
          SdbFilter.isNull(dbUserModel.created.name),
          SdbFilter.lessThan(
            dbUserModel.created.name,
            SdbTimestamp.now().addDuration(const Duration(days: 30)),
          ),
        ]),
      ]),
    );
    for (var r in toDelete) {
      await r.delete(txn);
    }
    var created = SdbTimestamp.now();
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
    var dbUser = await _database.inStoresTransaction(
      [_currentUserStore.rawRef, _userStore.rawRef],
      SdbTransactionMode.readWrite,
      (txn) async {
        var dbUser = await _txnGetSignInAnonymouslyUserCredential(txn);
        await firebaseAuthCurrentUserRecord.put(
          txn,

          DbCurrentUser()..uid.v = dbUser.id,
        );
        // Also set the current user directly
        currentUserAdd(_FirebaseUserSdb(this, dbUser));
        return dbUser;
      },
    );

    return _FirebaseUserCredentialSdb(this, dbUser);
  }

  @override
  Future<UserCredential> getSignInAnonymouslyUserCredential() async {
    await _ready;
    var dbUser = await _database.inStoreTransaction(
      _userStore.rawRef,
      SdbTransactionMode.readWrite,
      (txn) async {
        var dbUser = await _txnGetSignInAnonymouslyUserCredential(txn);
        return dbUser;
      },
    );

    return _FirebaseUserCredentialSdb(this, dbUser);
  }

  @override
  Future<void> signOut() async {
    // ignore: unnecessary_statements
    await _ready;

    await _database.inStoresTransaction(
      [_currentUserStore.rawRef, _userStore.rawRef],
      SdbTransactionMode.readWrite,
      (txn) async {
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
      },
    );

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
  FirebaseAuthService get service => authServiceSdb;

  @override
  Stream<UserRecord?> onUserRecord(String uid) async* {
    await _ready;
    yield* _userStore.record(uid).onRecord(_database).map((record) {
      if (record == null) {
        return null;
      }
      return _UserRecordSdb(record);
    });
  }
}

/// User Sdb
class _FirebaseUserSdb with FirebaseUserMixin {
  final FirebaseAuthSdb auth;
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

  _FirebaseUserSdb(this.auth, this._dbUser);

  @override
  Future<void> delete() async {
    await auth.deleteUser(uid);
  }
}

/// User credential Sdb
class _FirebaseUserCredentialSdb with FirebaseUserCredentialMixin {
  final FirebaseAuthSdb auth;
  final DbUser _dbUser;

  /// Constructor
  _FirebaseUserCredentialSdb(this.auth, this._dbUser);

  @override
  late final user = _FirebaseUserSdb(auth, _dbUser);

  @override
  late final credential = _FirebaseAuthCredentialSdb();
}

class _FirebaseAuthCredentialSdb
    with FirebaseAuthCredentialMixin
    implements FirebaseAuthCredential {
  @override
  String get providerId => _authSdbProviderId;
}

class _UserRecordSdb with FirebaseUserRecordDefaultMixin {
  final DbUser dbUser;

  _UserRecordSdb(this.dbUser);

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
