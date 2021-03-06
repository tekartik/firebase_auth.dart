# firebase_rest.dart

REST API

## Firebase Initialization

### Usage in IO

```
dependencies:
  tekartik_firebase_auth_rest:
    git:
      url: git://github.com/tekartik/firebase_auth.dart
      path: auth_rest
      ref: dart2
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
      url: git://github.com/tekartik/firebase_auth.dart
      path: auth_node
      ref: dart2
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
      url: git://github.com/tekartik/firebase_auth.dart
      path: auth
      ref: dart2
    version: '>=0.3.8'
```


## Auth access

```dart
var auth = authService.auth(app);
// ...

```  

