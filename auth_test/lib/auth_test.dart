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
  runApp(authService: authService, auth: auth);
}

void runApp({@required AuthService authService, @required Auth auth}) {
  setUpAll(() async {});
  group('auth', () {
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
        var user = auth.currentUser;
        print('currentUser: $user');
        user = await auth.onCurrentUserChanged.first;
        print('currentUser: $user');

        if (user is UserInfoWithIdToken) {
          print('idToken: ${(user as UserInfoWithIdToken).getIdToken()}');
        }
      });
    }, skip: !authService.supportsCurrentUser);
  });
}
