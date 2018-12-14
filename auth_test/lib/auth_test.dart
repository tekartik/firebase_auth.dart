import 'package:meta/meta.dart';
import 'package:tekartik_firebase/firebase.dart' as fb;
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth/utils/json_utils.dart';
import 'package:test/test.dart';

bool skipConcurrentTransactionTests = false;

void run(
    {@required fb.Firebase firebase,
    @required AuthService authService,
      fb.AppOptions options}) {
  fb.App app = firebase.initializeApp(options: options);

  tearDownAll(() {
    return app.delete();
  });

  var auth = authService.auth(app);
  runApp(authService: authService, auth: auth);
}

runApp(
    {@required AuthService authService,
    @required Auth auth}) {
  setUpAll(() async {
  });
  group('auth', ()
  {
    group('listUsers', () {
      test('one', () async {
        var user = (await auth.listUsers(maxResults: 1)).users?.first;
        print(userRecordToJson(user));
      });
    }, skip: !authService.supportsListUsers);
  });
}
