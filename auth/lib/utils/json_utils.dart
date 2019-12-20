import 'package:tekartik_firebase_auth/auth.dart';

Map<String, dynamic> userRecordToJson(UserRecord userRecord) {
  if (userRecord != null) {
    var map = <String, dynamic>{};
    if (userRecord.uid != null) {
      map['uid'] = userRecord.uid;
    }
    if (userRecord.displayName != null) {
      map['displayName'] = userRecord.displayName;
    }
    if (userRecord.email != null) {
      map['email'] = userRecord.email;
    }
    if (userRecord.emailVerified != null) {
      map['emailVerified'] = userRecord.emailVerified;
    }
    if (userRecord.disabled != null) {
      map['disabled'] = userRecord.disabled;
    }
    return map;
  }
  return null;
}
