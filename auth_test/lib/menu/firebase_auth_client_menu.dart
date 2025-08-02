import 'package:tekartik_app_dev_menu/dev_menu.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_auth/auth.dart';

export 'package:tekartik_app_dev_menu/dev_menu.dart';
export 'package:tekartik_firebase_auth/auth.dart';

/// Top doc context
class FirebaseAuthMainMenuContext {
  final FirebaseAuth auth;

  FirebaseAuthMainMenuContext({required this.auth});
}

void firebaseAuthMainMenu({required FirebaseAuthMainMenuContext context}) {
  var auth = context.auth;
  StreamSubscription? subscription;
  menu('signIn', () {
    item('current user', () async {
      write('current user: ${auth.currentUser}');
    });
    item('register on current user', () async {
      subscription?.cancel().unawait();
      subscription = auth.onCurrentUser.listen((user) {
        write('onUser: $user');
      });
    });
    item('cancel on current user', () {
      subscription?.cancel();
      subscription = null;
    });
    item('signIn anymomously', () async {
      var credentials = await auth.signInAnonymously();
      write('credentials: $credentials');
    });
    item('signOut', () async {
      await auth.signOut();
    });
  });
}
