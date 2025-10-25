# emulator_server


## Generating ts from emulator_controller.proto:

```bash
npx protoc  --plugin=./node_modules/.bin/protoc-gen-ts_proto.cmd --ts_proto_out=./src/emulator  --ts_proto_opt=esModuleInterop=true,outputServices=grpc-js  -I ./protos  ./protos/*.proto
```

# start the Emulator in background mode:
```bash
emulator -avd Medium_Phone_API_36.1 -grpc 8554 -no-window
```