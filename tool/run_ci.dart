//@dart=2.9

import 'package:dev_test/package.dart';

Future<void> main() async {
  for (var dir in [
    'auth',
    'auth_browser',
    'auth_flutter',
    'auth_jwt',
    'auth_local',
    'auth_node',
    'auth_rest',
    'auth_test',
  ]) {
    await packageRunCi(dir);
  }
}
