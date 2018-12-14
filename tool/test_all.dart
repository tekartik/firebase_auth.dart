//import 'package:tekartik_build_utils/cmd_run.dart';
import 'package:tekartik_build_utils/common_import.dart';

Future testAuth() async {
  var dir = 'auth';
  await runCmd(PubCmd(pubRunTestArgs(platforms: ['vm', 'chrome']))
    ..workingDirectory = dir);
}

Future testAuthLocal() async {
  var dir = 'auth_local';
  await runCmd(PubCmd(pubRunTestArgs(platforms: ['vm', 'chrome']))
    ..workingDirectory = dir);
}

Future testAuthBrowser() async {
  var dir = 'auth_browser';
  await runCmd(
      PubCmd(pubRunTestArgs(platforms: ['chrome']))..workingDirectory = dir);
}

Future testAuthNode() async {
  var dir = 'auth_node';
  //await runCmd(PubCmd(pubGetArgs())..workingDirectory = dir);
  //await runCmd(DartAnalyzerCmd(['lib', 'test'])..workingDirectory = dir);
  await runCmd(
      PubCmd(pubRunTestArgs(platforms: ['node']))..workingDirectory = dir);
}

Future testAuthTest() async {
  //var dir = 'auth_test';
  //await runCmd(PubCmd(pubGetArgs())..workingDirectory = dir);
  //await runCmd(DartAnalyzerCmd(['lib'])..workingDirectory = dir);
}

Future main() async {
  await testAuth();
  await testAuthLocal();
  await testAuthBrowser();
  await testAuthNode();
  // await testAuth();
  await testAuthTest();
}
