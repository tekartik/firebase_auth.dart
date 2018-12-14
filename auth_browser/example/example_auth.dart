import 'dart:html';

import 'package:tekartik_firebase/firebase.dart' as fb;
import 'package:tekartik_firebase_browser/firebase_browser.dart' as fb;
import 'package:tekartik_firebase_auth_browser/auth_browser.dart';
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
  AuthBrowser auth = authServiceBrowser.auth(app) as AuthBrowser;

  auth.onAuthStateChanged.listen((User user) {
    write('onAuthStateChanged: $user');
  });
  write('app ${app.name}');

  querySelector('#signOut').onClick.listen((_) async {
    write('signing out...');
    await auth.signOut();
    write('signed out');
  });

  querySelector('#googleSignIn').onClick.listen((_) async {
    write('signing in...');
    await auth.signInPopup(GoogleAuthProvider());
    write('signed in');
  });

  querySelector('#googleSignInWithRedirect').onClick.listen((_) async {
    write('signing in...');
    await auth.signInWithRedirect(GoogleAuthProvider());
    write('signed in');
  });
}
