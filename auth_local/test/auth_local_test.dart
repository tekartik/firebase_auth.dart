library tekartik_firebase_sembast.firebase_sembast_memory_test;

import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth/utils/json_utils.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_auth_local/auth_local.dart';
import 'package:tekartik_firebase_auth_test/auth_test.dart';
import 'package:test/test.dart';

void main() {
  var firebase = FirebaseLocal();
  run(firebase: firebase, authService: authServiceLocal);

  group('browser', () {
    test('factory', () {
      expect(authService.supportsListUsers, isTrue);
    });
    run(firebase: firebase, authService: authService);

    group('auth', () {
      App app = firebase.initializeApp(name: 'auth');
      var auth = authServiceLocal.auth(app) as AuthLocal;

      tearDownAll(() {
        return app.delete();
      });

      test('logout/login', () async {
        await auth.signIn(localAdminUser.uid);
        expect(auth.currentUser.uid, localAdminUser.uid);
        expect(await (auth.currentUser as UserInfoWithIdToken).getIdToken(),
            localAdminUser.uid);
        await auth.signOut();
        expect(auth.currentUser, isNull);
        await auth.signIn(localRegularUser.uid);
        expect(auth.currentUser.uid, localRegularUser.uid);
        try {
          await auth.signIn('-1');
          fail('should fail');
        } catch (e) {
          expect(e, isNot(const TypeMatcher<TestFailure>()));
        }
        expect(auth.currentUser, isNull);
      });
      test('listUsers', () async {
        var user = (await auth.listUsers(maxResults: 1)).users?.first;
        print(userRecordToJson(user));
      });

      test('getUser', () async {
        expect(await auth.getUser(null), isNull);
        expect((await auth.getUser("1")).displayName, "admin");
        expect((await auth.getUser("2")).displayName, "user");
      });
      test('getUserByEmail', () async {
        expect(await auth.getUserByEmail(null), isNull);
        expect((await auth.getUserByEmail("admin@example.com")).displayName,
            "admin");
        expect((await auth.getUserByEmail("user@example.com")).displayName,
            "user");
      });

      group('currentUser', () {
        test('currentUser', () async {
          var user = auth.currentUser;
          print('currentUser: $user');
          user = await auth.onCurrentUserChanged.first;
          print('currentUser: $user');
          if (user != null) {
            expect(user, const TypeMatcher<UserInfoWithIdToken>());
          }
        });
      });
    });
  });
}
