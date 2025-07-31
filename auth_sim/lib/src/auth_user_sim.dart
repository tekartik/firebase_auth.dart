import 'package:tekartik_firebase_auth/auth_mixin.dart';

import 'auth_sim_message.dart';

/// User record sim
class UserRecordSim with FirebaseUserRecordDefaultMixin {
  /// User response
  final UserGetResponse userResponse;

  /// Constructor
  UserRecordSim({required this.userResponse});
  @override
  String? get email => userResponse.email.v;

  @override
  String get uid => userResponse.userId.v!;
  @override
  bool get emailVerified => userResponse.emailVerified.v ?? false;
  @override
  bool get isAnonymous => userResponse.anonymous.v ?? false;

  @override
  String? get displayName => userResponse.name.v;
}

/// User Sembast
class FirebaseUserSim with FirebaseUserMixin {
  /// record
  final UserRecordSim userRecordSim;
  @override
  String get uid => userRecordSim.uid;

  @override
  String? get email => userRecordSim.email;

  @override
  bool get isAnonymous => userRecordSim.isAnonymous;

  @override
  bool get emailVerified => userRecordSim.emailVerified;
  @override
  String? get displayName => userRecordSim.displayName;

  /// Constructor
  FirebaseUserSim(this.userRecordSim);
}

/// User credential sim
class UserCredentialSim with FirebaseUserCredentialMixin {
  /// Record
  final UserRecordSim userRecordSim;

  @override
  late final user = FirebaseUserSim(userRecordSim);

  /// Constructor
  UserCredentialSim(this.userRecordSim);

  @override
  late final credential = FirebaseAuthCredentialSim();
}

/// Auth credential sim
class FirebaseAuthCredentialSim implements FirebaseAuthCredential {
  @override
  String get providerId => 'sim';

  @override
  String toString() => 'AuthCredential(provider: $providerId)';
}
