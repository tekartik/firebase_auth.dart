import 'dart:html';

import 'package:tekartik_firebase_auth_jwt/src/import.dart';

OutBuffer _outBuffer = OutBuffer(100);
Element? _output = document.getElementById('output');
void write([Object? message]) {
  print(message);
  _output!.text = (_outBuffer..add('$message')).toString();
}
