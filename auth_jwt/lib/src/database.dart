import 'package:http/http.dart';
import 'package:tekartik_firebase_auth_jwt/src/import.dart';

//
// Unused
//

//
class UnauthorizedDatabaseAuthException extends DatabaseAuthException {
  UnauthorizedDatabaseAuthException(super.message);

  @override
  String toString() => 'UnauthorizedDatabaseAuthException($message)';
}

class DatabaseAuthException implements Exception {
  final String message;

  DatabaseAuthException(this.message);

  @override
  String toString() => 'DatabaseAuthException($message)';
}

Future databaseGetRecord({
  required String idToken,
  required String? database,
  required String path,
  Future<String> Function(Uri)? httpGet,
}) async {
  httpGet ??= (Uri uri) async {
    var client = Client();
    var response = await client.get(uri);
    if (response.statusCode != 200) {
      throw UnauthorizedDatabaseAuthException(
        '${response.statusCode}: ${response.body}',
      );
    }
    return response.body;
  };
  var text = await httpGet(
    Uri.parse(
      'https://$database.firebaseio.com/$path.json?access_token=$idToken',
    ),
  );
  print(text);
}
