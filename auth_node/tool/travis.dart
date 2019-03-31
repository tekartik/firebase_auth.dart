import 'package:process_run/shell.dart';
import 'package:process_run/which.dart';
import 'build_node_test.dart' as build_node_test;
import 'setup_node.dart' as setup_node;

Future main() async {
  var shell = Shell();

  await shell.run('''
dartanalyzer --fatal-warnings --fatal-infos lib test

''');

  if (whichSync('npm') != null) {
    await setup_node.main();
    await build_node_test.main();
  }
}
