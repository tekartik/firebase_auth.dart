import 'package:tekartik_firebase_auth/auth.dart';

/// Convert a user record to json
Map<String, dynamic> userRecordToJson(UserRecord userRecord) {
  var map = <String, Object?>{'uid': userRecord.uid};

  if (userRecord.displayName != null) {
    map['displayName'] = userRecord.displayName;
  }
  if (userRecord.email != null) {
    map['email'] = userRecord.email;
  }
  if (userRecord.emailVerified) {
    map['emailVerified'] = userRecord.emailVerified;
  }
  if (userRecord.disabled) {
    map['disabled'] = userRecord.disabled;
  }
  return map;
}
