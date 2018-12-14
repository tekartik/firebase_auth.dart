import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth_node/src/auth_node.dart' as _;

AuthService get authServiceNode => _.authService;
AuthService get authService => authServiceNode;
