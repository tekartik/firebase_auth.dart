import 'dart:async';
import 'package:firebase_admin_interop/firebase_admin_interop.dart' as node;
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_node/src/firebase_node.dart';
import 'package:tekartik_firebase_auth/src/auth.dart';

class AuthServiceNode implements AuthService {
  @override
  bool get supportsListUsers => true;

  @override
  Auth auth(App app) {
    assert(app is AppNode, 'invalid firebase app type');
    AppNode appNode = app;
    return AuthNode(appNode.nativeInstance.auth());
  }

  @override
  bool get supportsCurrentUser => false;
}

AuthServiceNode _authServiceNode;

AuthServiceNode get authServiceNode => _authServiceNode ??= AuthServiceNode();

AuthService get authService => authServiceNode;

class ListUsersResultNode implements ListUsersResult {
  final node.ListUsersResult nativeInstance;

  ListUsersResultNode(this.nativeInstance);

  @override
  String get pageToken => nativeInstance.pageToken;

  @override
  List<UserRecord> get users => nativeInstance.users
      ?.cast<node.UserRecord>()
      ?.map(wrapUserRecord)
      ?.toList(growable: false);
}

class UserMetadataNode implements UserMetadata {
  final node.UserMetadata nativeInstance;

  UserMetadataNode(this.nativeInstance);

  @override
  String get creationTime => nativeInstance.creationTime;

  @override
  String get lastSignInTime => nativeInstance.creationTime;
}

class UserInfoNode implements UserInfo {
  final node.UserInfo nativeInstance;

  UserInfoNode(this.nativeInstance);

  @override
  String get displayName => nativeInstance.displayName;

  @override
  String get email => nativeInstance.email;

  @override
  String get phoneNumber => nativeInstance.phoneNumber;

  @override
  String get photoURL => nativeInstance.photoURL;

  @override
  String get providerId => nativeInstance.providerId;

  @override
  String get uid => nativeInstance.uid;
}

class UserRecordNode implements UserRecord {
  final node.UserRecord nativeInstance;

  UserRecordNode(this.nativeInstance);

  @override
  get customClaims => nativeInstance.customClaims;

  @override
  bool get disabled => nativeInstance.disabled;

  @override
  String get displayName => nativeInstance.displayName;

  @override
  String get email => nativeInstance.email;

  @override
  bool get emailVerified => nativeInstance.emailVerified;

  @override
  UserMetadata get metadata => wrapUserMetadata(nativeInstance.metadata);

  @override
  String get passwordHash => nativeInstance.passwordHash;

  @override
  String get passwordSalt => nativeInstance.passwordSalt;

  @override
  String get phoneNumber => nativeInstance.phoneNumber;

  @override
  String get photoURL => nativeInstance.photoURL;

  @override
  List<UserInfo> get providerData => nativeInstance.providerData
      ?.cast<node.UserInfo>()
      ?.map((nativeUserInfo) => wrapUserInfo(nativeUserInfo))
      ?.toList(growable: false);

  @override
  String get tokensValidAfterTime => nativeInstance.tokensValidAfterTime;

  @override
  String get uid => nativeInstance.uid;
}

ListUsersResult wrapListUsersResult(
        node.ListUsersResult nativeListUsersResult) =>
    nativeListUsersResult != null
        ? ListUsersResultNode(nativeListUsersResult)
        : null;

UserInfo wrapUserInfo(node.UserInfo nativeUserInfo) =>
    nativeUserInfo != null ? UserInfoNode(nativeUserInfo) : null;

UserRecord wrapUserRecord(node.UserRecord nativeUserRecord) =>
    nativeUserRecord != null ? UserRecordNode(nativeUserRecord) : null;

UserMetadata wrapUserMetadata(node.UserMetadata nativeUserMetadata) =>
    nativeUserMetadata != null ? UserMetadataNode(nativeUserMetadata) : null;

class AuthNode implements Auth {
  final node.Auth nativeInstance;

  AuthNode(this.nativeInstance);

  /// Retrieves a list of users (single batch only) with a size of [maxResults]
  /// and starting from the offset as specified by [pageToken].
  ///
  /// This is used to retrieve all the users of a specified project in batches.
  Future<ListUsersResult> listUsers({int maxResults, String pageToken}) async {
    return wrapListUsersResult(
        await nativeInstance.listUsers(maxResults, pageToken));
  }

  @override
  UserInfo get currentUser =>
      throw UnsupportedError('currentUser not supported for node');

  @override
  Stream<UserInfo> get onCurrentUserChanged =>
      throw UnsupportedError('onCurrentUserChanged not supported for node');
}

AuthNode auth(node.Auth _impl) => _impl != null ? AuthNode(_impl) : null;
