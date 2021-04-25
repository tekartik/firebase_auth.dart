//@dart=2.9

import 'package:dev_test/package.dart';
import 'package:path/path.dart';

var topDir = '..';

Future<void> main() async {
  for (var dir in [
    'auth',
    'auth_browser',
    'auth_jwt',
    'auth_local',
    'auth_rest',
    'auth_test',
  ]) {
    await packageRunCi(join(topDir, dir));
  }
}
