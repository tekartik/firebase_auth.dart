import 'dart:async';

import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth/auth_admin.dart';
import 'package:tekartik_firebase_auth/src/auth_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:uuid/uuid.dart';

import 'import.dart';

@Deprecated('Use firebaseAuthServiceLocal')
FirebaseAuthService get authService => firebaseAuthServiceLocal;

FirebaseAuthService newAuthServiceLocal() => newFirebaseAuthServiceLocal();

/// For unit test
FirebaseAuthService newFirebaseAuthServiceLocal() => AuthServiceLocal();

/// Deprecated
FirebaseAuth newAuthLocal() => newFirebaseAuthLocal();

/// Quick firestore test helper
FirebaseAuth newFirebaseAuthLocal() =>
    newFirebaseAuthServiceLocal().auth(newFirebaseAppMemory());

abstract class AuthLocalProvider implements AuthProvider {
  factory AuthLocalProvider() {
    return AuthLocalProviderImpl();
  }
}

const localProviderId = '_local';

class AuthLocalProviderImpl implements AuthLocalProvider {
  @override
  String get providerId => localProviderId;
}

class AuthLocalSignInOptions implements AuthSignInOptions {
  final UserRecordLocal _userRecordLocal;

  AuthLocalSignInOptions(this._userRecordLocal);
}

class ListUsersResultLocal implements ListUsersResult {
  @override
  final String pageToken;

  @override
  final List<UserRecord> users;

  ListUsersResultLocal({required this.pageToken, required this.users});
}

class AuthSignInResultImpl implements AuthSignInResult {
  @override
  final UserCredential credential;

  AuthSignInResultImpl(this.credential);

  @override
  bool get hasInfo => true;
}

class UserCredentialImpl implements UserCredential {
  @override
  final AuthCredential credential;

  @override
  final User user;

  UserCredentialImpl(this.credential, this.user);
}

class AuthCredentialImpl implements AuthCredential {
  @override
  String get providerId => localProviderId;
}

extension on UserRecordLocal {
  _UserRecordLocal get _ => this as _UserRecordLocal;
}

abstract class UserRecordLocal implements UserRecord {}

class _UserRecordLocal
    with FirebaseUserRecordDefaultMixin
    implements UserRecordLocal {
  final FirebaseAuthLocal auth;
  _UserRecordLocal({
    required this.auth,
    required this.uid,
    // ignore: unused_element_parameter
    this.disabled = false,
    this.emailVerified = true,
    this.isAnonymous = false,
    this.localPassword,
    this.email,
    this.displayName,
  });

  /// Optional
  final String? localPassword;
  @override
  dynamic get customClaims => null;

  @override
  final bool isAnonymous;

  @override
  final bool disabled;

  @override
  String? displayName;

  @override
  String? email;

  @override
  final bool emailVerified;

  @override
  UserMetadata? get metadata => null;

  @override
  String? get passwordHash => null;

  @override
  String? get passwordSalt => null;

  @override
  String? get phoneNumber => null;

  @override
  String? get photoURL => null;

  @override
  List<UserInfo>? get providerData => null;

  @override
  String? get tokensValidAfterTime => null;

  @override
  final String uid;

  UserInfo toUserInfo() {
    return _UserInfoLocal(auth: auth, uid: uid)
      ..email = email
      ..displayName = displayName;
  }

  User toUser() {
    return _UserLocal(auth: auth, uid: uid)
      ..email = email
      ..displayName = displayName;
  }
}

abstract class UserInfoLocal implements UserInfo, UserInfoWithIdToken {}

class _UserInfoLocal with FirebaseUserMixin implements UserInfoLocal {
  final FirebaseAuthLocal auth;
  _UserInfoLocal({required this.auth, required this.uid});

  @override
  String? displayName;

  @override
  String? email;

  @override
  String? get phoneNumber => null;

  @override
  String? get photoURL => null;

