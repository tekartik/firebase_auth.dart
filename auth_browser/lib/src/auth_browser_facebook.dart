import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth_browser/src/auth_browser.dart';

import 'import_native.dart' as native;

class FacebookAuthCustomParameters {
  static const displayPopup = 'popup';
  final String? display;

  FacebookAuthCustomParameters({this.display});

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{if (display != null) 'display': display};
    return map;
  }
}

abstract class FacebookAuthProvider extends AuthProvider {
  static const scopeEmail = 'email';

  factory FacebookAuthProvider() => FacebookAuthProviderImpl();

  void addScope(String scope);

  void setCustomParameters(FacebookAuthCustomParameters parameter);
}

class FacebookAuthProviderImpl extends AuthProviderImpl
    implements FacebookAuthProvider {
  FacebookAuthProviderImpl() : super(native.FacebookAuthProvider()) {
    _nativeAuthProvider = nativeAuthProvider as native.FacebookAuthProvider;
  }

  late native.FacebookAuthProvider _nativeAuthProvider;

  /// Adds additional OAuth 2.0 scopes that you want to request from the
  /// authentication provider.
  @override
  void addScope(String scope) {
    _nativeAuthProvider = _nativeAuthProvider.addScope(scope);
  }

  @override
  void setCustomParameters(FacebookAuthCustomParameters parameter) {
    _nativeAuthProvider.setCustomParameters(parameter.toMap());
  }
}
