import 'package:corsac_jwt/corsac_jwt.dart';

import 'import.dart';

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

  /// Firebase email
  final String email;

  /// Firebase email verified
  final bool emailVerified;

  /// Firebase project Id info
  String get projectId => sub;

  FirebaseAuthInfoPayload({
    this.exp,
    this.iss,
    this.iat,
    this.userId,
    this.aud,
    this.sub,
    this.authTime,
    this.email,
    this.emailVerified,
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
      'emailVerified': emailVerified
    };
  }
}

@visibleForTesting
bool debugFirebaseAuthInfo = false;

class FirebaseAuthInfo {
  JWT _jwt;
  FirebaseAuthInfo.fromIdToken(String idToken) {
    var jwt = _jwt = JWT.parse(idToken);
    var headers = jwt.headers;
    var claims = jwt.claims;
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
      var exp = claims['exp'] as int;
      var aud = claims['aud'] as String;
      var sub = claims['sub'] as String;
      var authTime = claims['auth_time'] as int;
      var email = claims['email'] as String;
      var emailVerified = claims['email_verified'] as bool;
      _payload = FirebaseAuthInfoPayload(
          iss: iss,
          iat: iat,
          userId: userId,
          exp: exp,
          authTime: authTime,
          sub: sub,
          aud: aud,
          email: email,
          emailVerified: emailVerified);
    }
  }

  /// Validate using public key fetched
  Future<bool> verify({Future<String> Function(String keyId) fetchKey}) async {
    if (header?.alg != 'RS256') {
      print('invalid jwt alg $header');
      return false;
    }

    try {
      var validator = JWTValidator();
      validator.validate(_jwt);
    } catch (e) {
      print('validator error $e');
    }

    var key = await fetchKey(header.kid);

    key = key.replaceAll(
        '-----BEGIN CERTIFICATE-----', '-----BEGIN RSA PUBLIC KEY-----');
    key = key.replaceAll(
        '-----END CERTIFICATE-----', '-----END RSA PUBLIC KEY-----');
    // -----BEGIN CERTIFICATE-----
    // static const String pkcs1PublicHeader = '-----BEGIN RSA PUBLIC KEY-----';
    // static const String pkcs1PublicFooter = '-----END RSA PUBLIC KEY-----';
    var signer = JWTRsaSha256Signer(publicKey: key);

    try {
      var validator = JWTValidator();
      validator.validate(_jwt, signer: signer);
    } catch (e) {
      print('validator error $e');
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

  Map toDebugMap() {
    return {'header': header.toDebugMap(), 'payload': payload.toDebugMap()};
  }

  @override
  String toString() => toDebugMap().toString();
}
/*
package com.tekartik.ae.firebase;

import com.auth0.jwt.JWTVerifier;
import com.auth0.jwt.JWTVerifyException;
import com.auth0.jwt.pem.X509CertUtils;
import com.google.gson.Gson;
import com.google.gson.annotations.SerializedName;
import com.google.gson.reflect.TypeToken;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.UnsupportedEncodingException;
import java.lang.reflect.Type;
import java.net.URL;
import java.security.InvalidKeyException;
import java.security.KeyFactory;
import java.security.NoSuchAlgorithmException;
import java.security.PublicKey;
import java.security.SignatureException;
import java.security.spec.X509EncodedKeySpec;
import java.util.Map;
import java.util.logging.Logger;
import com.google.appengine.repackaged.com.google.api.client.util.Base64;
/**
 * Created by alex on 17/08/16.
 *
 * Firebase auth tester
 */
public class FirebaseAuthInfo {

    private static final Logger log = Logger.getLogger(FirebaseAuthInfo.class.getName());

    public String getEmail() {
        return payload.email;
    }

    public String getUserId() {
        return payload.userId;
    }

    public String getSignInProvider() {
        return payload.firebase.signInProvider;
    }

    public String getName() {
        return payload.name;
    }

    public String getPicture() {
        return payload.picture;
    }

    public String getProjectId() {
        return payload.aud;
    }

    public static class Header {
        String alg;
        public String kid;

        @Override
        public String toString() {
            return "alg: " + alg + ", kid: " + kid;
        }
    }

    public static class Firebase {
        @SerializedName("sign_in_provider")
        public String signInProvider;

    }
    public static class Payload {
        public String email;

        public String name;

        public String picture;

        public String aud;

        @SerializedName("user_id")
        public
        String userId;

        public Firebase firebase;

        @Override
        public String toString() {
            return "user_id: " + userId + ", email: " + email;
        }
    }

    // input
    String token;

    // output
    public Header header;
    public Payload payload;

    Gson gson = new Gson();

    boolean verify() {
        return false;
    }

    public FirebaseAuthInfo(String token) {
        this.token  = token;
    }

    String decodeB64(String base64) throws UnsupportedEncodingException {
        return new String(Base64.decodeBase64(base64), "UTF-8");
        //return Base64Codec.decodeString(base64);
    }

    public PublicKey getKey(String key){
        try{

            X509EncodedKeySpec X509publicKey = new X509EncodedKeySpec(decodeB64(key).getBytes());
            KeyFactory kf = KeyFactory.getInstance("RSA");

            return kf.generatePublic(X509publicKey);
        } catch (java.lang.Exception e) {
            e.printStackTrace();
        }

        return null;
    }

    public String fetchKey(String keyId) throws IOException {
        URL url = new URL("https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com");
        BufferedReader reader = new BufferedReader(new InputStreamReader(url.openStream()));
        StringBuilder json = new StringBuilder();
        String line;

        while ((line = reader.readLine()) != null) {
            json.append(line);
        }
        reader.close();

        Type type = new TypeToken<Map<String, String>>() {
        }.getType();
        Map<String, String> keys = gson.fromJson(json.toString(), type);
        return keys.get(keyId);
    }


    public void decode() throws UnsupportedEncodingException {
            /*
            final String secret = "{{secret used for signing}}";
            try {
                final JWTVerifier jwtVerifier = new JWTVerifier(secret);
                final Map<String,Object> claims= jwtVerifier.verify(jwt);
            } catch (JWTVerifyException e) {
                // Invalid Token
                log.warning(e.toString());
            }
            */


        String parts[] = token.split("\\.");
        String header64 = parts[0];

        //byte[] encodedKey = Base64.decode(token);

        String jsonHeader = decodeB64(parts[0]);

        String jsonPayload = decodeB64(parts[1]);
        //String jsonSignature = decodeB64(parts[2]);
        //log.info(jsonHeader);
        //log.info(jsonPayload);
        //log.info(jsonSignature);
        this.header = gson.fromJson(jsonHeader, Header.class);
        //header.kid = "1234";
        this.payload = gson.fromJson(jsonPayload, Payload.class);
        //log.info(header.toString());
        //log.info(payload.toString());
    }

    public void decodeAndVerify() throws Exception {
        try {
            decode();
        } catch (UnsupportedEncodingException e) {
            throwException(e);
        }
        String key = null;
        try {
            key = fetchKey(header.kid);
            if (key == null) {
                throwException(new SignatureException("key " + header.kid + " not found"));
            }
        } catch (IOException e) {
            throwException(e);
        }
        verify(key);
    }

    public class Exception extends java.lang.Exception {
        Exception(java.lang.Exception source) {
            super(source);
        }
    }

    void throwException(java.lang.Exception e) throws Exception {
        throw new Exception(e);
    }

    public void verify(String key) throws Exception {


        PublicKey publicKey = X509CertUtils.parse(key).getPublicKey();
        try {
            final JWTVerifier jwtVerifier = new JWTVerifier(publicKey);
            String parts[] = token.split("\\.");
            String toSign = parts[0] + "." + parts[1];
            final Map<String,Object> claims= jwtVerifier.verify(token);
        } catch (JWTVerifyException e) {
            // Invalid Token
            log.warning(e.toString());
            throwException(e);
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
            throwException(e);
        } catch (IOException e) {
            e.printStackTrace();
            throwException(e);
        } catch (SignatureException e) {
            e.printStackTrace();
            throwException(e);
        } catch (InvalidKeyException e) {
            e.printStackTrace();
            throwException(e);
        }
    }
}

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
