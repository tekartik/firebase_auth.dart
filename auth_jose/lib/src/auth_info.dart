//import 'package:corsac_jwt/corsac_jwt.dart';
import 'package:http/http.dart';
import 'package:jose/jose.dart';

import 'import.dart';

abstract class FirebaseAuthException {}

class FirebaseAuthValidationException implements FirebaseAuthException {
  final String message;

  FirebaseAuthValidationException(this.message);

  @override
  String toString() => 'FirebaseAuthValidationException($message)';
}

class FirebaseAuthInfoHeader {
  /// alg	Algorithm	"RS256"
  final String alg;

  /// kid	Key ID	Must correspond to one of the public keys listed at
  /// https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com
  final String kid;

  FirebaseAuthInfoHeader({this.alg, this.kid});

  @override
  String toString() => toDebugMap().toString();

  Map toDebugMap() {
    return {'alg': alg, 'kid': kid};
  }
}

class FirebaseAuthInfoPayload {
  /*
  ID Token Payload Claims
exp	Expiration time	Must be in the future. The time is measured in seconds since the UNIX epoch.
iat	Issued-at time	Must be in the past. The time is measured in seconds since the UNIX epoch.
auth_time	Authentication time	Must be in the past. The time when
   */

  /// exp	Expiration time	Must be in the future. The time is measured in seconds since the UNIX epoch.
  final int exp;

  /// iat	Issued-at time	Must be in the past. The time is measured in seconds since the UNIX epoch.
  final int iat;

  /// aud	Audience	Must be your Firebase project ID, the unique identifier for your Firebase project, which can be found in the URL of that project's console.
  final String aud;

  /// iss	Issuer	Must be "https://securetoken.google.com/<projectId>", where <projectId> is the same project ID used for aud above.
  final String iss;

  final int authTime;

  /// sub	Subject	Must be a non-empty string and must be the uid of the user or device.
  final String sub;

  /// Firebase user Id info
  final String userId;

  /// Firebase user name
  final String name;

  /// Firebase email
  final String email;

  /// Firebase email
  final String picture;

  /// Firebase email verified
  final bool emailVerified;

  /// Firebase project Id info
  String get projectId => aud;

  FirebaseAuthInfoPayload({
    this.exp,
    this.iss,
    this.iat,
    this.userId,
    this.aud,
    this.sub,
    this.authTime,
    this.name,
    this.email,
    this.emailVerified,
    this.picture,
  });

  @override
  String toString() => toDebugMap().toString();

  String _timeToString(int time) => time == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(time * 1000)
          .toUtc()
          .toIso8601String();

  Map toDebugMap() {
    return {
      'exp': _timeToString(exp),
      'iat': _timeToString(iat),
      'aud': aud,
      'iss': iss,
      'sud': sub,
      'auth_time': _timeToString(authTime),
      'userId': userId,
      'email': email,
      'emailVerified': emailVerified,
      'picture': picture,
    };
  }
}

@visibleForTesting
bool debugFirebaseAuthInfo = false;

/// The decoded information
abstract class FirebaseAuthInfo {
  /// Decoded user name.
  String get name;

  /// Decoded userId.
  String get userId;

  /// Decoded email.
  String get email;

  /// Decoded email verified.
  bool get emailVerified;

  /// Decoded email verified.
  String get picture;

  /// Decoded projectId.
  String get projectId;

  Map toDebugMap();

  /// Validate using public key fetched
  Future<bool> verify(
      {DateTime currentTime, Future<String> Function(String keyId) fetchKey});

  factory FirebaseAuthInfo.fromIdToken(String idToken) =>
      FirebaseAuthInfoImpl.fromIdToken(idToken);
}

class JwtAuth {
  JsonWebToken _jwt;
  JsonWebSignature _jws;

  static JwtAuth fromIdToken(String idToken) {
    var auth = JwtAuth();
    auth._jwt = JsonWebToken.unverified(idToken);
    auth._jws = JsonWebSignature.fromCompactSerialization(idToken);
    return auth;
  }

  JwtAuthHeaders _headers;

  JwtAuthHeaders get headers => _headers ??= () {
        return JwtAuthHeaders(this);
      }();
  JwtAuthClaims _claims;

  JwtAuthClaims get claims => _claims ??= () {
        return JwtAuthClaims(this);
      }();
}

/// Unsupported
class JwtAuthHeaders {
  final JwtAuth _auth;

  JwtAuthHeaders(this._auth);

