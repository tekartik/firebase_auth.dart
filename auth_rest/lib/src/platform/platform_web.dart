import 'package:tekartik_firebase_auth_rest/auth_rest.dart';
import 'package:tekartik_firebase_auth_rest/src/google_auth_rest.dart';

export 'package:tekartik_firebase_auth_rest/src/google_auth_rest_web.dart'
    show GoogleAuthProviderRestWeb;

abstract class GoogleAuthProviderRestIo implements GoogleRestAuthProvider {
  factory GoogleAuthProviderRestIo(
          {required GoogleAuthOptions options,
          PromptUserForConsentRest? userPrompt,
          String? credentialPath}) =>
      throw UnsupportedError('io');
}
