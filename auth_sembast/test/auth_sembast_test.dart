// ignore_for_file: avoid_print

library;

import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth/utils/json_utils.dart';
import 'package:tekartik_firebase_auth_local/auth_local.dart';
import 'package:tekartik_firebase_auth_sembast/auth_sembast.dart';
import 'package:tekartik_firebase_auth_test/auth_test.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void main() {
  var firebase = FirebaseLocal();
  var databaseFactory = newDatabaseFactoryMemory();
  var authService =
      FirebaseAuthServiceSembast(databaseFactory: databaseFactory);
  runAuthTests(firebase: firebase, authService: authService);

  group('auth', () {
    test('factory', () {
      expect(authService.supportsListUsers, isTrue);
    });
    runAuthTests(firebase: firebase, authService: authService);

    group('auth', () {
      var app = firebase.initializeApp(name: 'auth');
      var auth = authService.auth(app) as AuthLocal;

      tearDownAll(() {
        return app.delete();
      });

      test('logout/login', () async {
        var provider = AuthLocalProvider();
        expect(provider.providerId, isNotNull);
        await auth.signIn(provider,
            options: AuthLocalSignInOptions(localAdminUser));
        expect(auth.currentUser!.uid, localAdminUser.uid);
        expect((await auth.onCurrentUser.first)!.uid, localAdminUser.uid);
        var userInfo = auth.currentUser!;
        expect(await (userInfo as UserInfoWithIdToken).getIdToken(),
            localAdminUser.uid);
        expect(userInfo.providerId, provider.providerId);

        await auth.signOut();
        expect(auth.currentUser, isNull);
        await auth.signIn(provider,
            options: AuthLocalSignInOptions(localRegularUser));
        expect(auth.currentUser!.uid, localRegularUser.uid);
        try {
          await auth.signIn(provider,
              options: AuthLocalSignInOptions(UserRecordLocal(uid: '-1')));
          fail('should fail');
        } catch (e) {
          expect(e, isNot(const TypeMatcher<TestFailure>()));
        }
        expect(auth.currentUser, isNotNull);
      });
      test('listUsers', () async {
        var user = (await auth.listUsers(maxResults: 1)).users.first!;
        print(userRecordToJson(user));
      });

      test('getUser', () async {
        expect((await auth.getUser('1'))!.displayName, 'admin');
        expect((await auth.getUser('2'))!.displayName, 'user');
      });

      test('getUsers', () async {
        expect(await auth.getUsers(<String>[]), isEmpty);
        expect(
            (await auth.getUsers(['1', '2'])).map((user) => user.emailVerified),
            [true, true]);
        expect((await auth.getUser('2'))!.displayName, 'user');
      });
      test('getUserByEmail', () async {
        expect((await auth.getUserByEmail('admin@example.com'))!.displayName,
            'admin');
        expect((await auth.getUserByEmail('user@example.com'))!.displayName,
            'user');
      });

      group('currentUser', () {
        test('currentUser', () async {
          var user = auth.currentUser;
          print('currentUser: $user');
          user = await auth.onCurrentUser.first;
          print('currentUser: $user');
          if (user != null) {
            expect(user, const TypeMatcher<UserInfoWithIdToken>());
          }
        });
      });

      test('idToken', () async {
        var provider = AuthLocalProvider();
        var result = await auth.signIn(provider,
            options: AuthLocalSignInOptions(localAdminUser));
        var user = result.credential!.user;
        var idToken = await (user as UserInfoWithIdToken).getIdToken();
        var decoded = await auth.verifyIdToken(idToken);
        expect(decoded.uid, localAdminUser.uid);
      });

      test('newAuth', () async {
        var auth1 = newAuthLocal();
        var auth2 = newAuthLocal();
        expect(auth1, isNot(auth2));

        var app = newFirebaseAppLocal();
        var service = newAuthServiceLocal();
        auth1 = service.auth(app);
        auth2 = service.auth(app);
        expect(auth1, auth2);

        auth2 = newAuthServiceLocal().auth(app);
        expect(auth1, auth2);

        auth2 = service.auth(newFirebaseAppLocal());
        expect(auth1, isNot(auth2));
      });
    });
  });
}
