# firebase_auth.dart

Firebase Auth dart common interface and implementation for Browser, VM, node and flutter

## Firebase Initialization

### Usage in browser

```
dependencies:
  tekartik_firebase_auth_browser:
    git:
      url: https://github.com/tekartik/firebase_auth.dart
      path: auth_browser
      ref: dart3a
    version: '>=0.3.8'
```

```dart
import 'package:tekartik_firebase_auth_browser/auth_browser.dart';

void main() {
  var authService = authServiceBrowser;
  // ...
}
```  

### Usage on node

```
dependencies:
  tekartik_firebase_auth_node:
    git:
      url: https://github.com/tekartik/firebase_node.dart
      path: auth_node
      ref: dart3a
    version: '>=0.3.8'
```

```dart
import 'package:tekartik_firebase_auth_node/auth_node.dart';

void main() {
  var authService = authServiceNode;
  // ...
}
```  

## Generic usage

```
dependencies:
  tekartik_firebase_auth:
    git:
      url: https://github.com/tekartik/firebase_auth.dart
      path: auth
      ref: dart3a
    version: '>=0.3.8'
```


## Auth access

```dart
var auth = authService.auth(app);
// ...

```  

