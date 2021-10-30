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
  GoogleAuthProviderRestImpl(this.googleAuthOptions);

  @override
  Future<AuthSignInResult> signIn() async {
    AuthClient authClient;
    var scopes = [
      ...firebaseBaseScopes,
      'https://www.googleapis.com/auth/devstorage.read_write',
      'https://www.googleapis.com/auth/datastore',
      // OAuth scope
      // 'https://www.googleapis.com/auth/firebase'
      //'https://www.googleapis.com/auth/contacts.readonly',
    ];
    var clientId = googleAuthOptions.clientId!;
    // devPrint('signing in...$clientId');
    try {
      var auth2flow =
          await createImplicitBrowserFlow(ClientId(clientId, null), scopes);
      //var result = await auth2flow.runHybridFlow(immediate: false);
      var client = await auth2flow.clientViaUserConsent();

      // devPrint('ID token: ${client.credentials.idToken}');
      client.credentialUpdates.listen((event) {
        // devPrint('update: token ${event.idToken}');
      });
      authClient = client;
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

      var result = AuthSignInResultRest(client: authClient)
        ..hasInfo = true
        ..credential = UserCredentialImpl(
            AuthCredentialImpl(providerId: providerId),
            UserRest(
                uid: person.id!, emailVerified: person.verifiedEmail ?? false));
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
