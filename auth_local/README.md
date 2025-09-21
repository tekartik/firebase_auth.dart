# firebase_auth_local

REST API

## Firebase Initialization

### Usage in IO

```
dependencies:
  tekartik_firebase_auth_local:
    git:
      url: https://github.com/tekartik/firebase_auth.dart
      path: auth_local
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
      url: https://github.com/tekartik/firebase_auth.dart
      path: auth_node
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
    version: '>=0.3.8'
```


## Auth access

```dart
var auth = authService.auth(app);
// ...

```  

