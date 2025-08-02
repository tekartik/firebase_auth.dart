import 'dart:core' hide Error;

import 'package:cv/cv.dart';
import 'package:sembast/utils/key_utils.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_common_utils/stream/stream_poller.dart';
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth/auth_admin.dart';
import 'package:tekartik_firebase_auth_sim/src/auth_sim_message.dart';
import 'package:tekartik_firebase_sim/firebase_sim_mixin.dart';

import 'auth_sim_plugin.dart'; // ignore: implementation_imports
// ignore: implementation_imports

/// One per client/app
class FirebaseAuthSimPluginServer {
  /// Firebase auth sim server
  final FirebaseAuthSimPlugin firebaseAuthSimPlugin;

  /// Firebase auth
  final FirebaseAuthLocalAdmin firebaseAuth;

  final _lock = Lock();

  /// Constructor
  FirebaseAuthSimPluginServer(this.firebaseAuthSimPlugin, this.firebaseAuth);

  /// Last subscriptionId
  int lastSubscriptionId = 0;

  /// New subcription id
  int get newSubscriptionId => ++lastSubscriptionId;

  /// Subscriptions
  final Map<int, SimSubscription> subscriptions = <int, SimSubscription>{};

  /// Set user
  Future handleFirebaseAuthSetUserRequest(Map<String, Object?> params) async {
    var userSetRequest = params.cv<UserSetRequest>();
    var uid = userSetRequest.userId.v ?? generateStringKey();
    var email = userSetRequest.email.v;
    var anonymous = userSetRequest.anonymous.v;
    var emailVerified = userSetRequest.emailVerified.v;

    await _lock.synchronized(() async {
      await firebaseAuth.setUser(
        uid,
        email: email,
        isAnonymous: anonymous,
        emailVerified: emailVerified,
      );
    });
  }

  /// Sign in email password
  Future<Model?> handleFirebaseAuthSignInEmailPassword(
    Map<String, Object?> params,
  ) async {
    var signInRequest = params.cv<UserSignInEmailPasswordRequest>();
    var email = signInRequest.email.v!;
    var password = signInRequest.password.v!;

    return await _lock.synchronized(() async {
      var credentials = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      var user = await firebaseAuth.getUser(credentials.user.uid);
      if (user == null) {
        return newModel();
      }
      return _fromUserRecord(user).toMap();
    });
  }

  /// Sign in anonymous
  Future<Model?> handleFirebaseAuthSignInAnonymously(
    Map<String, Object?> params,
  ) async {
    return await _lock.synchronized(() async {
      var credentials = await firebaseAuth.signInAnonymously();
      var user = await firebaseAuth.getUser(credentials.user.uid);
      if (user == null) {
        return newModel();
      }
      return _fromUserRecord(user).toMap();
    });
  }

  /// Sign in anonymous
  Future<void> handleFirebaseAuthSixgnOut(Map<String, Object?> params) async {
    // var signOutRequest = params.cv<UserSignOutRequest>();

    await _lock.synchronized(() async {
      await firebaseAuth.signOut();
    });
  }

  /// Get user
  Future<Model> handleFirebaseAuthGetUserRequest(
    Map<String, Object?> params,
  ) async {
    var userGetRequest = params.cv<UserGetRequest>();
    var uid = userGetRequest.userId.v!;

    return await _lock.synchronized(() async {
      var user = await firebaseAuth.getUser(uid);
      if (user == null) {
        return newModel();
      }
      return _fromUserRecord(user).toMap();
    });
  }

  /// Get user
  Future<void> handleFirebaseAuthDeleteUserRequest(
    Map<String, Object?> params,
  ) async {
    var userDeleteRequest = params.cv<UserGetRequest>();
    var uid = userDeleteRequest.userId.v!;

    await _lock.synchronized(() async {
      await firebaseAuth.deleteUser(uid);
    });
  }

  UserGetResponse _fromUserRecord(UserRecord user) {
    return UserGetResponse()
      ..emailVerified.v = user.emailVerified
      ..email.v = user.email
      ..anonymous.v = user.isAnonymous
      ..userId.v = user.uid;
  }

  /// Get user
  Future<Model> handleFirebaseAuthGetUserByEmailRequest(
    Map<String, Object?> params,
  ) async {
    var userGetRequest = params.cv<UserGetByEmailRequest>();
    var email = userGetRequest.email.v!;

    return await _lock.synchronized(() async {
      var user = await firebaseAuth.getUserByEmail(email);
      if (user == null) {
        return newModel();
      }
      return _fromUserRecord(user).toMap();
    });
  }

  /// onUser
  Future handleAuthUserGetListen(Map<String, Object?> params) async {
    var userGetListen = params.cv<UserGetRequest>();
    var subscriptionId = newSubscriptionId;
    final userId = userGetListen.userId.v!;
    return await _lock.synchronized(() async {
      subscriptions[subscriptionId] = SimSubscription<UserRecord?>(
        firebaseAuth.onUserRecord(userId),
      );
      return {paramSubscriptionId: subscriptionId};
    });
  }

  /// User stream cancel
  Future handleAuthUserGetCancel(Map<String, Object?> params) async {
    var subscriptionId = params[paramSubscriptionId] as int?;
    var subscription = subscriptions[subscriptionId!]!;
    subscriptions.remove(subscriptionId);
    await subscription.cancel();
  }

  /// User stream
  Future handleAuthUserGetStream(Map<String, Object?> params) async {
    // New stream?
    var subscriptionId = params[paramSubscriptionId] as int;
    final subscription =
        subscriptions[subscriptionId] as SimSubscription<UserRecord?>?;
    var event = (await subscription?.getNext());
    var map = <String, Object?>{};
    if (event == null || event.done) {
      map[paramDone] = true;
    } else {
      var userRecord = event.data;
      if (userRecord != null) {
        map[paramUserRecord] = _fromUserRecord(userRecord).toMap();
      }
    }
    return map;
  }
}

/// Sim subscription
class SimSubscription<T> {
  late StreamPoller<T> _poller;

  /// Get next
  Future<StreamPollerEvent<T?>> getNext() => _poller.getNext();

  /// Constructor
  SimSubscription(Stream<T> stream) {
    _poller = StreamPoller<T>(stream);
  }

  /// Make sure to cancel the pending completer
  Future cancel() => _poller.cancel();
}
