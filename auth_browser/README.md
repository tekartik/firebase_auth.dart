
## Usage

In your `pubspec.yaml`:

```yaml
tekartik_firebase_auth_browser:
  git:
    url: https://github.com/tekartik/firebase_auth.dart
    path: auth_browser
    ref: dart2_3
  version: '>=0.8.1'
```

## Test

### Setup

Copy the file `test/config.sample.yaml` as `test/config.local.yaml` with your firebase info

Run

    pub run build_runner test --fail-on-severe -- -p chrome -r expanded
    
