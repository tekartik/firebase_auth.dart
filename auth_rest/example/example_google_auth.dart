//import 'package:googleapis/people/v1.dart';
import 'package:googleapis/oauth2/v2.dart';
import 'package:googleapis_auth/auth_browser.dart';
import 'package:tekartik_browser_utils/browser_utils_import.dart';
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth_rest/auth_rest.dart';
import 'package:tekartik_firebase_auth_rest/src/auth_rest.dart';
import 'package:tekartik_firebase_auth_rest/src/google_auth_rest_web.dart';
import 'package:tekartik_firebase_auth_rest/src/identitytoolkit/v3.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';

//import 'package:tekartik_firebase_browser/src/interop.dart';
//import 'package:tekartik_firebase_rest/firebase_rest.dart';

import 'example_common.dart';

Future<void> main() async {
  //write('require :$hasRequire');
  var options = await loadGoogleAuthOptions();
  if (options == null) {
    write('options not laoded. Retry');
    return;
  }
  late AuthRest auth;
  var app = firebaseRest.initializeApp(
      options: AppOptionsRest()..projectId = options.projectId);
  auth = authServiceRest.auth(app) as AuthRest;
  auth.addProvider(GoogleAuthProviderRestWeb(options: options));
  write('loaded');
  auth.onCurrentUser.listen((user) async {
    write('current user: $user');

    var oauth2Api = Oauth2Api(auth.client!);
    // oauth2Api.tokeninfo(accessToken: )
    var tokenInfoResult = await oauth2Api.tokeninfo();
    //write('token: ${tokenInfoResult.accessToken}');
    write(jsonPretty(tokenInfoResult.toJson()));

    var _identitytoolkitApi = IdentityToolkitApi(auth.client!);
    //var _identitytoolkitApi = (auth as AuthRestImpl)
    //  .identitytoolkitApi; //IdentityToolkitApi(auth.client!);
    final request = IdentitytoolkitRelyingpartyVerifyAssertionRequest()
      ..returnSecureToken = true
      ..autoCreate = true
      ..returnIdpCredential = true
      ..requestUri = Uri.base.toString()
      ..returnRefreshToken;
    var assertionResult =
        await _identitytoolkitApi.relyingparty.verifyAssertion(request);
    write('verifyAssertion: ${jsonPretty(assertionResult.toJson())}');

    write('idToken: ${await ((user as UserInfoWithIdToken).getIdToken())}');
    //app.
  });
  /*
  var firebase = fb.firebaseBrowser;
  var authService = authServiceBrowser;

  //Firebase firebase = firebaseBrowser;
  var app = firebase.initializeApp(options: options);

  var delay = parseInt(locationInfo!.arguments['delay']);

  write(
      'native.currentUser1: ${(app as fb_impl.AppBrowser).nativeApp.auth().currentUser}');
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

  querySelector('#signOut')!.onClick.listen((_) async {
    write('signing out...');
    await auth.signOut();
    write('signed out');
  });
*/
  //var clientId =
  // '673610294238-qvk8j295q46sb752nj20oapdjsmrmgde.apps.googleusercontent.com';
  querySelector('#googleSignIn')!.onClick.listen((_) async {
    write('signing in');
    var result = await auth.signIn(GoogleAuthProviderRestWeb(options: options));
    write('done $result');
    var oauth2Api = Oauth2Api(auth.client!);
    var oResult = await oauth2Api.userinfo.v2.me.get();
    write(jsonPretty(oResult.toJson()));
    var tokenInfoResult = await oauth2Api.tokeninfo();
    write(jsonPretty(tokenInfoResult.toJson()));

    // var _identitytoolkitApi = IdentityToolkitApi(auth.client!);
    var _identitytoolkitApi = (auth as AuthRestImpl)
        .identitytoolkitApi; //IdentityToolkitApi(auth.client!);
    final request = IdentitytoolkitRelyingpartyVerifyAssertionRequest()
      ..returnSecureToken = true
      ..autoCreate = true
      ..returnIdpCredential = true
      ..requestUri = Uri.base.toString();
    var assertionResult =
        await _identitytoolkitApi.relyingparty.verifyAssertion(request);
    write('verifyAssertion: ${jsonPretty(assertionResult.toJson())}');

    var getAccountRequest = IdentitytoolkitRelyingpartyGetAccountInfoRequest()
      ..localId = [tokenInfoResult.userId!];
    if (debugRest) {
      print('getAccountInfoRequest2: ${jsonPretty(request.toJson())}');
    }

    var accountResult = await _identitytoolkitApi.relyingparty
        .getAccountInfo(getAccountRequest);

    write('getAccountInfo: ${jsonPretty(accountResult.toJson())}');

    /*
    var verifyResult = await api.relyingparty
        .verifyAssertion(IdentitytoolkitRelyingpartyVerifyAssertionRequest());
    write(verifyResult.toJson());

     */
  });
  querySelector('#rawGoogleSignIn')!.onClick.listen((_) async {
    //write('signing in');
    // var options = await setup();
    var scopes = [
      ...firebaseBaseScopes,
      'https://www.googleapis.com/auth/devstorage.read_write',
      'https://www.googleapis.com/auth/datastore'
    ];
    var clientId = options.clientId!;
    write('signing in...$clientId');
    try {
      var auth2flow =
          await createImplicitBrowserFlow(ClientId(clientId, null), scopes);
      //var result = await auth2flow.runHybridFlow(immediate: false);
      var client = await auth2flow.clientViaUserConsent(immediate: true);

      /*
      authClient = client;
      write(authClient);
      write(client.credentials.accessToken);
      var appOptions = AppOptionsRest(client: authClient)
        ..projectId = options.projectId;
      var app = await firebaseRest.initializeAppAsync(options: appOptions);
      auth = authServiceRest.auth(app);

       */
      var oauth2Api = Oauth2Api(client);
      // oauth2Api.tokeninfo(accessToken: )
      var tokenInfoResult = await oauth2Api.tokeninfo();
      write(jsonPretty(tokenInfoResult.toJson()));

      // Get me special!
      final person = await oauth2Api.userinfo.get();
      write(jsonPretty(person.toJson()));
      write(auth.currentUser);
    } catch (e) {
      write('error $e');
    }
    write('signing done');

    /*
    write('signing in...');
    try {
      var result = await auth.signIn(GoogleAuthProvider());
      write('signed in result $result');
    } catch (e) {
      write('signed in error $e');
    }*/
  });

  querySelector('#rawGoogleCredentials')!.onClick.listen((_) async {
    //write('signing in');
    // var options = await setup();
    var scopes = [
      ...firebaseBaseScopes,
      'https://www.googleapis.com/auth/devstorage.read_write',
      'https://www.googleapis.com/auth/datastore'
    ];
    var clientId = options.clientId!;
    write('auto signing in...$clientId');
    try {
      var auth2flow =
          await createImplicitBrowserFlow(ClientId(clientId, null), scopes);
      //var result = await auth2flow.runHybridFlow(immediate: false);
      write('#2');
      var credentials = await auth2flow.obtainAccessCredentialsViaUserConsent(
          immediate: true);
      write('#3');
      write(credentials.accessToken);
      var authClient = await auth2flow.clientViaUserConsent(immediate: true);

      /*
      authClient = client;
      write(authClient);
      write(client.credentials.accessToken);
      var appOptions = AppOptionsRest(client: authClient)
        ..projectId = options.projectId;
      var app = await firebaseRest.initializeAppAsync(options: appOptions);
      auth = authServiceRest.auth(app);

       */

      var oauth2Api = Oauth2Api(authClient);

      // Get me special!
      final person = await oauth2Api.userinfo.get();
      write(jsonPretty(person.toJson()));
      //write(auth.currentUser);
    } catch (e) {
      write('error $e');
    }
    write('signing done');

    /*
    write('signing in...');
    try {
      var result = await auth.signIn(GoogleAuthProvider());
      write('signed in result $result');
    } catch (e) {
      write('signed in error $e');
    }*/
  });
/*
  querySelector('#googleSignInWithPopup')!.onClick.listen((_) async {
    write('popup signing in...');
    try {
      await auth.signIn(GoogleAuthProvider(),
          options: AuthBrowserSignInOptions(isPopup: true));
      write('signed in');
    } catch (e) {
      write('signed in error $e');
    }
  });

  querySelector('#googleSignInWithRedirect')!.onClick.listen((_) async {
    write('signing in...');
    try {
      await auth.signIn(GoogleAuthProvider(),
          options: AuthBrowserSignInOptions(isRedirect: true));
      write('signed in maybe...');
    } catch (e) {
      write('signed in error $e');
    }
  });

  querySelector('#getUser')!.onClick.listen((_) async {
    try {
      if (auth.currentUser?.uid == null) {
        write('Not authentified');
      } else {
        var result = await auth.getUser(auth.currentUser!.uid);
        write(result);
      }
    } catch (e) {
      write('getUser error $e');
    }
  });
  */
  querySelector('#restGetUser')!.onClick.listen((_) async {
    var oauth2 = Oauth2Api(auth.client!);
    var userInfo = await oauth2.userinfo.get();
    write(jsonPretty(userInfo.toJson()));
    // devPrint(auth.currentUser);
    var request = IdentitytoolkitRelyingpartyGetAccountInfoRequest()
      ..idToken =
          //  ..localId = [auth.currentUser!.uid]
          '';
    //devWarning;
    if (debugRest) {
      print('getAccountInfoRequest: ${jsonPretty(request.toJson())}');
    }
    var _identitytoolkitApi = IdentityToolkitApi(auth.client!);
    var result = await _identitytoolkitApi.relyingparty.getAccountInfo(request);
    // var api = IdentityToolkitApi(auth.client!);
    //auth.iden(uid)
    write(jsonPretty(result.toJson()));

    try {
      var user = await auth.getUser(userInfo.id!);
      write(user);
      // ignore: dead_code
      if (false) {
        // authClient == null) {
        write('Not authentified');
      } else {
        /*
        // var result = await auth.reloadCurrentUser(auth.currentUser!.uid);

        write('getting token');
        var token =
            await (auth.currentUser as UserInfoWithIdToken).getIdToken();
        write('token: $token');
        var restApp = firebaseRest.initializeApp(
            name: 'access_token',
            options: getAppOptionsFromAccessToken(Client(), token,
                projectId: options.projectId!,
                scopes: [firebaseGoogleApisUserEmailScope]));


        var restAuth = authServiceRest.auth(restApp);

        // var result = await auth.getUser(auth.currentUser!.uid);

         */

        // write(result);
      }
    } catch (e) {
      write('getUser error $e');
    }
  });
  querySelector('#currentUser')!.onClick.listen((_) async {
    write('currentUser ${auth.currentUser}');
  });
/*
  querySelector('#onCurrentUser')!.onClick.listen((_) async {
    write('wait for first onCurrentUser');
    write('onCurrentUser ${await auth.onCurrentUser.first}');
  });
  querySelector('#reloadWithDelay')!.onClick.listen((_) async {
    window.location.href = 'example_auth.html?delay=3000';
  });*/
}
