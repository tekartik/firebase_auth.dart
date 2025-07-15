import 'dart:async';

import 'package:path/path.dart';
import 'package:synchronized/synchronized.dart';
import 'package:tekartik_app_cv_sembast/app_cv_sembast.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_auth/auth_admin.dart';
import 'package:tekartik_firebase_auth/auth_mixin.dart';
import 'package:tekartik_firebase_auth_sembast/auth_sembast_mixin.dart';
import 'package:tekartik_firebase_auth_sim/src/auth_sim_message.dart';
import 'package:tekartik_firebase_auth_sim/src/auth_sim_service.dart';
import 'package:tekartik_firebase_auth_sim/src/auth_user_sim.dart';
import 'package:tekartik_firebase_sim/firebase_sim.dart';
import 'package:tekartik_firebase_sim/firebase_sim_client.dart';
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
    with FirebaseAppProductMixin<FirebaseAuth>, FirebaseAuthMixin
    implements FirebaseAuthSim, FirebaseAuthLocalAdmin {
  final FirebaseAppSim appSim;
  final FirebaseAuthServiceSim authServiceSim;
  FirebaseSim get firebaseSim => appSim.firebase as FirebaseSim;

  _FirebaseAuthSim({required this.appSim, required this.authServiceSim});

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

  @override
  Future<void> setUser(
    String uid, {
    String? email,
    bool? emailVerified,
    bool? isAnonymous,
  }) async {
    var simClient = await appSim.simClient;
    var userSetRequest = UserSetRequest()
      ..userId.setValue(uid)
      ..email.setValue(email)
      ..anonymous.setValue(isAnonymous)
      ..emailVerified.setValue(emailVerified);
    await simClient.sendRequest<void>(
      FirebaseAuthSimService.serviceName,
      methodAuthUserSet,
      userSetRequest.toMap(),
    );
  }

  @override
  Future<void> deleteUser(String uid) async {
    var simClient = await appSim.simClient;
    var userDeleteRequest = UserGetRequest()..userId.setValue(uid);

    await simClient.sendRequest<void>(
      FirebaseAuthSimService.serviceName,
      methodAuthUserDelete,
      userDeleteRequest.toMap(),
    );
  }

  @override
  Future<UserRecord?> getUser(String uid) async {
    var simClient = await appSim.simClient;
    var userGetRequest = UserGetRequest()..userId.setValue(uid);
    var map = await simClient.sendRequest<Model>(
      FirebaseAuthSimService.serviceName,
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
    var simClient = await appSim.simClient;
    var userGetRequest = UserGetByEmailRequest()..email.setValue(email);
    var map = await simClient.sendRequest<Model>(
      FirebaseAuthSimService.serviceName,
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
    late FirebaseSimClient? simClient;
    final lock = Lock();
    subscription = ServerSubscriptionSim(
      StreamController(
        onCancel: () async {
          await lock.synchronized(() async {
            await removeSubscription(subscription);
            await simClient?.sendRequest<void>(
              FirebaseAuthSimService.serviceName,
              methodAuthUserGetCancel,
              {paramSubscriptionId: subscription.id},
            );
            await subscription.done;
          });
        },
      ),
    );

    () async {
      await lock.synchronized(() async {
        simClient = await appSim.simClient;
        var result = await simClient!.sendRequest<Map>(
          FirebaseAuthSimService.serviceName,
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
    FirebaseSimClient simClient,
    String path,
    ServerSubscriptionSim subscription,
  ) async {
    var subscriptionId = subscription.id;
    while (true) {
      if (_subscriptions.containsKey(subscriptionId)) {
        var result = await simClient.sendRequest<Map>(
          FirebaseAuthSimService.serviceName,
          methodAuthUserGetStream,
          {paramSubscriptionId: subscriptionId},
        );
        // devPrint(result);
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
        }
      } else {
        break;
      }
    }
    subscription.doneCompleter.complete();
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _ready;
    var simClient = await appSim.simClient;
    var signInRequest = UserSignInEmailPasswordRequest()
      ..email.setValue(email)
      ..password.setValue(password);
    var map = await simClient.sendRequest<Map>(
      FirebaseAuthSimService.serviceName,
      methodAuthSignInEmailPassword,
      signInRequest.toMap(),
    );
    var userResponse = map.cv<UserGetResponse>();
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

  @override
  Future<UserCredential> signInAnonymously() async {
    await _ready;
    var simClient = await appSim.simClient;

    var currentUser = this.currentUser as FirebaseUserSim?;
    if (currentUser != null && currentUser.isAnonymous) {
      return UserCredentialSim(currentUser.userRecordSim);
    }

    /// Reuse current if any
    ///
    var signInRequest = UserSignInAnonymouslyRequest();
    var map = await simClient.sendRequest<Map>(
      FirebaseAuthSimService.serviceName,
      methodAuthSignInAnonymously,
      signInRequest.toMap(),
    );
    var userResponse = map.cv<UserGetResponse>();
    var responseUid = userResponse.userId.v;
    if (responseUid == null) {
      throw StateError('Login failed');
    }
    var userRecordSim = UserRecordSim(userResponse: userResponse);
    currentUserAdd(FirebaseUserSim(userRecordSim));
    return UserCredentialSim(userRecordSim);
  }

  @override
  Future signOut() async {
    await firebaseAuthCurrentUserRecord.delete(_database);
    currentUserAdd(null);
    _currentUserId = null;
  }
}
