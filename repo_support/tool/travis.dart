import 'package:path/path.dart';
import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();

  for (var dir in [
    'auth_local',
    'auth_browser',
    'auth_test',
    'auth_rest',
    'auth_jwt',
    'auth',
  ]) {
    shell = shell.pushd(join('..', dir));
    await shell.run('''
    
  pub get
  dart tool/travis.dart
  
''');
    shell = shell.popd();
  }
}
