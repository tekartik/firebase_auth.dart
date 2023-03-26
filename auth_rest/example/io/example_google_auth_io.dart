// ignore_for_file: directives_ordering

import 'dart:io';

import 'package:tekartik_firebase_auth_rest/auth_rest.dart';
import 'package:tekartik_firebase_auth_rest/src/google_auth_rest_io.dart';
import 'package:tekartik_firebase_rest/firebase_rest.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart';

Future<void> main() async {
  var authService = authServiceRest;
  var options = GoogleAuthOptions.fromMap(loadYaml(
          await File(join('example', 'local.config_io.yaml')).readAsString())
      as Map);
  var app = firebaseRest.initializeApp(
      options: AppOptionsRest()
        ..projectId = options.projectId
        ..apiKey = options.apiKey);
  var auth = authService.auth(app);
  var result = await auth.signIn(GoogleAuthProviderRestIo(
      options: options,
      credentialPath:
          join('example', 'local.config_io.user.credentials.yaml')));
  print(result);
  print(options);
}
