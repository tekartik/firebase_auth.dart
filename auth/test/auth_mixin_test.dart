import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth/src/auth.dart';
import 'package:tekartik_firebase_auth/src/auth_mixin.dart';
import 'package:test/test.dart';

class AuthMock with AuthMixin {
//  @override
//  Future<ListUsersResult> listUsers({int maxResults, String pageToken}) async =>
//      null;

}

class UserInfoMock implements UserInfo {
  @override
  final String displayName;

  UserInfoMock({this.displayName});

  @override
  String get email => null;

  @override
  String get phoneNumber => null;

  @override
  String get photoURL => null;

  @override
  String get providerId => null;

  @override
  String get uid => null;
}

void main() {
  group('auth_mixin', () {
    test('onCurrentUserNonNull', () async {
      var mock = AuthMock();
      var userInfo = UserInfoMock();
      mock.currentUserAdd(userInfo);
      /*
      // expect(mock.onCurrentUser, emitsInOrder([userInfo]));
      expect(await mock.onCurrentUser.first, userInfo);
      await mock.close(null);
      */
      expect(mock.onCurrentUser, emitsInOrder([userInfo]));
      await mock.close(null);
    });

    test('onCurrentUserNull', () async {
      var mock = AuthMock();
      mock.currentUserAdd(null);
      expect(mock.onCurrentUser, emitsInOrder([null]));
      await mock.close(null);
    });
    test('onCurrentUserNull2', () async {
      var mock = AuthMock();
      mock.onCurrentUser.listen((userInfo) {
        print(userInfo);
      });
      var future = expectLater(mock.onCurrentUser, emitsInOrder([null]));
      mock.currentUserAdd(null);
      //await Future.delayed(Duration(milliseconds: 5));
      await future;
      await mock.close(null);
    });
  });
}
