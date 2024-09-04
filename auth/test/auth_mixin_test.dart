// ignore_for_file: avoid_print

import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth/src/auth.dart';
import 'package:tekartik_firebase_auth/src/auth_mixin.dart';
import 'package:test/test.dart';

class FirebaseAuthMock
    with FirebaseAppProductMixin<FirebaseAuth>, FirebaseAuthMixin {
  @override
  Future<User> reloadCurrentUser() {
    throw UnimplementedError();
  }

  @override
  void dispose() {
    currentUserClose();
    super.dispose();
  }

  @override
  FirebaseApp get app => throw UnimplementedError();

  @override
  FirebaseAuthService get service => throw UnimplementedError();
}

class UserInfoMock implements UserInfo {
  @override
  final String? displayName;

  UserInfoMock({this.displayName});

  @override
  String? get email => null;

  @override
  String? get phoneNumber => null;

  @override
  String? get photoURL => null;

  @override
  String? get providerId => null;

  @override
  String get uid => 'uid1';
}

class UserMock extends UserInfoMock implements User {
  @override
  bool get emailVerified => false;

  @override
  bool get isAnonymous => false;
}

void main() {
  group('auth_mixin', () {
    test('onCurrentUserNonNull', () async {
      var mock = FirebaseAuthMock();
      var userInfo = UserMock();
      mock.currentUserAdd(userInfo);
      /*
      // expect(mock.onCurrentUser, emitsInOrder([userInfo]));
      expect(await mock.onCurrentUser.first, userInfo);
      await mock.close(null);
      */
      expect(mock.onCurrentUser, emitsInOrder([userInfo]));
      mock.dispose();
    });

    test('onCurrentUserNull', () async {
      var mock = FirebaseAuthMock();
      mock.currentUserAdd(null);
      expect(mock.onCurrentUser, emitsInOrder([null]));
      mock.dispose();
    });
    test('onCurrentUserNull2', () async {
      var mock = FirebaseAuthMock();
      mock.onCurrentUser.listen((userInfo) {
        print(userInfo);
      });
      var future = expectLater(mock.onCurrentUser, emitsInOrder([null]));
      mock.currentUserAdd(null);
      //await Future.delayed(Duration(milliseconds: 5));
      await future;
      mock.dispose();
    });
  });
}
