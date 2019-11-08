library tekartik_firebase_sembast.firebase_sembast_memory_test;

import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth/utils/json_utils.dart';
import 'package:tekartik_firebase_auth_rest/auth_rest.dart';
import 'package:tekartik_firebase_auth_test/auth_test.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:test/test.dart';

import 'test_setup.dart';

Future main() async {
  var context = await setup();
  var firebase = firebaseRest;

  group('auth_rest', () {
    if (context != null) {
      run(firebase: firebase, authService: authServiceRest);
    }

    test('factory', () {
      expect(authService.supportsListUsers, isFalse);
      expect(authService.supportsCurrentUser, isFalse);
    });
    run(firebase: firebase, authService: authService);

    group('auth', () {
      App app;
      AuthRest auth;

      setUpAll(() async {
        app = firebase.initializeApp(name: 'auth', options: context?.options);
        auth = authServiceRest.auth(app) as AuthRest;
      });

      tearDownAll(() {
        return app.delete();
      });

      test('getUserInfo', () async {
        var user = auth.currentUser;
        expect(user, isNull);
        // devPrint('user: $user');
        String userId = 'gpt1QKVyJMcLHh2MM2x4THAaQW63';
        var userRecord = await auth.getUser(userId);
        if (userRecord != null) {
          expect(userRecord.displayName, isNotNull);
          print('userRecord: $userRecord');
        }
        //expect(true, isFalse);
      });

      test('getUsers', () async {
        var user = auth.currentUser;
        expect(user, isNull);
        // devPrint('user: $user');
        String userId = 'gpt1QKVyJMcLHh2MM2x4THAaQW63';
        var userRecords =
            await auth.getUsers([userId, 'NX8geaeHWCcibyp2YWeyU7UqEtN2']);
        if (userRecords?.isNotEmpty ?? false) {
          for (int i = 0; i < userRecords.length; i++) {
            var userRecord = userRecords[i];
            expect(userRecord.displayName, isNotNull);
            print('userRecords[$i]: $userRecord');
          }
        }
        //expect(true, isFalse);
      });

      test('listUsers', () async {
        try {
          var users = (await auth.listUsers(maxResults: 1)).users?.first;
          print(userRecordToJson(users));
          fail('should fail');
        } on UnsupportedError catch (_) {}
      });

      test('getUserByEmail', () async {
        try {
          expect(await auth.getUserByEmail(null), isNull);
          expect((await auth.getUserByEmail("admin@example.com")).displayName,
              "admin");
          expect((await auth.getUserByEmail("user@example.com")).displayName,
              "user");
          fail('should fail');
        } on UnsupportedError catch (_) {}
      });

      group('currentUser', () {
        test('currentUser', () async {
          var user = auth.currentUser;
          expect(user, isNull);
          print('currentUser: $user');
          try {
            user = await auth.onCurrentUser.first;
            print('currentUser: $user');
            if (user != null) {
              expect(user, const TypeMatcher<UserInfoWithIdToken>());
            }
            fail('should fail');
          } on UnsupportedError catch (_) {}
        });
      });

      test('idToken', () async {
        if (context.authClient != null) {
          /*
          var provider = AuthLocalProvider();
          var result = await auth.signIn(provider,
              options: AuthLocalSignInOptions(localAdminUser));
          var user = result.credential.user;
          var idToken = await (user as UserInfoWithIdToken).getIdToken();
          var decoded = await auth.verifyIdToken(idToken);
          expect(decoded.uid, localAdminUser.uid);

           */
        }
      });
    });
  }, skip: context == null);
}
