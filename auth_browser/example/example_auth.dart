import 'dart:html';

import 'package:tekartik_browser_utils/browser_utils_import.dart';
import 'package:tekartik_browser_utils/location_info_utils.dart';
import 'package:tekartik_firebase/firebase.dart' as fb;
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth_browser/auth_browser.dart';
import 'package:tekartik_firebase_browser/firebase_browser.dart' as fb;
import 'package:tekartik_firebase_browser/src/firebase_browser.dart' as fb_impl;
import 'package:tekartik_firebase_browser/src/interop.dart';

import 'example_common.dart';
import 'example_setup.dart';

void main() async {
  write("require :${hasRequire}");
  var options = await setup();
  write("loaded");
  fb.Firebase firebase = fb.firebaseBrowser;

  //Firebase firebase = firebaseBrowser;
  fb.App app = firebase.initializeApp(options: options);

  var delay = parseInt(locationInfo.arguments['delay']);
  write(
      'native.currentUser1: ${(app as fb_impl.AppBrowser).nativeApp.auth().currentUser}');
  (app as fb_impl.AppBrowser)
      .nativeApp
      .auth()
      .onAuthStateChanged
      .listen((user) {
    write('native.onAuthStateChanged1: $user');
  });
  (app as fb_impl.AppBrowser).nativeApp.auth().onIdTokenChanged.listen((user) {
    write('native.onIdTokenChanged1: $user');
  });

  if (delay != null) {
    await sleep(delay);
  }

  write(
      'native.currentUser2: ${(app as fb_impl.AppBrowser).nativeApp.auth().currentUser}');
  (app as fb_impl.AppBrowser)
      .nativeApp
      .auth()
      .onAuthStateChanged
      .listen((user) {
    write('native.onAuthStateChanged2: $user');
  });
  (app as fb_impl.AppBrowser).nativeApp.auth().onIdTokenChanged.listen((user) {
    write('native.onIdTokenChanged2: $user');
  });
  AuthBrowser auth = authServiceBrowser.auth(app) as AuthBrowser;

  auth.onAuthStateChanged.listen((fb.User user) {
    write('onAuthStateChanged: $user');
  });

  auth.onCurrentUserChanged.listen((UserInfo userInfo) {
    write('onCurrentUserChanged: $userInfo');
  });
  write('app ${app.name}');
  write('currentUser ${auth.currentUser}');

  querySelector('#signOut').onClick.listen((_) async {
    write('signing out...');
    await auth.signOut();
    write('signed out');
  });

  querySelector('#googleSignIn').onClick.listen((_) async {
    write('signing in...');
    try {
      var result = await auth.signIn(GoogleAuthProvider());
      write('signed in result $result');
    } catch (e) {
      write('signed in error $e');
    }
  });

  querySelector('#googleSignInWithPopup').onClick.listen((_) async {
    write('popup signing in...');
    try {
      await auth.signIn(GoogleAuthProvider(),
          options: AuthBrowserSignInOptions(isPopup: true));
      write('signed in');
    } catch (e) {
      write('signed in error $e');
    }
  });

  querySelector('#googleSignInWithRedirect').onClick.listen((_) async {
    write('signing in...');
    try {
      await auth.signIn(GoogleAuthProvider(),
          options: AuthBrowserSignInOptions(isRedirect: true));
      write('signed in maybe...');
    } catch (e) {
      write('signed in error $e');
    }
  });

  querySelector('#currentUser').onClick.listen((_) async {
    write('currentUser ${auth.currentUser}');
  });

  querySelector('#onCurrentUser').onClick.listen((_) async {
    write('wait for first onCurrentUser');
    write('onCurrentUser ${await auth.onCurrentUser.first}');
  });
  querySelector('#reloadWithDelay').onClick.listen((_) async {
    window.location.href = 'example_auth.html?delay=3000';
  });
}
