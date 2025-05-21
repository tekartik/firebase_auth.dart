import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth/utils/json_utils.dart';
import 'package:test/test.dart';

class UserRecordMock implements UserRecord {
  UserRecordMock({required this.uid});

  @override
  dynamic get customClaims => null;

  @override
  final bool disabled = false;

  @override
  String? displayName;

  @override
  String? email;

  @override
  bool emailVerified = false;

  @override
  UserMetadata? get metadata => null;

  @override
  String? get passwordHash => null;

  @override
  String? get passwordSalt => null;

  @override
  String? get phoneNumber => null;

  @override
  String? get photoURL => null;

  @override
  List<UserInfo>? get providerData => null;

  @override
  String? get tokensValidAfterTime => null;

  @override
  final String uid;
}

void main() {
  group('utils', () {
    test('userRecordToJson', () {
      expect(userRecordToJson(UserRecordMock(uid: '1')), {'uid': '1'});
      var record =
          UserRecordMock(uid: '1234')
            ..displayName = 'alex'
            ..email = 'alex@alex.com'
            ..emailVerified = true;

      expect(userRecordToJson(record), {
        'uid': '1234',
        'displayName': 'alex',
        'email': 'alex@alex.com',
        'emailVerified': true,
      });
    });
  });
}
