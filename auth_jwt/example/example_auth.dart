import 'package:tekartik_browser_utils/location_info_utils.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_auth/auth.dart';
// ignore: deprecated_member_use
import 'package:tekartik_firebase_auth_browser/auth_browser.dart';
import 'package:tekartik_firebase_auth_jwt/src/auth_info.dart';
import 'package:tekartik_firebase_auth_jwt/src/scopes.dart';
import 'package:tekartik_firebase_browser/firebase_browser.dart' as fb;
import 'package:tekartik_firebase_browser/src/firebase_browser.dart' as fb_impl;
//import 'package:tekartik_firebase_browser/src/interop.dart';
import 'package:web/web.dart';

import 'example_common.dart';
import 'example_setup.dart';

void main() async {
  var options = await setup();
  write('loaded');
  // ignore: deprecated_member_use
  var firebase = fb.firebaseBrowser;
  var authService = authServiceBrowser;

  //Firebase firebase = firebaseBrowser;
  var app = firebase.initializeApp(options: options);

  var delay = parseInt(locationInfo!.arguments['delay']);
  write(
    'native.currentUser1: ${(app as fb_impl.AppBrowser).nativeApp.auth().currentUser}',
  );
  app.nativeApp.auth().onAuthStateChanged.listen((user) {
    write('native.onAuthStateChanged1: $user');
  });
  app.nativeApp.auth().onIdTokenChanged.listen((user) {
    write('native.onIdTokenChanged1: $user');
  });

  var auth = authService.auth(app) as AuthBrowser;

  if (delay != null) {
    await sleep(delay);
  }

  write('native.currentUser2: ${app.nativeApp.auth().currentUser}');
  app.nativeApp.auth().onAuthStateChanged.listen((user) {
    write('native.onAuthStateChanged2: $user');
  });
  app.nativeApp.auth().onIdTokenChanged.listen((user) {
    write('native.onIdTokenChanged2: $user');
  });

  auth.onAuthStateChanged.listen((User? user) {
    write('onAuthStateChanged: $user');
  });

  auth.onCurrentUser.listen((User? user) {
    write('onCurrentUser: $user');
  });
  write('app ${app.name}');
  write('currentUser ${auth.currentUser}');

  document.querySelector('#signOut')!.onClick.listen((_) async {
    write('signing out...');
    await auth.signOut();
    write('signed out');
  });

  // ignore: no_leading_underscores_for_local_identifiers
  GoogleAuthProvider? _authPovider;
  GoogleAuthProvider getAuthPovider() =>
      _authPovider ??
      () {
        var provider = GoogleAuthProvider()
          ..addScope(firebaseGoogleApisFirebaseDatabaseScope)
          ..addScope(firebaseGoogleApisUserEmailScope);
        return provider;
      }();
  document.querySelector('#googleSignIn')!.onClick.listen((_) async {
    write('signing in...');
    try {
      var result = await auth.signIn(getAuthPovider());
      write('signed in result $result');
    } catch (e) {
      write('signed in error $e');
    }
  });

  document.querySelector('#googleSignInWithPopup')!.onClick.listen((_) async {
    write('popup signing in...');
    try {
      await auth.signIn(
        getAuthPovider(),
        options: AuthBrowserSignInOptions(isPopup: true),
      );
      write('signed in');
    } catch (e) {
      write('signed in error $e');
    }
  });

  document.querySelector('#googleSignInWithRedirect')!.onClick.listen((
    _,
  ) async {
    write('signing in...');
    try {
      await auth.signIn(
        getAuthPovider(),
        options: AuthBrowserSignInOptions(isRedirect: true),
      );
      write('signed in maybe...');
    } catch (e) {
      write('signed in error $e');
    }
  });

  document.querySelector('#currentUser')!.onClick.listen((_) async {
    write('currentUser ${auth.currentUser}');
    write('providerId: ${auth.currentUser?.providerId}');
  });

  document.querySelector('#getIdToken')!.onClick.listen((_) async {
    var idToken = await (auth.currentUser as UserInfoWithIdToken).getIdToken(
      forceRefresh: false,
    );
    write('IdToken $idToken');
    var jwt = FirebaseAuthInfo.fromIdToken(idToken);
    write(jsonPretty(jwt));
    write(jsonPretty(jwt.toDebugMap()));

    /*
    var database = jwt.payload.projectId;
    var userId = jwt.payload.userId;
    var record = await databaseGetRecord(
        idToken: idToken,
        database: database,
        path: '/_check_user_access/$userId');
    write(record);
     */
    try {
      await jwt.verify();
      write('verified');
    } catch (e) {
      write('verified failed $e');
    }
  });

  document.querySelector('#onCurrentUser')!.onClick.listen((_) async {
    write('wait for first onCurrentUser');
    write('onCurrentUser ${await auth.onCurrentUser.first}');
  });
  document.querySelector('#reloadWithDelay')!.onClick.listen((_) async {
    window.location.href = 'example_auth.html?delay=3000';
  });
}