  Object operator [](String key) {
    switch (key) {
      case 'alg':
        return _auth._jws.recipients.first.header.algorithm;
      case 'kid':
        return _auth._jws.recipients.first.header.keyId;
    }
    return null;
  }
}

class JwtAuthClaims {
  final JwtAuth _auth;

  JwtAuthClaims(this._auth);

  Object operator [](String key) => _auth._jwt.claims[key];
}

class FirebaseAuthInfoImpl implements FirebaseAuthInfo {
  final String idToken;

  @override
  String get userId => payload.userId;

  //JwtAuth _jwt;

  FirebaseAuthInfoImpl.fromIdToken(String idToken) : idToken = idToken {
    var jwt = JwtAuth.fromIdToken(idToken);
    var headers = jwt.headers;
    var claims = jwt.claims;
    //devPrint(_jwt._jwt.claims):
    if (debugFirebaseAuthInfo) {
      print(jsonPretty(headers));
      print(jsonPretty(claims));
      // devPrint(jwt);
    }

    // Header
    {
      var alg = headers['alg'];
      var kid = headers['kid'];
      _header = FirebaseAuthInfoHeader(alg: alg, kid: kid);
    }

    // Claims
    {
      var iss = claims['iss'] as String;
      var iat = claims['iat'] as int;
      var userId = claims['user_id'] as String;
      var name = claims['name'] as String;
      var exp = claims['exp'] as int;
      var aud = claims['aud'] as String;
      var sub = claims['sub'] as String;
      var authTime = claims['auth_time'] as int;
      var email = claims['email'] as String;
      var emailVerified = claims['email_verified'] as bool;
      var picture = claims['picture'] as String;
      _payload = FirebaseAuthInfoPayload(
          iss: iss,
          iat: iat,
          userId: userId,
          exp: exp,
          authTime: authTime,
          sub: sub,
          aud: aud,
          name: name,
          email: email,
          emailVerified: emailVerified,
          picture: picture);
    }
  }

  Future<String> httpFetchKey(String key) async {
    var jsonContent = await read(Uri.parse(
        'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com'));
    var map = jsonDecode(jsonContent) as Map;
    return map[key];
  }

  /// Validate using public key fetched
  @override
  Future<bool> verify(
      {DateTime currentTime,
      Future<String> Function(String keyId) fetchKey}) async {
    fetchKey ??= httpFetchKey;
    if (header?.alg != 'RS256') {
      print('invalid jwt alg $header');
      return false;
    }

    /*
    try {
      var validator = JWTValidator();
      validator.validate(_jwt);
    } catch (e) {
      print('validator error $e');
      rethrow;
    }

     */

    var key = await fetchKey(header.kid);
/*
    key = key.replaceAll(
        '-----BEGIN CERTIFICATE-----', '-----BEGIN RSA PUBLIC KEY-----');
    key = key.replaceAll(
        '-----END CERTIFICATE-----', '-----END RSA PUBLIC KEY-----');
*/
    // -----BEGIN CERTIFICATE-----
    // static const String pkcs1PublicHeader = '-----BEGIN RSA PUBLIC KEY-----';
    // static const String pkcs1PublicFooter = '-----END RSA PUBLIC KEY-----';
    // devPrint('key: $key');
    //var jo = JsonWebEncryption.fromCompactSerialization(key);
    // Parse PEM encoded private key.
    //var keyData = PemCodec(PemLabel.privateKey).decode(key);

    //var codec = PemCodec(key);
    var jwk = JsonWebKey.fromPem(key);

    /*
    expect(key.keyType, 'EC');
    expect(key.cryptoKeyPair.publicKey, isA<EcPublicKey>());
    expect((key.cryptoKeyPair.publicKey as EcKey).curve, curves.p256);
    expect(key.cryptoKeyPair.privateKey, isA<EcPrivateKey>());
    expect((key.cryptoKeyPair.privateKey as EcKey).curve, curves.p256);

     */

    var keyStore = JsonWebKeyStore()..addKey(jwk);
    var jws = JsonWebSignature.fromCompactSerialization(idToken);
    //var signer = JWTRsaSha256Signer(publicKey: key);

    try {
      //var validator = JWTValidator(currentTime: currentTime);
      if (!await jws.verify(keyStore)) {
        throw FirebaseAuthValidationException('not verified');
      }
      // var errors = validator.validate(_jwt, signer: signer);
      //if (errors.isNotEmpty) {
      //  throw FirebaseAuthValidationException(errors.toString());
      //}
    } catch (e) {
      print('validator error $e');
      rethrow;
    }

    // Verify the ID token's header conforms to the following constraints:

    // ID Token Header Claims
    //alg	Algorithm	"RS256"
    // kid	Key ID	Must correspond to one of the public keys listed at https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com
    return true;
  }

