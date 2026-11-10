import 'package:path/path.dart';
import 'package:tekartik_app_cv_sembast/app_cv_sembast.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_common_utils/env_utils.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_auth/auth_admin.dart';
import 'package:tekartik_firebase_auth/auth_mixin.dart';
import 'package:tekartik_firebase_auth_sembast/auth_sembast_mixin.dart';

import 'package:tekartik_firebase_auth_sim/src/auth_sim_message.dart';
import 'package:tekartik_firebase_auth_sim/src/auth_sim_server_service.dart';
import 'package:tekartik_firebase_auth_sim/src/auth_user_sim.dart';
import 'package:tekartik_firebase_sim/firebase_sim_mixin.dart';

import 'auth_service_sim.dart';

/// Auth sim
///
/// The id token of a user is its uid ([UserInfoWithIdToken.getIdToken] of
/// the signed-in user), accepted by [verifyIdToken] while the user exists on
/// the sim server, see [FirebaseAuthLocalIdTokenMixin].
abstract class FirebaseAuthSim implements FirebaseAuth, FirebaseAuthLocalAdmin {
  /// Firebase auth sim
  factory FirebaseAuthSim({
    required FirebaseAppSim appSim,
    required FirebaseAuthServiceSim authServiceSim,
  }) => _FirebaseAuthSim(appSim: appSim, authServiceSim: authServiceSim);
}

