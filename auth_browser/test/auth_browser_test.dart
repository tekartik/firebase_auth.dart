@TestOn('browser')
library tekartik_firebase_auth_browser.auth_browser_test;

import 'package:tekartik_firebase/firebase.dart' as fb;
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_browser/firebase_browser.dart';
import 'package:tekartik_firebase_auth_browser/auth_browser.dart';
import 'package:tekartik_firebase_auth_browser/auth_browser.dart'
    as auth_browser;
import 'package:tekartik_firebase_auth_test/auth_test.dart';
import 'package:test/test.dart';

import 'test_setup.dart';

void main() async {
  var options = await setup();
  if (options == null) {
    return;
  }
  var firebase = firebaseBrowser;

  group('browser', () {
    test('factory', () {
      expect(authService.supportsListUsers, isFalse);
    });
    run(firebase: firebase, authService: authService, options: options);

    group('auth', () {
      fb.App app = firebase.initializeApp(options: options, name: 'auth');

      tearDownAll(() {
        return app.delete();
      });

      test('currentUser', () async {
        var auth = authServiceBrowser.auth(app);
        var user = auth.currentUser;
        // print('currentUser: $user');
        user = await auth.onCurrentUserChanged.first;
        // print('currentUser: $user');
        if (user != null) {
          expect(user, const TypeMatcher<UserInfoWithIdToken>());
          var token = await (user as UserInfoWithIdToken).getIdToken();
          print('token: $token');
        }
      });

      test('signOut', () async {
        var auth = authServiceBrowser.auth(app) as auth_browser.AuthBrowser;
        await auth.signOut();
        expect(await auth.onAuthStateChanged.take(1).toList(), [null]);
      });
    });
  });
}
