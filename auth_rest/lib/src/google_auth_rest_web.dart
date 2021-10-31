import 'package:googleapis/oauth2/v2.dart';
import 'package:googleapis_auth/auth_browser.dart';
import 'package:http/browser_client.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_auth/auth.dart';
//import 'package:tekartik_firebase_auth/src/auth.dart';
import 'package:tekartik_firebase_auth_rest/src/auth_rest.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:yaml/yaml.dart';

import 'google_auth_rest.dart';

class GoogleAuthProviderRestImpl
    with GoogleRestAuthProviderMixin
    implements GoogleAuthProviderRestWeb {
  final GoogleAuthOptions googleAuthOptions;
  AuthClient? _authClient;
  @override
  AuthClient get currentAuthClient => _authClient!;
  @override
  AuthClient get client => _authClient!;
  @override
  String get apiKey => googleAuthOptions.apiKey!;
  late final List<String> scopes;
  GoogleAuthProviderRestImpl(this.googleAuthOptions, {List<String>? scopes}) {
    this.scopes = scopes ??
        [
          ...firebaseBaseScopes,
          'https://www.googleapis.com/auth/devstorage.read_write',
          'https://www.googleapis.com/auth/datastore',
          // OAuth scope
          // 'https://www.googleapis.com/auth/firebase'
          //'https://www.googleapis.com/auth/contacts.readonly',
          'https://www.googleapis.com/auth/contacts.readonly'
        ];
  }

  BrowserOAuth2Flow? _auth2flow;

  Future<BrowserOAuth2Flow> get auth2flow async {
    var clientId = googleAuthOptions.clientId!;
    _auth2flow ??=
        await createImplicitBrowserFlow(ClientId(clientId, null), scopes);

    return _auth2flow!;
  }

  StreamController<UserRest?>? currentUserController;
  User? _currentUser;
  User? get currentUser => _currentUser;
  @override
  Stream<User?> get onCurrentUser {
    late StreamController<User?> ctlr;
    ctlr = currentUserController ??=
        StreamController.broadcast(onListen: () async {
      var auth2flow = await this.auth2flow;
      try {
        var client = await auth2flow.clientViaUserConsent(immediate: true);
        _authClient = client;
        var credentials = client.credentials;
        _setCurrent(toUserRest(credentials));
      } catch (_) {
        _setCurrent(null);
      }
    });

    return ctlr.stream;
  }

  void _setCurrent(User? user) {
    _currentUser = user as UserRest?;
    var ctlr = currentUserController;
    if (ctlr != null) {
      ctlr.add(user);
    }
  }

  // Future<String> getIdToken() async {}
  Future<UserRest?> getUserMe() async {
    return null;
    /*
    final SecureTokenApi secureTokenApi = SecureTokenApi(
      client: auth._apiKeyClient,
      accessToken: accessToken,
      accessTokenExpirationDate: accessTokenExpirationDate,
      refreshToken: refreshToken,
    );

    final FirebaseUser user =
        FirebaseUser._(secureTokenApi: secureTokenApi, auth: auth);
    final String newAccessToken = await user._getToken();

    final IdentitytoolkitRelyingpartyGetAccountInfoRequest request =
        IdentitytoolkitRelyingpartyGetAccountInfoRequest()
          ..idToken = newAccessToken;

    final GetAccountInfoResponse response =
        await auth._firebaseAuthApi.getAccountInfo(request);

    return user
      .._isAnonymous = anonymous
      .._updateWithUserDataResponse(response);
     */
  }

  UserRest toUserRest(AccessCredentials credentials) {
    return UserRest(emailVerified: true, uid: '', provider: this)
      ..accessCredentials = credentials;
  }

  @override
  Future<AuthSignInResult> signIn() async {
    AuthClient authClient;

    // var clientId = googleAuthOptions.clientId!;
    // devPrint('signing in...$clientId');
    try {
      _auth2flow?.close();
      var auth2flow = await this.auth2flow;
      var runResult = await auth2flow.runHybridFlow(immediate: false);
      var client = runResult.newClient();
      //var client = await auth2flow.clientViaUserConsent();

      // devPrint('ID token: ${client.credentials.idToken}');
      client.credentialUpdates.listen((event) {
        // devPrint('update: token ${event.idToken}');
      });
      _authClient = authClient = client;
      // devPrint(authClient);
      // devPrint(client.credentials.accessToken);
      /*
      var appOptions = AppOptionsRest(client: authClient)
        ..projectId = googleAuthOptions.projectId;

       */
      /*
      var app = await firebaseRest.initializeAppAsync(options: appOptions);
      auth = authServiceRest.auth(app);
      */
      var oauth2Api = Oauth2Api(authClient);

      // Get me special!
      final person = await oauth2Api.userinfo.get();

      // devPrint(jsonPretty(person.toJson()));
      // devPrint(auth.currentUser);

      var result = AuthSignInResultRest(client: authClient, provider: this)
        ..hasInfo = true
        ..credential = UserCredentialImpl(
            AuthCredentialImpl(providerId: providerId),
            UserRest(
                uid: person.id!,
                emailVerified: person.verifiedEmail ?? false,
                provider: this));
      return result;
    } catch (e) {
      // devPrint('error $e');
      rethrow;
    }
    // devPrint('signing done');
  }
}

abstract class GoogleAuthProviderRestWeb implements GoogleRestAuthProvider {
  factory GoogleAuthProviderRestWeb({required GoogleAuthOptions options}) =>
      GoogleAuthProviderRestImpl(options);
}

Future<GoogleAuthOptions?> loadGoogleAuthOptions() async {
  // Load javascript
  // await loadFirebaseJs();
  var client = BrowserClient();

  // Load client info
  try {
    var sample = await client.read(Uri.parse('sample.local.config.yaml'));

    try {
      var local = await client.read(Uri.parse('local.config.yaml'));
      var map = (loadYaml(local) as Map).cast<String, Object?>();
      var options = GoogleAuthOptions.fromMap(map);
      if (options.projectId == null) {
        print('Missing "projectId" in local.config.yaml');
        return null;
      }
      return options;
    } catch (e) {
      print(e);
      print('Cannot find local.config.yaml');
      print(
          'Create it from the sample.local.config.yaml file with your firebase information');
      print(sample);
    }
  } catch (e) {
    print(e);
    print('Cannot find sample.local.config.yaml');
    print('Make sure to run the test using something like: ');
    print('  pub run build_runner test --fail-on-severe -- -p chrome');
  }
  return null;
}
