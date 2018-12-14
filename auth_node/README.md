## Test setup

 Use dart2 and set env variable
    
    npm install
    
    npm install firebase-admin --save
     
## Test

    pub run build_runner test -- -p node
    pub run test -p node
    pub run test -p node test/auth_node_test.dart

### Single test

    pub run build_runner test -- -p node .\test\auth_node_test.dart

    pbr test -- -p -node test/auth_node_test.dart