  FirebaseAuthInfoHeader _header;

  FirebaseAuthInfoHeader get header => _header;
  FirebaseAuthInfoPayload _payload;

  FirebaseAuthInfoPayload get payload => _payload;

  @override
  Map toDebugMap() {
    return {'header': header.toDebugMap(), 'payload': payload.toDebugMap()};
  }

  @override
  String toString() => toDebugMap().toString();

  @override
  String get email => payload.email;

  @override
  bool get emailVerified => payload.emailVerified;

  @override
  String get picture => payload.picture;

  @override
  String get projectId => payload.projectId;

  @override
  String get name => payload.name;
}
/*
/*
token:

eyJhbGciOiJSUzI1NiIsImtpZCI6IjYwZjdkMTUxMzVlZjhiODY3YTMzYmUwYWM2ZTAxNTkyYTJiNmE2MmYifQ.eyJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vdGVrYXJ0aWstZGV2IiwibmFtZSI6IkFsZXhhbmRyZSBSb3V4IEAgVGVrYXJ0aWsiLCJwaWN0dXJlIjoiaHR0cHM6Ly9saDQuZ29vZ2xldXNlcmNvbnRlbnQuY29tLy1OcmtNV3RCWGp2by9BQUFBQUFBQUFBSS9BQUFBQUFBQUFIWS9PcThyRXdJNXUtYy9zOTYtYy9waG90by5qcGciLCJhdWQiOiJ0ZWthcnRpay1kZXYiLCJhdXRoX3RpbWUiOjE0NzEzNjA4NTUsInVzZXJfaWQiOiJKVWg2NzZUMENLaE1meTMyS01QanoyRnhhMUEzIiwic3ViIjoiSlVoNjc2VDBDS2hNZnkzMktNUGp6MkZ4YTFBMyIsImlhdCI6MTQ3MTM2NjQwMSwiZXhwIjoxNDcxMzcwMDAxLCJlbWFpbCI6ImFsZXhAdGVrYXJ0aWsuY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsImZpcmViYXNlIjp7ImlkZW50aXRpZXMiOnsiZ29vZ2xlLmNvbSI6WyIxMDYwNDkzODI0NjUyNjcwMTIzNDQiXSwiZW1haWwiOlsiYWxleEB0ZWthcnRpay5jb20iXX0sInNpZ25faW5fcHJvdmlkZXIiOiJnb29nbGUuY29tIn19.bjT_5kWMuUtub7DCrUkIigpiJM0FVzv9iaQlqOnlRomMocbdqhTnQTbqleaWEmDBu1JRXoQkCzTRQ2OSXcdpbBDzHs1sag0fPw0FcGFF7oIZx2Ks5Xg8YlXFWYryXnaa_I9vVxDmocVadDV5ZOqcwL9NznkldAT6OtIFpbSC8zpWg4jbFTudLH-4D9oAKP8o6vA2UwSnxfOAYzu8iu61HVnUsyqso0IDqhl-D6r7ehl0dGTOGTVXnLL6iY2CRvkLzNdqY_9tVVolCLvr_3znyoBc4YdoC_R1hgwx0DHHKScgHDlPiXWEzJZ7XB1viLbWOEbTI5yzk5L5LLD4U0sk-w

header:

{
  "alg": "RS256",
  "kid": "60f7d15135ef8b867a33be0ac6e01592a2b6a62f"
}


payload

{
  "iss": "https://securetoken.google.com/tekartik-dev",
  "name": "Alexandre Roux @ Tekartik",
  "picture": "https://lh4.googleusercontent.com/-NrkMWtBXjvo/AAAAAAAAAAI/AAAAAAAAAHY/Oq8rEwI5u-c/s96-c/photo.jpg",
  "aud": "tekartik-dev",
  "auth_time": 1471360855,
  "user_id": "JUh676T0CKhMfy32KMPjz2Fxa1A3",
  "sub": "JUh676T0CKhMfy32KMPjz2Fxa1A3",
  "iat": 1471366401,
  "exp": 1471370001,
  "email": "alex@tekartik.com",
  "email_verified": true,
  "firebase": {
    "identities": {
      "google.com": [
        "106049382465267012344"
      ],
      "email": [
        "alex@tekartik.com"
      ]
    },
    "sign_in_provider": "google.com"
  }
}
 */
 */
