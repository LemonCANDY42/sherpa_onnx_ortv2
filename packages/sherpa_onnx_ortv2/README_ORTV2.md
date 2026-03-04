# sherpa_onnx_ortv2

Functional fork of `sherpa_onnx` for Android/iOS compatibility with `onnxruntime_v2`.

## What this fork adds

- Non-breaking `provider: "auto"` support (default for most model configs).
- Global policy API:
  - `setAutoProviderPolicy(...)`
  - `autoProviderPolicy`
- Provider diagnostics fields in logs:
  - `requested_provider`
  - `resolved_provider`
  - `fallback_reason`
- Android ORT line alignment for coexistence with `onnxruntime_v2`.

## Quick Start (Host App + Submodule)

### 1) Add this repo as a submodule in your host app repo

```bash
git submodule add <PUBLIC_REPO_URL> submodules/sherpa_onnx_ortv2_repo
git submodule update --init --recursive
```

### 2) Point host `pubspec.yaml` to the package path

First, choose one `status: "active"` pair from `compat-matrix.yaml` and keep
your host `onnxruntime_v2` version on that same ORT line.

Example (current active ORT line):

```yaml
dependencies:
  onnxruntime_v2: ^1.23.2+2
  sherpa_onnx_ortv2:
    path: submodules/sherpa_onnx_ortv2_repo/packages/sherpa_onnx_ortv2
```

Then run:

```bash
flutter pub get
```

### 3) Build-time sanity checks (recommended)

From host app root:

```bash
flutter test submodules/sherpa_onnx_ortv2_repo/packages/sherpa_onnx_ortv2/test/auto_provider_policy_test.dart
flutter test submodules/sherpa_onnx_ortv2_repo/packages/sherpa_onnx_ortv2/test/tts_pocket_config_test.dart
flutter build apk --debug
```

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
      allowOptimisticSelectionWithoutProbe: false,
      enableDiagnostics: true,
    ),
  );
}
```

Any existing code that omitted `provider` now uses `auto` by default.
If you explicitly set `provider: "cpu"`, behavior remains explicit CPU.
When provider probing is unavailable, default behavior is conservative CPU fallback.

## Runtime verification (provider resolution)

Enable diagnostics in policy:

```dart
sherpa.setAutoProviderPolicy(
  const sherpa.AutoProviderPolicy(
    enableDiagnostics: true,
  ),
);
```

Then inspect logs for tag `sherpa_onnx_ortv2.provider`:

- `requested_provider`
- `resolved_provider`
- `fallback_reason`

This confirms whether runtime uses NNAPI/QNN/CoreML/XNNPACK/CPU, and why fallback happened.

## Guard scripts (release and CI checks)

Run from `packages/sherpa_onnx_ortv2`:

```powershell
pwsh ./tool/assert-compat-matrix.ps1 -SherpaTag <SHERPA_TAG> -OrtVersion <ORT_VERSION>
pwsh ./tool/check-public-api-exports.ps1 -UpstreamVersion <UPSTREAM_VERSION>
pwsh ./tool/check-android-sherpa-symbol-version.ps1 -ExpectedOrtVersion <ORT_VERSION>
pwsh ./tool/check-ios-linkage.ps1
```

Example:

```powershell
pwsh ./tool/assert-compat-matrix.ps1 -SherpaTag 1.12.27 -OrtVersion 1.23.2
pwsh ./tool/check-public-api-exports.ps1 -UpstreamVersion 1.12.27
pwsh ./tool/check-android-sherpa-symbol-version.ps1 -ExpectedOrtVersion 1.23.2
pwsh ./tool/check-ios-linkage.ps1
```

Why these matter:

- prevent unsupported sherpa/ORT version pair publish
- prevent Dart public API regression vs upstream
- prevent Android symbol version mismatch (common `OrtGetApiBase`/`VERS_*` issues)
- prevent iOS packaging of unexpected extra ORT artifacts

Other useful scripts:

- `tool/check-android-onnxruntime-version.ps1`
- `tool/detect-upstream-drift.ps1`
- `tool/update-compat-matrix.ps1`

## Compatibility matrix

See `compat-matrix.yaml` for approved upstream/ORT combinations.

## Common integration failures

1. Error: `cannot locate symbol "OrtGetApiBase"` / `VERS_*` mismatch
   - Cause: mixed ONNX Runtime binaries from different version lines.
   - Fix:
     - align ORT line to one version pair from `compat-matrix.yaml`
     - run `check-android-sherpa-symbol-version.ps1`

2. `provider: "nnapi"` or `provider: "coreml"` crashes or fails for some models
   - Cause: model/operator not supported by target EP.
   - Fix:
     - keep `provider: "auto"` and fallback enabled
     - inspect diagnostics fields to confirm resolved provider and reason

3. Build succeeds but runtime backend unclear
   - Fix:
     - enable diagnostics
     - verify `sherpa_onnx_ortv2.provider` logs for resolved provider


