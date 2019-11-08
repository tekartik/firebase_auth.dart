import 'package:tekartik_firebase_auth/auth.dart';

import 'src/auth_flutter.dart' as auth_flutter;

export 'auth_flutter_api.dart';

/// The flutter auth service
AuthService get authServiceFlutter => auth_flutter.authService;

AuthService get authService => authServiceFlutter;