  @override
  String get providerId => localProviderId;

  @override
  final String uid;

  @override
  String toString() => '$uid $email $displayName';

  @override
  Future<String> getIdToken({bool? forceRefresh}) async => uid;
}

abstract class UserLocal implements User {}

class _UserLocal extends _UserInfoLocal implements UserLocal {
  _UserLocal({required super.auth, required super.uid});

  @override
  bool get emailVerified => true;

  @override
  bool get isAnonymous => false;

  @override
  Future<void> delete() async {
    await auth.deleteUser(uid);
  }
}

typedef AuthLocal = FirebaseAuthLocal;

abstract class FirebaseAuthLocal
    implements FirebaseAuth, FirebaseAuthLocalAdmin, FirebaseAuthAdmin {
  UserRecordLocal get localAdminUser;
  UserRecordLocal get localRegularUser;
}

class AuthLocalImpl
    with
        FirebaseAppProductMixin<FirebaseAuth>,
        FirebaseAuthMixin,
        FirebaseAuthAdminDefaultMixin,
        FirebaseAuthLocalAdminDefaultMixin
    implements AuthLocal {
  final AuthServiceLocal _authServiceLocal;
  final AppLocal _appLocal;

  late final _UserRecordLocal _localAdminUser =
      _UserRecordLocal(auth: this, uid: '1')
        ..displayName = 'admin'
        ..email = 'admin@example.com';

  late final User adminUserInfo = _localAdminUser.toUser();

  late final _UserRecordLocal _localRegularUser =
      _UserRecordLocal(auth: this, uid: '2')
        ..displayName = 'user'
        ..email = 'user@example.com';

  late final List<_UserRecordLocal> _allUsers = [
    _localAdminUser,
    _localRegularUser,
  ];

  AuthLocalImpl(this._authServiceLocal, this._appLocal) {
    currentUserAdd(adminUserInfo);
  }

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
    var userRecord = _getUserByEmail(email);
    if (userRecord == null) {
      throw StateError('user $email not found');
    }
    if (userRecord.localPassword != null &&
        userRecord.localPassword != password) {
      throw StateError('invalid password');
    }
    var user = userRecord.toUser();
    currentUserAdd(user);
    return _wrapUserAsCredential(userRecord);
  }

  @override
  Future<ListUsersResult> listUsers({
    int? maxResults,
    String? pageToken,
  }) async {
    var startIndex = parseInt(pageToken, 0)!;
    var lastIndex = startIndex + (maxResults ?? 10);
    var result = ListUsersResultLocal(
      pageToken: lastIndex.toString(),
      users: listSubList(_allUsers, startIndex, lastIndex),
    );

    return result;
  }

  @override
  Future<UserRecord?> getUser(String uid) async {
    return _getUserById(uid);
  }

  UserRecord? _getUserById(String uid) {
    for (var user in _allUsers) {
      if (user.uid == uid) {
        return user;
      }
    }
    return null;
  }

  @override
  Future<List<UserRecord>> getUsers(List<String> uids) async {
    var list = <UserRecord?>[];
    for (var uid in uids) {
      var user = await getUser(uid);
      if (user != null) {
        list.add(user);
      }
    }
    return list.cast<UserRecord>();
  }

  @override
  Future<UserRecord?> getUserByEmail(String email) async {
    return _getUserByEmail(email);
  }

  UserCredentialImpl _wrapUserAsCredential(UserRecordLocal user) {
    return UserCredentialImpl(AuthCredentialImpl(), user._.toUser());
  }

  _UserRecordLocal? _getUserByEmail(String email) {
    for (var user in _allUsers) {
      if (user.email == email) {
        return user;
      }
    }
    return null;
  }

  @override
  Future<AuthSignInResult> signIn(
    AuthProvider authProvider, {
    AuthSignInOptions? options,
  }) async {
    var localOptions = options as AuthLocalSignInOptions?;
    var uid = localOptions?._userRecordLocal.uid;
    if (uid == null) {
      throw StateError('uid is null');
    }
    var userRecord = await getUser(uid) as UserRecordLocal?;

    if (userRecord == null) {
      throw StateError('user $uid not found');
      // return AuthSignInResultImpl(null);
    } else {
      var user = userRecord._.toUser();
      currentUserAdd(user);
      return AuthSignInResultImpl(
        UserCredentialImpl(AuthCredentialImpl(), user),
      );
    }
  }

  @override
  Future signOut() async {
    currentUserAdd(null);
  }

  @override
  String toString() => _appLocal.name;

  @override
  Future<DecodedIdToken> verifyIdToken(
    String idToken, {
    bool? checkRevoked,
  }) async {
    // The id token is the uid itself
    return DecodedIdTokenLocal(uid: idToken);
  }

  @override
  Future<User?> reloadCurrentUser() async {
    // No-op on local
    return currentUser;
  }

  @override
  FirebaseAuthService get service => _authServiceLocal;

  @override
  FirebaseApp get app => _appLocal;

  @override
  Future<void> deleteUser(String uid) async {
    _allUsers.removeWhere((user) => user.uid == uid);
  }

  @override
  Stream<UserRecord?> onUserRecord(String uid) =>
      throw UnimplementedError('onUserRecord not implemented for auth local');

  @override
  Future<UserRecord> createUser(FirebaseAuthCreateUserRequest request) async {
    var uid = request.uid;
    if (uid != null) {
      if (await getUser(uid) != null) {
        throw StateError('user $uid already exists');
      }
    }
    if (request.email != null) {
      if (await getUserByEmail(request.email!) != null) {
        throw StateError('user ${request.email} already exists');
      }
    }
    uid ??= _generateId();
    var userRecord = _UserRecordLocal(
      auth: this,
      uid: uid,
      isAnonymous: false,
      localPassword: request.password,

      email: request.email,
      displayName: request.displayName,
    );

    _allUsers.add(userRecord);
    return userRecord;
  }

  @override
  Future<void> setUser(
    String uid, {
    String? email,
    bool? isAnonymous,
    bool? emailVerified,
  }) async {
    var userRecord = await getUser(uid) as UserRecordLocal?;
    if (userRecord == null) {
      var userRecordLocal = _UserRecordLocal(
        auth: this,
        uid: uid,
        emailVerified: emailVerified ?? true,
        isAnonymous: isAnonymous ?? false,
      )..email = email;
      _allUsers.add(userRecordLocal);
    } else {
      userRecord._.email = email ?? userRecord.email;
    }
  }

  @override
  UserRecordLocal get localAdminUser => _localAdminUser;

  @override
  UserRecordLocal get localRegularUser => _localRegularUser;
}

class DecodedIdTokenLocal implements DecodedIdToken {
  @override
  final String uid;

  DecodedIdTokenLocal({required this.uid});
}

typedef AuthServiceLocal = FirebaseAuthServiceLocal;

class FirebaseAuthServiceLocal
    with FirebaseProductServiceMixin<FirebaseAuth>, FirebaseAuthServiceMixin
    implements FirebaseAuthService {
  @override
  bool get supportsListUsers => true;

  @override
  FirebaseAuth auth(App app) {
    return getInstance(app, () {
      // assert(app is AppLocal, 'invalid app type - not AppLocal');
      final appLocal = app as AppLocal;
      return AuthLocalImpl(this, appLocal);
    });
  }

  @override
  bool get supportsCurrentUser => true;
}

AuthServiceLocal? _authServiceLocal;

FirebaseAuthService get authServiceLocal => firebaseAuthServiceLocal;
AuthServiceLocal get firebaseAuthServiceLocal =>
    _authServiceLocal ??= AuthServiceLocal();

String _generateId() => const Uuid().v4().toString();
