import 'package:corsac_jwt/corsac_jwt.dart';
import 'package:tekartik_firebase_auth_jwt/auth_jwt.dart';
import 'package:tekartik_firebase_auth_jwt/src/auth_info.dart';
import 'package:tekartik_firebase_auth_jwt/src/database.dart';
import 'package:tekartik_firebase_auth_jwt/src/import.dart';
import 'package:test/test.dart';

void main() {
  // debugFirebaseAuthInfo = true;

  group('decode', () {
    // {
    //  'alg': 'RS256',
    //  'kid': '88848b5aff2d5201331a547d1906e5aadf6513c8',
    //  'typ': 'JWT'
    //}
    //{
    //  'name': 'Test Tekartik',
    //  'picture': 'https://lh3.googleusercontent.com/-GlXO6JJAgiI/AAAAAAAAAAI/AAAAAAAAAAA/ACevoQN11E8L_4YI8-lu16tYmWfgT90Usw/mo/photo.jpg',
    //  'iss': 'https://securetoken.google.com/tekartik-free-dev',
    //  'aud': 'tekartik-free-dev',
    //  'auth_time': 1588489534,
    //  'user_id': 'Ac8ExOw1kIZZWv7ZZyK1eIVw0Mu2',
    //  'sub': 'Ac8ExOw1kIZZWv7ZZyK1eIVw0Mu2',
    //  'iat': 1588489534,
    //  'exp': 1588493134,
    //  'email': 'tekatest@tekartik.fr',
    //  'email_verified': true,
    //  'firebase': {
    //    'identities': {
    //      'google.com': [
    //        '111030387215071100877'
    //      ],
    //      'email': [
    //        'tekatest@tekartik.fr'
    //      ]
    //    },
    //    'sign_in_provider': 'google.com'
    //  }
    //}
    test('simple', () async {
      var idToken =
          'eyJhbGciOiJSUzI1NiIsImtpZCI6Ijg4ODQ4YjVhZmYyZDUyMDEzMzFhNTQ3ZDE5MDZlNWFhZGY2NTEzYzgiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoiVGVzdCBUZWthcnRpayIsInBpY3R1cmUiOiJodHRwczovL2xoMy5nb29nbGV1c2VyY29udGVudC5jb20vLUdsWE82SkpBZ2lJL0FBQUFBQUFBQUFJL0FBQUFBQUFBQUFBL0FDZXZvUU4xMUU4TF80WUk4LWx1MTZ0WW1XZmdUOTBVc3cvbW8vcGhvdG8uanBnIiwiaXNzIjoiaHR0cHM6Ly9zZWN1cmV0b2tlbi5nb29nbGUuY29tL3Rla2FydGlrLWZyZWUtZGV2IiwiYXVkIjoidGVrYXJ0aWstZnJlZS1kZXYiLCJhdXRoX3RpbWUiOjE1ODg0ODk1MzQsInVzZXJfaWQiOiJBYzhFeE93MWtJWlpXdjdaWnlLMWVJVncwTXUyIiwic3ViIjoiQWM4RXhPdzFrSVpaV3Y3Wlp5SzFlSVZ3ME11MiIsImlhdCI6MTU4ODQ4OTUzNCwiZXhwIjoxNTg4NDkzMTM0LCJlbWFpbCI6InRla2F0ZXN0QHRla2FydGlrLmZyIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsImZpcmViYXNlIjp7ImlkZW50aXRpZXMiOnsiZ29vZ2xlLmNvbSI6WyIxMTEwMzAzODcyMTUwNzExMDA4NzciXSwiZW1haWwiOlsidGVrYXRlc3RAdGVrYXJ0aWsuZnIiXX0sInNpZ25faW5fcHJvdmlkZXIiOiJnb29nbGUuY29tIn19.O_w31LzfSYOGDTDYxskrGGN2LiBQLfZ5Zhn5JAgYYGdElZ8_hgVOyEwvBELmf4p9zEHDfzghMRvxfOGnYmGFouLhme3tvAVZKWlvOKSwCxPCI-MIGE_PGJTDWABcE5WbCcTb-oHXaiKVdJe3xjeTitlnRvF7aXLmqfX_nHWx-Kqc6RhXKiRbftOYDT3oI6buvEPq7B2gF58e9HGQ0ImLivRkYFrG6V_YWP35hH84V80DQLIbO5pzbA8dEFb-V1iKHufTuHAOxNE1rwuUN1SPqG4TrJ095I9u4FIokMm-uZUDTyxNLm6qjyS-r1UazqxsPhuFoNzQmKiby5tdST00IQ';
      var jwt = FirebaseAuthInfo.fromIdToken(idToken) as FirebaseAuthInfoImpl;

      print(jsonPretty(jwt.toDebugMap()));
      expect(jwt.header.alg, 'RS256');
      expect(jwt.header.kid, '88848b5aff2d5201331a547d1906e5aadf6513c8');
      expect(jwt.payload.userId, 'Ac8ExOw1kIZZWv7ZZyK1eIVw0Mu2');
      expect(jwt.payload.userId, jwt.payload.sub);
      expect(jwt.payload.email, 'tekatest@tekartik.fr');
      expect(jwt.payload.emailVerified, true);
      expect(jwt.payload.projectId, 'tekartik-free-dev');

      var database = jwt.payload.projectId;
      var userId = jwt.payload.userId;
      try {
        await databaseGetRecord(
            idToken: idToken,
            database: database,
            path: '_check_user_access/$userId');
        fail('should fail');
      } on UnauthorizedDatabaseAuthException catch (_) {
        // UnauthorizedDatabaseAuthException(401: {
        // "error" : "Unauthorized request."
        // }
      }
    });
  });
}
