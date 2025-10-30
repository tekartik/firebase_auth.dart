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
        FirebaseAuthLocalAdminDefaultMixin
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
    _ready.then((_) {
      _currentUserIdSubscription?.cancel();
      _currentUserSubscription?.cancel();
      _database.close();
    });

    super.dispose();
  }

  @override
  FirebaseApp get app => appSim;

  late Database _database;
  StreamSubscription? _currentUserIdSubscription;
  StreamSubscription? _currentUserSubscription;
  String? _currentUserId;
  late final _ready = () async {
    firebaseAuthSembastInitDbBuilders();
    _database = await authServiceSim.databaseFactory.openDatabase(
      join(firebaseSim.localPath, appSim.name, 'auth.db'),
    );
    _currentUserIdSubscription = firebaseAuthCurrentUserRecord
        .onRecord(_database)
        .listen((record) {
          var userId = record?.uid.v;
          if (userId == null) {
            _currentUserId = null;
            currentUserAdd(null);
            _currentUserSubscription?.cancel();
            return;
          }
          if (userId != _currentUserId) {
            _currentUserSubscription?.cancel();
          }
          _currentUserSubscription = onUserRecord(userId).listen((record) {
            if (record == null) {
              // Record not found, delete current user
              firebaseAuthCurrentUserRecord.delete(_database);
              currentUserAdd(null);
            } else {
              currentUserAdd(FirebaseUserSim(record));
            }
          });
        });
  }();

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
  Future<void> deleteUser(String uid) async {
    var simClient = await _simClient;
    var userDeleteRequest = UserGetRequest()..userId.setValue(uid);

    await simClient.sendRequest<void>(
      FirebaseAuthSimServerService.serviceName,
      methodAuthUserDelete,
      userDeleteRequest.toMap(),
    );
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

  @override
  Stream<UserRecordSim?> onUserRecord(String userId) {
    late ServerSubscriptionSim<UserRecordSim?> subscription;
    late FirebaseSimAppClient? simClient;
    final lock = Lock();
    subscription = ServerSubscriptionSim(
      StreamController(
        onCancel: () async {
          await lock.synchronized(() async {
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
      ),
    );

    () async {
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
    subscription.doneCompleter.complete();
  }

  Future<UserGetResponse> _getSignInWithEmailAndPasswordUserReponse({
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
    var userResponse = await _getSignInWithEmailAndPasswordUserReponse(
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
    var userResponse = await _getSignInWithEmailAndPasswordUserReponse(
      email: email,
      password: password,
    );
    var userRecordSim = UserRecordSim(userResponse: userResponse);
    return UserCredentialSim(userRecordSim);
  }

  Future<UserCredentialSim> _handleSignInResponse(
    UserGetResponse userResponse,
  ) async {
    var responseUid = userResponse.userId.v;
    if (responseUid == null) {
      throw StateError('Login failed');
    }
    await firebaseAuthCurrentUserRecord.put(
      _database,
      DbCurrentUser()..uid.v = responseUid,
    );
    var userRecordSim = UserRecordSim(userResponse: userResponse);
    currentUserAdd(FirebaseUserSim(userRecordSim));
    return UserCredentialSim(userRecordSim);
  }

  Future<UserGetResponse> _getSignInAnonymouslyUserResponse() async {
    await _ready;
    var simClient = await _simClient;

    /// Reuse current if any
    ///
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
  Future<UserCredential> getSignInAnonymouslyUserCredential() async {
    var userResponse = await _getSignInAnonymouslyUserResponse();
    var userRecordSim = UserRecordSim(userResponse: userResponse);
    return UserCredentialSim(userRecordSim);
  }

  @override
  Future signOut() async {
    // ignore: unnecessary_statements
    await _ready;
    var currentUser = await onCurrentUser.first;
    await firebaseAuthCurrentUserRecord.delete(_database);
    if (currentUser != null && currentUser.isAnonymous) {
      await deleteUser(currentUser.uid);
    }
    currentUserAdd(null);
    _currentUserId = null;
  }
}
