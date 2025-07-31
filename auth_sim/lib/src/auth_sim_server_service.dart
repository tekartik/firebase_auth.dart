// ignore: implementation_imports

import 'dart:async';
import 'dart:core' hide Error;

import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_common_utils/env_utils.dart';
import 'package:tekartik_firebase_auth/auth_admin.dart';
import 'package:tekartik_firebase_auth_sim/src/auth_sim_plugin.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';
// ignore: implementation_imports
import 'package:tekartik_firebase_sim/src/firebase_sim_common.dart';

import 'auth_sim_message.dart';
import 'auth_sim_server.dart';

/// Auth sim service
class FirebaseAuthSimServerService extends FirebaseSimServerServiceBase {
  /// Firebase auth sim plugin
  late FirebaseAuthSimPlugin firebaseAuthSimPlugin;
  final _expando = Expando<FirebaseAuthSimPluginServer>();

  /// Service name
  static final serviceName = 'firebase_auth';

  /// Sim service
  FirebaseAuthSimServerService() : super(serviceName) {
    initAuthSimBuilders();
  }

  @override
  FutureOr<Object?> onCall(
    RpcServerChannel channel,
    RpcMethodCall methodCall,
  ) async {
    try {
      var simServerChannel = firebaseSimServerExpando[channel]!;
      var firebaseAuthSimPluginServer = _expando[channel] ??= () {
        var app = simServerChannel.app!;
        var firebaseAuth =
            firebaseAuthSimPlugin.firebaseAuthService.auth(app)
                as FirebaseAuthLocalAdmin;
        //.debugQuickLoggerWrapper();
        // One transaction lock per server
        //firebaseAuthSimPlugin._locks[firebaseAuth] ??= Lock();
        return FirebaseAuthSimPluginServer(firebaseAuthSimPlugin, firebaseAuth);
      }();
      var parameters = methodCall.arguments;
      switch (methodCall.method) {
        case methodAuthUserGet:
          var map = resultAsMap(parameters);
          return await firebaseAuthSimPluginServer
              .handleFirebaseAuthGetUserRequest(map);

        case methodAuthUserGetByEmail:
          var map = resultAsMap(parameters);
          return await firebaseAuthSimPluginServer
              .handleFirebaseAuthGetUserByEmailRequest(map);

        case methodAuthUserSet:
          var map = resultAsMap(parameters);
          return await firebaseAuthSimPluginServer
              .handleFirebaseAuthSetUserRequest(map);
        case methodAuthUserDelete:
          var map = resultAsMap(parameters);
          await firebaseAuthSimPluginServer.handleFirebaseAuthDeleteUserRequest(
            map,
          );
          return null;

        case methodAuthSignInEmailPassword:
          var map = resultAsMap(parameters);
          return await firebaseAuthSimPluginServer
              .handleFirebaseAuthSignInEmailPassword(map);
        case methodAuthSignInAnonymously:
          var map = resultAsMap(parameters);
          return await firebaseAuthSimPluginServer
              .handleFirebaseAuthSignInAnonymously(map);

        case methodAuthUserGetListen:
          var map = resultAsMap(parameters);
          return await firebaseAuthSimPluginServer.handleAuthUserGetListen(map);

        case methodAuthUserGetStream:
          var map = resultAsMap(parameters);
          return await firebaseAuthSimPluginServer.handleAuthUserGetStream(map);

        case methodAuthUserGetCancel:
          var map = resultAsMap(parameters);
          return await firebaseAuthSimPluginServer.handleAuthUserGetCancel(map);
      }
      return super.onCall(channel, methodCall);
    } catch (e, st) {
      if (isDebug) {
        // ignore: avoid_print
        print('error $st');
        // ignore: avoid_print
        print(st);
      }
      rethrow;
    }
  }
}
