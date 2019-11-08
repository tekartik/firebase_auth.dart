import 'package:meta/meta.dart';
import 'package:tekartik_firebase/firebase.dart' as fb;
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth/utils/json_utils.dart';
import 'package:test/test.dart';

bool skipConcurrentTransactionTests = false;

void run(
    {@required fb.Firebase firebase,
    @required AuthService authService,
    fb.AppOptions options}) {
  fb.App app = firebase.initializeApp(options: options);

  tearDownAll(() {
    return app.delete();
  });

  var auth = authService.auth(app);
  runApp(authService: authService, auth: auth, app: app);
}

void runApp(
    {@required AuthService authService,
    @required Auth auth,
    @required fb.App app}) {
  setUpAll(() async {});
  group('auth', () {
    test('unique', () {
      expect(authService.auth(app), auth);
    });
    group('listUsers', () {
      test('one', () async {
        try {
          var user = (await auth.listUsers(maxResults: 1)).users?.first;
          print(userRecordToJson(user));
        } catch (e) {
          // Error: Credential implementation provided to initializeApp() via the "credential" property has insufficient permission to access the requested resource. See https://firebase.google.com/docs/admin/setup for details on how to authenticate this SDK with appropriate permissions.
          if (e.toString().contains('insufficient permission')) {
            // Ok!
            print('insufficient permission $e');
          } else {
            print('runtimeType: ${e.runtimeType}');
            print(e);
            rethrow;
          }
        }
      });
    }, skip: !authService.supportsListUsers);

    group('currentUser', () {
      test('currentUser', () async {
        Future _checkUser(UserInfo user) async {
          if (user != null) {
            if (user is UserInfoWithIdToken) {
              print(
                  'idToken: ${await (user as UserInfoWithIdToken).getIdToken()}');
            }
            expect(user.providerId, isNotNull);
          }
        }

        var user = auth.currentUser;
        print('currentUser: $user');
        await _checkUser(user);

        user = await auth.onCurrentUser.first;
        print('currentUser: $user');
        await _checkUser(user);
      });
    }, skip: !authService.supportsCurrentUser);
  });
}