class _FirebaseAuthSim
    with
        FirebaseAppProductMixin<FirebaseAuth>,
        FirebaseAuthMixin,
        FirebaseAuthLocalAdminDefaultMixin,
        FirebaseAuthLocalIdTokenMixin
    implements FirebaseAuthSim, FirebaseAuthLocalAdmin {
  final FirebaseAppSim appSim;
  final FirebaseAuthServiceSim authServiceSim;
  FirebaseSim get firebaseSim => appSim.firebase as FirebaseSim;

  _FirebaseAuthSim({required this.appSim, required this.authServiceSim}) {
    // Lazy start
    // ignore: unnecessary_statements
    _ready;
  }

  @override
  void dispose() {
    super.dispose();
    // Closed right away: the database is shared with an auth of the same app
    // name created next (sembast returns the open database of a path). A
    // change in progress fails, the next ones do nothing once disposed.
    _ready.then((_) {
      _currentUserIdSubscription?.cancel();
      // Not awaited, it waits for the server.
      _currentUserSubscription?.cancel().ignore();
      _currentUserSubscription = null;
      _currentUserId = null;
      _database.close();
    }).ignore();
  }

  @override
  FirebaseApp get app => appSim;

  late Database _database;
  StreamSubscription? _currentUserIdSubscription;
  StreamSubscription? _currentUserSubscription;

  /// The signed in user whose server record is listened to.
  String? _currentUserId;

  /// One change of the signed in user at a time (the methods, the local
  /// database listener, a deleted user, dispose).
  final _stateLock = Lock();

  late final _ready = () async {
    firebaseAuthSembastInitDbBuilders();
    _database = await authServiceSim.databaseFactory.openDatabase(
      join(firebaseSim.localPath, appSim.name, 'auth.db'),
    );
    // The local database holds the signed in user id (restored on start,
    // shared by the auths of the same app name). Its events can come late,
    // after another change: they only trigger a read of the record.
    _currentUserIdSubscription = firebaseAuthCurrentUserRecord
        .onRecord(_database)
        .listen((_) {
          _stateLock.synchronized(() async {
            if (disposed) {
              return;
            }
            var userId = (await firebaseAuthCurrentUserRecord.get(
              _database,
            ))?.uid.v;
            _listenToUser(userId);
            if (userId == null) {
              _publish(null);
            }
            // Otherwise the user is published by its server record.
          }).ignore();
        });
  }();

  /// Listens to the server record of the signed in user [uid], none when
  /// null.
  void _listenToUser(String? uid) {
    if (uid == _currentUserId) {
      return;
    }
    _currentUserId = uid;
    // Not awaited, it waits for the server.
    _currentUserSubscription?.cancel().ignore();
    _currentUserSubscription = null;
    if (uid == null || disposed) {
      return;
    }
    _currentUserSubscription = onUserRecord(uid).listen(
      (record) => _onCurrentUserRecord(uid, record),
      onError: (Object _) {
        // The connection closed (server gone): the current user stays.
      },
    );
  }

  /// A server record event of the signed in user [uid].
  void _onCurrentUserRecord(String uid, UserRecordSim? record) {
    // A late event of a user no longer signed in is ignored.
    if (disposed || _currentUserId != uid) {
      return;
    }
    if (record != null) {
      _publish(record);
      return;
    }
    // The user was deleted on the server: signed out.
    _stateLock.synchronized(() async {
      if (disposed || _currentUserId != uid) {
        return;
      }
      _listenToUser(null);
      _publish(null);
      await _deleteCurrentUserRecord(uid);
    }).ignore();
  }

  /// Deletes the local current user record if it still holds [uid].
  Future<void> _deleteCurrentUserRecord(String uid) async {
    await _database.transaction((txn) async {
      var record = await firebaseAuthCurrentUserRecord.get(txn);
      if (record?.uid.v == uid) {
        await firebaseAuthCurrentUserRecord.delete(txn);
      }
    });
  }

  /// Whether a current user was published, and which one (null when signed
  /// out).
  var _published = false;
  UserGetResponse? _publishedUser;

  /// The only path to [currentUserAdd]: a state equal to the published one
  /// is not published again (a sign in is answered by the server and then
  /// by its user record).
  void _publish(UserRecordSim? record) {
    if (disposed) {
      return;
    }
    var user = record?.userResponse;
    if (_published && user == _publishedUser) {
      return;
    }
    _published = true;
    _publishedUser = user;
    currentUserAdd(record == null ? null : FirebaseUserSim(record, auth: this));
  }

  @override
  Future<FirebaseUser?> reloadCurrentUser() {
    // TODO: implement reloadCurrentUser
    throw UnimplementedError();
  }

  // The key is the streamId from the server
  final Map<int, ServerSubscriptionSim> _subscriptions = {};

  void addSubscription(ServerSubscriptionSim subscription) {
    _subscriptions[subscription.id!] = subscription;
  }

  Future removeSubscription(ServerSubscriptionSim subscription) async {
    _subscriptions.remove(subscription.id);
    await subscription.close();
  }

  @override
  Stream<User?> get onCurrentUser async* {
    await _ready;
    yield* super.onCurrentUser;
  }

  @override
  FirebaseAuthService get service => authServiceSim;

  Future<FirebaseSimAppClient> get _simClient => appSim.simAppClient;
  @override
  Future<void> setUser(
    String uid, {
    String? email,
    bool? emailVerified,
    bool? isAnonymous,
  }) async {
    var simClient = await _simClient;
    var userSetRequest = UserSetRequest()
      ..userId.setValue(uid)
      ..email.setValue(email)
      ..anonymous.setValue(isAnonymous)
      ..emailVerified.setValue(emailVerified);
    await simClient.sendRequest<void>(
      FirebaseAuthSimServerService.serviceName,
      methodAuthUserSet,
      userSetRequest.toMap(),
    );
  }

  @override
  Future<UserRecord> createUser(FirebaseAuthCreateUserRequest request) async {
    var simClient = await _simClient;
    var userCreateRequest = UserCreateRequest()
      ..uid.setValue(request.uid)
      ..disabled.setValue(request.disabled)
      ..displayName.setValue(request.displayName)
      ..email.setValue(request.email)
      ..emailVerified.setValue(request.emailVerified)
      ..password.setValue(request.password)
      ..phoneNumber.setValue(request.phoneNumber)
      ..photoURL.setValue(request.photoURL);
    try {
      var map = await simClient.sendRequest<Model>(
        FirebaseAuthSimServerService.serviceName,
        methodAuthUserCreate,
        userCreateRequest.toMap(),
      );
      var userResponse = map.cv<UserGetResponse>();

      return UserRecordSim(userResponse: userResponse);
    } catch (e) {
      if (e.toString().contains('already-exists')) {
        throw StateError(e.toString());
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteUser(String uid) async {
    await _ready;
    var simClient = await _simClient;
    var userDeleteRequest = UserGetRequest()..userId.setValue(uid);

    await simClient.sendRequest<void>(
      FirebaseAuthSimServerService.serviceName,
      methodAuthUserDelete,
      userDeleteRequest.toMap(),
    );
    // Only the deleted user is signed out, right away.
    await _stateLock.synchronized(() async {
      if (disposed) {
        return;
      }
      if (_currentUserId == uid || currentUser?.uid == uid) {
        _listenToUser(null);
        _publish(null);
        await _deleteCurrentUserRecord(uid);
      }
    });
  }

  @override
  Future<UserRecord?> getUser(String uid) async {
    var simClient = await _simClient;
    var userGetRequest = UserGetRequest()..userId.setValue(uid);
    var map = await simClient.sendRequest<Model>(
      FirebaseAuthSimServerService.serviceName,
      methodAuthUserGet,
      userGetRequest.toMap(),
    );
    var userResponse = map.cv<UserGetResponse>();
    var responseUid = userResponse.userId.v;
    if (responseUid == null) {
      return null;
    }

    return UserRecordSim(userResponse: userResponse);
  }

  @override
  Future<UserRecord?> getUserByEmail(String email) async {
    var simClient = await _simClient;
    var userGetRequest = UserGetByEmailRequest()..email.setValue(email);
    var map = await simClient.sendRequest<Model>(
      FirebaseAuthSimServerService.serviceName,
      methodAuthUserGetByEmail,
      userGetRequest.toMap(),
    );
    var userResponse = map.cv<UserGetResponse>();
    var responseUid = userResponse.userId.v;
    if (responseUid == null) {
      return null;
    }

    return UserRecordSim(userResponse: userResponse);
  }

  /// The server record of the user [userId], null when it does not exist.
  ///
  /// When the connection closes (app deleted, server gone), the stream ends,
  /// with the error unless it was cancelled or the auth disposed.
  @override
  Stream<UserRecordSim?> onUserRecord(String userId) {
    late ServerSubscriptionSim<UserRecordSim?> subscription;
    FirebaseSimAppClient? simClient;
    final lock = Lock();
    late final StreamController<UserRecordSim?> controller;
    controller = StreamController(
      onCancel: () async {
        await lock.synchronized(() async {
          if (!_subscriptions.containsKey(subscription.id)) {
            // Ended by a closed connection (or never started).
            return;
          }
          await removeSubscription(subscription);
          // Allow failure here, in case server already closed
          try {
            await simClient?.sendRequest<void>(
              FirebaseAuthSimServerService.serviceName,
              methodAuthUserGetCancel,
              {paramSubscriptionId: subscription.id},
            );
          } catch (e) {
            if (isDebug) {
              // ignore: avoid_print
              print('Ignoring subscription cancel error $e');
            }
          }
          await subscription.done;
        });
      },
    );
    subscription = ServerSubscriptionSim(controller);

    () async {
      try {
        await lock.synchronized(() async {
          simClient = await _simClient;
          var result = await simClient!.sendRequest<Map>(
            FirebaseAuthSimServerService.serviceName,
            methodAuthUserGetListen,
            (UserGetRequest()..userId.v = userId).toMap(),
          );

          subscription.id = result[paramSubscriptionId] as int?;

          addSubscription(subscription);
        });

        // Loop until cancelled
        await _getStream(simClient!, userId, subscription);
        subscription.doneCompleter.complete();
      } catch (e, st) {
        // The connection closed: done first, a pending cancel waits for it,
        // and removed, the cancel of the close below has nothing to do.
        subscription.doneCompleter.complete();
        _subscriptions.remove(subscription.id);
        if (!controller.isClosed) {
          if (!disposed) {
            controller.addError(e, st);
          }
          controller.close().ignore();
        }
      }
    }();
    return subscription.stream;
  }

  // do until cancelled
  Future _getStream(
    FirebaseSimAppClient simClient,
    String path,
    ServerSubscriptionSim subscription,
  ) async {
    var subscriptionId = subscription.id;
    while (true) {
      if (_subscriptions.containsKey(subscriptionId)) {
        var result = await simClient.sendRequest<Map>(
          FirebaseAuthSimServerService.serviceName,
          methodAuthUserGetStream,
          {paramSubscriptionId: subscriptionId},
        );
        // null means cancelled
        if (result[paramDone] == true) {
          break;
        }
        var user = result[paramUserRecord];
        if (user is Map) {
          var userResponse = user.cv<UserGetResponse>();
          var userId = userResponse.userId.v;
          if (userId != null) {
            subscription.add(UserRecordSim(userResponse: userResponse));
          } else {
            subscription.add(null);
          }
        } else {
          subscription.add(null);
        }
      } else {
        break;
      }
    }
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

  Future<UserGetResponse> _signInWithEmailAndPasswordUser({
    required String email,
    required String password,
  }) async {
    await _ready;
    var simClient = await _simClient;
    var signInRequest = UserSignInEmailPasswordRequest()
      ..email.setValue(email)
      ..password.setValue(password);
    var map = await simClient.sendRequest<Map>(
      FirebaseAuthSimServerService.serviceName,
      methodAuthSignInEmailPassword,
      signInRequest.toMap(),
    );
    var userResponse = map.cv<UserGetResponse>();
    return userResponse;
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    var userResponse = await _signInWithEmailAndPasswordUser(
      email: email,
      password: password,
    );
    return await _handleSignInResponse(userResponse);
  }

  @override
  Future<UserCredential> getSignInWithEmailAndPasswordUserCredential({
    required String email,
    required String password,
  }) async {
    var userRecord = await getOrCreateUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    var userRecordSim = userRecord as UserRecordSim;

    return UserCredentialSim(userRecordSim, auth: this);
  }

  Future<UserCredentialSim> _handleSignInResponse(
    UserGetResponse userResponse,
  ) async {
    var responseUid = userResponse.userId.v;
    if (responseUid == null) {
      throw StateError('Login failed');
    }
    var userRecordSim = UserRecordSim(userResponse: userResponse);
    await _stateLock.synchronized(() async {
      await firebaseAuthCurrentUserRecord.put(
        _database,

        DbCurrentUser()..uid.v = responseUid,
      );
      _listenToUser(responseUid);
      // Also set the current user directly
      _publish(userRecordSim);
    });

    return UserCredentialSim(userRecordSim, auth: this);
  }

  Future<UserGetResponse> _getSignInAnonymouslyUserResponse() async {
    await _ready;
    var simClient = await _simClient;

    /// Reuse current if any
    var signInRequest = UserSignInAnonymouslyRequest();
    var map = await simClient.sendRequest<Map>(
      FirebaseAuthSimServerService.serviceName,
      methodAuthSignInAnonymously,
      signInRequest.toMap(),
    );
    var userResponse = map.cv<UserGetResponse>();
    return userResponse;
  }

  @override
  Future<UserCredential> signInAnonymously() async {
    await _ready;

    /*
    // Re-use existing?
    var currentUser = this.currentUser as FirebaseUserSim?;
    if (currentUser != null && currentUser.isAnonymous) {
      return UserCredentialSim(currentUser.userRecordSim);
    }
    */

    var userResponse = await _getSignInAnonymouslyUserResponse();
    return await _handleSignInResponse(userResponse);
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _ready;
    var simClient = await _simClient;
    var request = UserSendPasswordResetEmailRequest()..email.setValue(email);
    await simClient.sendRequest<Object?>(
      FirebaseAuthSimServerService.serviceName,
      methodAuthSendPasswordResetEmail,
      request.toMap(),
    );
  }

  @override
  Future<UserCredential> getSignInAnonymouslyUserCredential() async {
    var userResponse = await _getSignInAnonymouslyUserResponse();
    var userRecordSim = UserRecordSim(userResponse: userResponse);

    return UserCredentialSim(userRecordSim, auth: this);
  }

  /// Links an email and password [credential] to the user [uid] on the
  /// server, see [FirebaseUser.linkWithCredential].
  @override
  Future<UserCredential> linkUserWithCredential(
    String uid,
    FirebaseAuthCredential credential,
  ) async {
    if (credential is! FirebaseAuthEmailPasswordCredential) {
      throw UnsupportedError(
        '$runtimeType cannot link a ${credential.providerId} credential',
      );
    }
    await _ready;
    var simClient = await _simClient;
    var linkRequest = UserLinkEmailPasswordRequest()
      ..userId.setValue(uid)
      ..email.setValue(credential.email)
      ..password.setValue(credential.password);
    var map = await simClient.sendRequest<Map>(
      FirebaseAuthSimServerService.serviceName,
      methodAuthUserLinkEmailPassword,
      linkRequest.toMap(),
    );
    var userResponse = map.cv<UserGetResponse>();
    if (userResponse.userId.v == null) {
      throw StateError('user-not-found');
    }
    var userRecordSim = UserRecordSim(userResponse: userResponse);
    if (_currentUserId == uid) {
      // Also set the current user directly
      _publish(userRecordSim);
    }
    return UserCredentialSim(userRecordSim, auth: this);
  }

  @override
  Future signOut() async {
    // ignore: unnecessary_statements
    await _ready;
    var currentUser = await onCurrentUser.first;
    if (currentUser != null && currentUser.isAnonymous) {
      // Also signs it out.
      await deleteUser(currentUser.uid);
    }
    await _stateLock.synchronized(() async {
      await firebaseAuthCurrentUserRecord.delete(_database);
      _listenToUser(null);
      _publish(null);
    });
  }
}
