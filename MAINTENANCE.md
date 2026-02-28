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
- Release: `.github/workflows/release.yml`
- Upstream source sync: `.github/workflows/upstream-sync.yml`
- Upstream drift monitor: `.github/workflows/upstream-monitor.yml`

## Implemented Guardrails

- Compatibility matrix: `packages/sherpa_onnx_ortv2/compat-matrix.yaml`
- API export guard: `tools/check-public-api-exports.ps1`
- Android ORT line guard: `tools/check-android-onnxruntime-version.ps1`
- iOS linkage guard: `tools/check-ios-linkage.ps1`
- Upstream drift detector: `tools/detect-upstream-drift.ps1`

## Release Rules

- Version format: `<upstream_version>-ortv2.<n>`
- Must pass before publish:
  - `verify.yml`
  - `dart pub publish --dry-run` for all 3 packages
- Real publish uses `release.yml` and requires `PUB_DEV_TOKEN` secret.

## Continuous Maintenance Flow

1. Monitor upstream drift (`upstream-monitor.yml` schedule).
2. Run `upstream-sync.yml` to sync upstream source and auto-update compat matrix entry.
3. Re-apply ORTv2-specific patches if upstream touched relevant files.
4. Run verify workflow and smoke tests.
5. Trigger release workflow after manual review.

## Known Remaining Work

- Full auto rebuild of Android/iOS native binaries per upstream tag.
- Broader device-matrix stability tests (hardware EP coverage).
- End-to-end automated iOS ORT rebuild-level verification.
