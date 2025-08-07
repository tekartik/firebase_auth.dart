import 'package:dev_build/package.dart';
import 'package:path/path.dart';

var topDir = '..';

Future<void> main() async {
  for (var dir in [
    'auth',
    'auth_jwt',
    'auth_local',
    'auth_sembast',
    'auth_test',
  ]) {
    await packageRunCi(join(topDir, dir));
  }
}
