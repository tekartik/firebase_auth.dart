import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth/utils/json_utils.dart';
import 'package:test/test.dart';

class UserRecordMock implements UserRecord {
  @override
  dynamic get customClaims => null;

  @override
  late bool disabled;

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
  String uid = 'uid1';
}

void main() {
  group('utils', () {
    test('userRecordToJson', () {
      expect(userRecordToJson(UserRecordMock()), {});
      var record = UserRecordMock()
        ..displayName = 'alex'
        ..email = 'alex@alex.com'
        ..emailVerified = true
        ..uid = '1234'
        ..disabled = false;

      expect(userRecordToJson(record), {
        'uid': '1234',
        'displayName': 'alex',
        'email': 'alex@alex.com',
        'emailVerified': true,
        'disabled': false
      });
    });
  });
}
