// ignore: depend_on_referenced_packages
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase/firebase.dart' as fb;
import 'package:tekartik_firebase/firebase_mixin.dart' as fb;
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:test/test.dart';
export 'package:tekartik_firebase_auth/auth.dart';

bool skipConcurrentTransactionTests = false;

void runAuthTests(
    {required fb.Firebase firebase,
    required FirebaseAuthService authService,
    String? name,
    fb.AppOptions? options}) {
  var app = firebase.initializeApp(options: options, name: name);
  setUpAll(() async {});
  tearDownAll(() {
    return app.delete();
  });

  var auth = authService.auth(app);
  runAuthAppTests(authService: authService, auth: auth, app: app);
}

@Deprecated('Use runAuthAppTests instead')
void runApp(
        {required FirebaseAuthService authService,
        required FirebaseAuth auth,
        required fb.App app}) =>
    runAuthAppTests(authService: authService, auth: auth, app: app);

void runAuthAppTests(
    {required FirebaseAuthService authService,
    FirebaseAuth? auth,
    required fb.App app}) {
  var firebaseAuth = auth ?? authService.auth(app);
  setUpAll(() async {});
  group('auth', () {
    test('app', () {
      expect(firebaseAuth.app, app);
      expect(firebaseAuth.service, authService);
    });
    test('unique', () {
      expect(authService.auth(app), firebaseAuth);
      if (app is fb.FirebaseAppMixin) {
        expect(app.getProduct<FirebaseAuth>(), authService.auth(app));
      }
    });

    group('listUsers', () {
      test('one', () async {
        try {
          var user =
              (await firebaseAuth.listUsers(maxResults: 1)).users.firstOrNull;
          print('user: $user');
        } catch (e) {
          // Error: Credential implementation provided to initializeApp() via the 'credential' property has insufficient permission to access the requested resource. See https://firebase.google.com/docs/admin/setup for details on how to authenticate this SDK with appropriate permissions.
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
        Future checkUser(UserInfo? user) async {
          if (user != null) {
            if (user is UserInfoWithIdToken) {
              print(
                  'idToken: ${await (user as UserInfoWithIdToken).getIdToken()}');
            }
            expect(user.providerId, isNotNull);
          }
        }

        var user = firebaseAuth.currentUser;
        print('currentUser: $user');
        await checkUser(user);

        user = await firebaseAuth.onCurrentUser.first;
        print('currentUser: $user');
        await checkUser(user);
      });
    }, skip: !authService.supportsCurrentUser);
  });
}
