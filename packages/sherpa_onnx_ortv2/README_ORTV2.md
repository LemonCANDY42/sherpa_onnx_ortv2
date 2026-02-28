# sherpa_onnx_ortv2

Functional fork of `sherpa_onnx` for Android/iOS compatibility with `onnxruntime_v2`.

## Repo mode

- Maintained as a standalone public repository.
- Consumed by SaySee through Git submodule:
  `app/saysee_client/submodules/sherpa_onnx_ortv2`.
- Build/release is handled in the standalone repo GitHub Workflows.

## What is added

- Non-breaking `provider: "auto"` support.
- Global policy API:
  - `setAutoProviderPolicy(...)`
  - `autoProviderPolicy`
- Provider diagnostics fields in logs:
  - `requested_provider`
  - `resolved_provider`
  - `fallback_reason`

## Default auto policy

- Android: `nnapi -> qnn -> xnnpack -> cpu`
- iOS: `coreml -> xnnpack -> cpu`
- Others: `xnnpack -> cpu`

## Usage

```dart
import 'package:sherpa_onnx_ortv2/sherpa_onnx.dart' as sherpa;

void configureSherpa() {
  sherpa.setAutoProviderPolicy(
    const sherpa.AutoProviderPolicy(
      androidPriority: <String>['nnapi', 'qnn', 'xnnpack', 'cpu'],
      iosPriority: <String>['coreml', 'xnnpack', 'cpu'],
      defaultPriority: <String>['xnnpack', 'cpu'],
      enableOnnxruntimeProbe: true,
      enableDiagnostics: true,
    ),
  );
}
```

Any existing code that omitted `provider` now uses `auto` by default.
If you explicitly set `provider: "cpu"`, behavior remains explicit CPU.

## Compatibility matrix

See `compat-matrix.yaml` for approved upstream/ORT combinations.

## Guard scripts

- `tools/assert-compat-matrix.ps1`
- `tools/check-public-api-exports.ps1`
- `tools/check-android-onnxruntime-version.ps1`
