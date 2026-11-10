library;

import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_auth_sim/auth_sim.dart';
import 'package:tekartik_firebase_sim/firebase_sim_mixin.dart';
import 'package:test/test.dart';

import 'test_common.dart';

/// Lets the late events (server answers, listeners) come.
Future<void> settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
  await Future<void>.delayed(const Duration(milliseconds: 100));
}

void main() {
  group('connection', () {
    late FirebaseAppSim app;
    late FirebaseAuthSim auth;
    late FirebaseAuthServiceSim authService;
    late TestContext testContext;
    setUp(() async {
      testContext = await initTestContextSim(port: 0);
      authService = FirebaseAuthServiceSim(
        databaseFactory: newDatabaseFactoryMemory(),
      );
      app = testContext.firebase.initializeApp() as FirebaseAppSim;
      auth = authService.auth(app);
    });

    tearDown(() async {
      await app.delete();
      await close(testContext);
    });

    Future<String> signIn(String email, {bool settled = true}) async {
      var credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: 'password',
      );
      if (settled) {
        // Its server record is listened to.
        await settle();
      }
      return credential.user.uid;
    }

    test('user record stream ends when the connection closes', () async {
      var uid = await signIn('connection_closed');
      var events = <String?>[];
      var errors = <Object>[];
      var done = Completer<void>();
      var subscription = auth
          .onUserRecord(uid)
          .listen(
            (record) => events.add(record?.email),
            onError: (Object e) => errors.add(e),
            onDone: done.complete,
          );
      await settle();
      expect(events, ['connection_closed']);
      await (await app.simClient).close();
      await done.future.timeout(const Duration(seconds: 5));
      expect(errors, hasLength(1));
      // The current user stays.
      expect(auth.currentUser?.uid, uid);
      await subscription.cancel().timeout(const Duration(seconds: 5));
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('cancel after the connection closed', () async {
      var uid = await signIn('cancel_after_close');
      var subscription = auth.onUserRecord(uid).listen((_) {});
      await settle();
      await (await app.simClient).close();
      // It hung, waiting for a loop that died with the connection.
      await subscription.cancel().timeout(const Duration(seconds: 5));
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('app connection closed after delete', () async {
      await signIn('closed_after_delete');
      var simClient = await app.simClient;
      await app.delete();
      // What FirebaseAppSim.delete should do (it keeps the connection).
      await simClient.close();
      await settle();
    }, timeout: const Timeout(Duration(seconds: 30)));

    // The server also answers the user record stream of the deleted user:
    // the record of the signed out user was deleted after the database was
    // closed (uncaught 'database is closed', 1 in 2 to 5 runs of the shared
    // tests deleting their signed in user).
    test('signed in user deleted, then the app deleted', () async {
      for (var i = 0; i < 10; i++) {
        // As the shared tests do: deleted right after the sign in.
        var uid = await signIn(
          'deleted_then_app_deleted_$i',
          settled: i.isEven,
        );
        await auth.deleteUser(uid);
        expect(auth.currentUser, isNull);
        await app.delete();
        await settle();
        app = testContext.firebase.initializeApp() as FirebaseAppSim;
        auth = authService.auth(app);
      }
    }, timeout: const Timeout(Duration(seconds: 60)));

    test(
      'signed in user deleted by another app, then this app deleted',
      () async {
        for (var i = 0; i < 5; i++) {
          var uid = await signIn('deleted_elsewhere_$i');
          var otherApp = testContext.firebase.initializeApp(name: 'other_$i');
          try {
            var otherAuth = FirebaseAuthServiceSim(
              databaseFactory: newDatabaseFactoryMemory(),
            ).auth(otherApp);
            await otherAuth.deleteUser(uid);
            await auth.onCurrentUser
                .firstWhere((user) => user == null)
                .timeout(const Duration(seconds: 5));
            await app.delete();
            await settle();
          } finally {
            await otherApp.delete();
          }
          app = testContext.firebase.initializeApp() as FirebaseAppSim;
          auth = authService.auth(app);
        }
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );
  });
}
