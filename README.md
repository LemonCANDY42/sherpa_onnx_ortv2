# sherpa_onnx_ortv2

`sherpa_onnx_ortv2` is a compatibility-first Flutter fork of `sherpa_onnx`,
focused on Android/iOS ONNX Runtime unification with `onnxruntime_v2`.

## Goals

- Keep development and release independent from any host application repository.
- Keep Dart API behavior aligned with upstream `sherpa_onnx` as much as possible.
- Unify Android/iOS ONNX Runtime version lines for coexistence with `onnxruntime_v2`.
- Provide `provider=auto` with deterministic priority and safe CPU fallback.

## Related repositories

- Upstream `sherpa_onnx`: https://github.com/k2-fsa/sherpa-onnx
- ONNX Runtime: https://github.com/microsoft/onnxruntime
- `onnxruntime_v2` package: https://pub.dev/packages/onnxruntime_v2

## Repository layout

- `packages/sherpa_onnx_ortv2`
- `packages/sherpa_onnx_ortv2_android`
- `packages/sherpa_onnx_ortv2_ios`
- `.github/workflows/verify.yml`
- `.github/workflows/release.yml`
- `.github/workflows/upstream-sync.yml`
- `.github/workflows/upstream-monitor.yml`
- `.github/workflows/native-rebuild.yml`

## Consume from a host app repo (submodule)

In your host repo root:

```bash
git submodule add <PUBLIC_REPO_URL> <your-submodule-path>
git submodule update --init --recursive
```

Then point Flutter `pubspec.yaml` path dependencies to:
`<your-submodule-path>/packages/...`

## Release model

- CI verification: `verify.yml`
- Upstream sync helper: `upstream-sync.yml`
- Upstream drift monitor: `upstream-monitor.yml`
- Native binary rebuild automation: `native-rebuild.yml`
- Release check + source artifact build: `release.yml`
- Maintenance guide: `MAINTENANCE.md`

Version format:

- `<upstream_version>-ortv2.<n>`

## Native rebuild automation

`native-rebuild.yml` is the primary workflow for rebuilding Android/iOS native artifacts from upstream `sherpa_onnx` tags while pinning ONNX Runtime to the target `onnxruntime_v2` line.

- Android outputs:
  - `packages/sherpa_onnx_ortv2_android/android/src/main/jniLibs/*/libsherpa-onnx-c-api.so`
  - `packages/sherpa_onnx_ortv2_android/android/src/main/jniLibs/*/libsherpa-onnx-cxx-api.so`
- iOS output:
  - `packages/sherpa_onnx_ortv2_ios/ios/sherpa_onnx.xcframework`

By default it resolves the latest upstream versions from pub.dev, rebuilds on GitHub-hosted runners, and opens a PR with the refreshed binaries and compat-matrix update.

