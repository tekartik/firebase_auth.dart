import 'dart:async';

import 'package:process_run/shell.dart';
import 'package:process_run/stdio.dart';

Future main() async {
  var shell = Shell();

  stdout.writeln('http://localhost:8060/example_auth.html');
  await shell.run('''
  
  pub global run webdev serve example:8060 --auto refresh
  
  ''');
}
