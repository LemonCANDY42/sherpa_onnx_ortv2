# sherpa_onnx_ortv2 Maintenance and Release

Last updated: 2026-02-28

## Scope

This repository is a functional fork of `sherpa_onnx` (Android/iOS first). Main goals:

- Keep ONNX Runtime version lines unified with `onnxruntime_v2` strategy.
- Provide `provider=auto` with stable fallback behavior.
- Keep API compatibility with upstream `sherpa_onnx` as much as possible.

Recommended remote:
`https://github.com/LemonCANDY42/sherpa_onnx_ortv2.git`

## CI and Workflows

- Verify: `.github/workflows/verify.yml`
- Release check and source artifact: `.github/workflows/release.yml`
- Upstream source sync: `.github/workflows/upstream-sync.yml`
- Upstream drift monitor: `.github/workflows/upstream-monitor.yml`
- Native artifact rebuild: `.github/workflows/native-rebuild.yml`

## Implemented Guardrails

- Compatibility matrix: `packages/sherpa_onnx_ortv2/compat-matrix.yaml`
- API export guard: `tool/check-public-api-exports.ps1`
- Android ORT line guard: `tool/check-android-onnxruntime-version.ps1`
- Android sherpa symbol guard: `tool/check-android-sherpa-symbol-version.ps1`
- iOS linkage guard: `tool/check-ios-linkage.ps1`
- Upstream drift detector: `tool/detect-upstream-drift.ps1`

## Release Rules

- Version format: `<upstream_version>-ortv2.<n>`
- Must pass before publish:
  - `verify.yml`
  - `dart pub publish --dry-run` for all 3 packages
- Current delivery mode: GitHub repository / submodule / git dependency (pub.dev publish disabled for now).

## Continuous Maintenance Flow

1. Monitor upstream drift (`upstream-monitor.yml` schedule).
2. Run `upstream-sync.yml` to sync upstream source.
3. Run `native-rebuild.yml` for the same sherpa/ORT version pair.
4. Re-apply ORTv2-specific patches if upstream touched relevant files.
5. Run verify workflow and smoke tests.
6. Trigger release workflow after manual review.

## Host App Integration Checklist

For any upstream update (`sherpa_onnx` or `onnxruntime_v2` related):

1. Ensure compat matrix has the target pair marked as releasable.
2. Ensure Android/iOS native binaries are aligned with the target upstream tag.
3. Ensure `provider=auto` policy and CPU fallback tests still pass.
4. Publish/push new commit in this repository.
5. In host app repository, move submodule pointer to that commit and run:
   - `flutter pub get`
   - `flutter analyze`
   - policy/config tests from `packages/sherpa_onnx_ortv2/test/`

## Known Remaining Work

- Broader device-matrix stability tests (hardware EP coverage).
- End-to-end runtime smoke on physical iOS/Android devices for each release candidate.


