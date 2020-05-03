import 'package:corsac_jwt/corsac_jwt.dart';
import 'package:tekartik_firebase_auth_jwt/auth_jwt.dart';

import 'package:test/test.dart';

void main() {
  debugFirebaseAuthInfo = true;

  var keys20201009 = {
    '88848b5aff2d5201331a547d1906e5aadf6513c8':
        '-----BEGIN CERTIFICATE-----\nMIIDHDCCAgSgAwIBAgIIA/oH1w0GNmMwDQYJKoZIhvcNAQEFBQAwMTEvMC0GA1UE\nAxMmc2VjdXJldG9rZW4uc3lzdGVtLmdzZXJ2aWNlYWNjb3VudC5jb20wHhcNMjAw\nNDI3MDkxOTU2WhcNMjAwNTEzMjEzNDU2WjAxMS8wLQYDVQQDEyZzZWN1cmV0b2tl\nbi5zeXN0ZW0uZ3NlcnZpY2VhY2NvdW50LmNvbTCCASIwDQYJKoZIhvcNAQEBBQAD\nggEPADCCAQoCggEBAJ0JeaPobguFV56+uzblHTomAFVcixD2fyERU4x618fxuTRq\nEBCZErH3SeUIR0KH8KIbjBYcF8DVZLF0xWSAIhVCbcp1t+53ICri4uWrh6VI0vvl\nsj0u5zB1r26UYfbAv3vyV8ImbfjFra2JUnWs+zzf102X2cD0CiFnG5qXWQnEoGdg\nY0GbAH+AMjH4Pt9W+aohZ+LpZXjakjPaqF1x61pTy0ApHOrHnprzDxd13jIansoj\nHO4fphkxBJiiXBaCuWrexrLdPJZiYtyuimuMtVBTPnIfFJye8uMB8zV0F6STeSYg\nYDmWcAbyRViyivcoyxQZh/A1WdEV9VmhpltqaZ0CAwEAAaM4MDYwDAYDVR0TAQH/\nBAIwADAOBgNVHQ8BAf8EBAMCB4AwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwIwDQYJ\nKoZIhvcNAQEFBQADggEBABnHr4qQhoXG9T93ChoyhKvY8dFEe0FPUcUT6zaJxR4F\nuXahQtUEIzXdLZ9ADStMMePNJRj8kAEvwPIyioKppV/AF6Y/Ea8XHm7KNvY+c8FA\nI7lBbfg9azJcrtZGQsSbTuowTQZX1R1jBq1FWZ/bxwn6vnIU75LaYBk5lB2HbwCL\ny4RmHAX73BLPtVnmR3WdI6eUbSt4IPI4FzpLGonwI50vi2bnCTI22OkVtucr8nAh\noXEG+FPAiStqwMaHr8v2I68dAgNk97aQWVULrxZm/LjFh4A+FLK6FpGgITLpbp+I\nzlhFewXrAFp8Up6U3Sch6SCXrtEjDfkyhHbb/j+RtYI=\n-----END CERTIFICATE-----\n',
    '5e9ee97c840f97e0253688a3b7e94473e528a7b5':
        '-----BEGIN CERTIFICATE-----\nMIIDHDCCAgSgAwIBAgIIZC7uPq+FdkIwDQYJKoZIhvcNAQEFBQAwMTEvMC0GA1UE\nAxMmc2VjdXJldG9rZW4uc3lzdGVtLmdzZXJ2aWNlYWNjb3VudC5jb20wHhcNMjAw\nNDE5MDkxOTU2WhcNMjAwNTA1MjEzNDU2WjAxMS8wLQYDVQQDEyZzZWN1cmV0b2tl\nbi5zeXN0ZW0uZ3NlcnZpY2VhY2NvdW50LmNvbTCCASIwDQYJKoZIhvcNAQEBBQAD\nggEPADCCAQoCggEBAN4QmiJxlOTvbw/wwJPYISofcxRXb/I4+K8noG7fFhim+RxU\n/f84uYyDssopXt6jiUGeBKMvm65fi108EfGZXCYPZVBX1dgkddRkgNA2afhvrgdF\n7BG9U1e1SPlcovJH4upn5bQb0kOr7yTg6LfihA30kgZ3RyekrSx4VJP+UNb38f+J\ntOhiROEwUOS/0J35+8jZtO5FqVfp/hxfGLMdsi+l7kA65ogW/4uQCaD8V54Ncf6D\nn0qX3qW3ze2kO1W4NDmOhLhpef8nBORs1Mt7dvKxK3QNMJQwtqqO1wQC4oKzvhNY\neNsfw+nFiDtAyUFwZOVbYP2Vsp3p3oYu1impJu0CAwEAAaM4MDYwDAYDVR0TAQH/\nBAIwADAOBgNVHQ8BAf8EBAMCB4AwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwIwDQYJ\nKoZIhvcNAQEFBQADggEBAE7NhWSHuaikAo6EVt7Q4F+eOCAywQbGJgVE/xdK8AA+\nmEbU6Ybi8wc4yCE2QW2NYMH822MPiuiTKgBRPdOPQa1YrOfmvLQt0ZHGADl/d2U8\ny0wPZJWjCWHRkufPOMr2EFhwlA5Pj1mBTKn9PZAQf9rWiJuYhkb4jm6hsABmL0HY\ngGZkLcXsnzIWfNj0IXU7YRbY7ko5NoqfXe3aOoNIysgF59wInPUPnYyKZjrRS0Jj\nU93x28x7EC2clk59tRylyoJnRDbs4WbLMpzS8Fq6APa0ukHRV9cimjqmQbEJ5v6y\nTBtNG1gPXsUJQldCKMYWmXh0hAdq+ZjcRVZnOngS35Q=\n-----END CERTIFICATE-----\n'
  };

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
      var jwt = FirebaseAuthInfo.fromIdToken(
          'eyJhbGciOiJSUzI1NiIsImtpZCI6Ijg4ODQ4YjVhZmYyZDUyMDEzMzFhNTQ3ZDE5MDZlNWFhZGY2NTEzYzgiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoiVGVzdCBUZWthcnRpayIsInBpY3R1cmUiOiJodHRwczovL2xoMy5nb29nbGV1c2VyY29udGVudC5jb20vLUdsWE82SkpBZ2lJL0FBQUFBQUFBQUFJL0FBQUFBQUFBQUFBL0FDZXZvUU4xMUU4TF80WUk4LWx1MTZ0WW1XZmdUOTBVc3cvbW8vcGhvdG8uanBnIiwiaXNzIjoiaHR0cHM6Ly9zZWN1cmV0b2tlbi5nb29nbGUuY29tL3Rla2FydGlrLWZyZWUtZGV2IiwiYXVkIjoidGVrYXJ0aWstZnJlZS1kZXYiLCJhdXRoX3RpbWUiOjE1ODg0ODk1MzQsInVzZXJfaWQiOiJBYzhFeE93MWtJWlpXdjdaWnlLMWVJVncwTXUyIiwic3ViIjoiQWM4RXhPdzFrSVpaV3Y3Wlp5SzFlSVZ3ME11MiIsImlhdCI6MTU4ODQ4OTUzNCwiZXhwIjoxNTg4NDkzMTM0LCJlbWFpbCI6InRla2F0ZXN0QHRla2FydGlrLmZyIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsImZpcmViYXNlIjp7ImlkZW50aXRpZXMiOnsiZ29vZ2xlLmNvbSI6WyIxMTEwMzAzODcyMTUwNzExMDA4NzciXSwiZW1haWwiOlsidGVrYXRlc3RAdGVrYXJ0aWsuZnIiXX0sInNpZ25faW5fcHJvdmlkZXIiOiJnb29nbGUuY29tIn19.O_w31LzfSYOGDTDYxskrGGN2LiBQLfZ5Zhn5JAgYYGdElZ8_hgVOyEwvBELmf4p9zEHDfzghMRvxfOGnYmGFouLhme3tvAVZKWlvOKSwCxPCI-MIGE_PGJTDWABcE5WbCcTb-oHXaiKVdJe3xjeTitlnRvF7aXLmqfX_nHWx-Kqc6RhXKiRbftOYDT3oI6buvEPq7B2gF58e9HGQ0ImLivRkYFrG6V_YWP35hH84V80DQLIbO5pzbA8dEFb-V1iKHufTuHAOxNE1rwuUN1SPqG4TrJ095I9u4FIokMm-uZUDTyxNLm6qjyS-r1UazqxsPhuFoNzQmKiby5tdST00IQ');

      // devPrint(jsonPretty(jwt.toDebugMap()));
      expect(jwt.header.alg, 'RS256');
      expect(jwt.header.kid, '88848b5aff2d5201331a547d1906e5aadf6513c8');
      expect(jwt.payload.userId, 'Ac8ExOw1kIZZWv7ZZyK1eIVw0Mu2');
      expect(jwt.payload.userId, jwt.payload.sub);
      expect(jwt.payload.email, 'tekatest@tekartik.fr');
      expect(jwt.payload.emailVerified, true);

      try {
        await jwt.verify(fetchKey: (key) async => keys20201009[key]);
      } catch (e) {
        print('Failing $e');
      }
    });

    test('simple non firebase', () {
      try {
        FirebaseAuthInfo.fromIdToken(
            'ya29.c.Ko8ByQe8ZMgj4lTOXj0NnrbKiZQR2nnkuglmzefV5rWR3Rl7lvHtHLqMoTcjkqucCnKywiZs20qWvWQRjGAkDMv_oRJ8RejwPXvV3GiYHC2E600i8Nkv3QsP7IahUp06w0EZlYEPyboluecKhBIw0h5HAyJxJ4L5E3JxkdE3LjFsR-Ej-LK3D1JErBiaK3IPplU');
        fail('should fail');
      } on JWTError catch (_) {}
    });
  });
}
