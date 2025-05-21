@TestOn('browser')
library;

// ignore: deprecated_member_use_from_same_package
import 'package:tekartik_firebase_auth_browser/auth_browser.dart'
    as auth_browser;
// ignore: deprecated_member_use_from_same_package
import 'package:tekartik_firebase_auth_browser/auth_browser.dart';
import 'package:tekartik_firebase_auth_test/auth_test.dart';
import 'package:tekartik_firebase_browser/firebase_browser.dart';
import 'package:test/test.dart';

import 'test_setup.dart';

void main() async {
  var options = await setup();
  if (options == null) {
    return;
  }
  // ignore: deprecated_member_use
  var firebase = firebaseBrowser;

  group('browser', () {
    test('factory', () {
      expect(authServiceBrowser.supportsListUsers, isFalse);
    });
    runAuthTests(
      firebase: firebase,
      authService: authServiceBrowser,
      options: options,
    );

    group('auth', () {
      var app = firebase.initializeApp(options: options, name: 'auth');

      tearDownAll(() {
        return app.delete();
      });

      test('currentUser', () async {
        var auth = authServiceBrowser.auth(app);
        var user = auth.currentUser;
        // print('currentUser: $user');
        user = await auth.onCurrentUser.first;
        // print('currentUser: $user');
        if (user != null) {
          expect(user, const TypeMatcher<UserInfoWithIdToken>());
          expect(user.providerId, isNotNull);
          var token = await (user as UserInfoWithIdToken).getIdToken();
          print('token: $token');
        }
      });

      test('signOut', () async {
        var auth = authServiceBrowser.auth(app) as auth_browser.AuthBrowser;
        //if (auth.currentUser != null) {
        await auth.signOut();
        expect(await auth.onCurrentUser.first, null);
        // }
      });
    });
  });
}
