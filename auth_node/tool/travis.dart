import 'package:process_run/shell.dart';
import 'package:process_run/which.dart';
import 'run_node_test.dart' as run_node_test;
import 'setup_node.dart' as setup_node;

Future main() async {
  var shell = Shell();

  await shell.run('''
dartanalyzer --fatal-warnings --fatal-infos lib test

# pub run build_runner test -- -p vm,chrome
# pub run test -p vm,chrome
''');

  if (whichSync('npm') != null) {
    await setup_node.main();
    await run_node_test.main();
  }
}
