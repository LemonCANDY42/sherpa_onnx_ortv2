# sherpa_onnx_ortv2 (Standalone Repo Layout)

This directory is the standalone repository layout for the public `sherpa_onnx_ortv2` fork.

## Goals

- Keep package development/release fully independent from the private SaySee app repo.
- Keep SaySee as a consumer only, via Git submodule pinning.
- Support Android/iOS ONNX Runtime unification and `provider=auto` fallback behavior.

## Repository layout

- `packages/sherpa_onnx_ortv2`
- `packages/sherpa_onnx_ortv2_android`
- `packages/sherpa_onnx_ortv2_ios`
- `.github/workflows/verify.yml`
- `.github/workflows/release.yml`
- `.github/workflows/upstream-sync.yml`

## Consume from a host app repo (submodule)

In your host repo root:

```bash
git submodule add <PUBLIC_REPO_URL> <your-submodule-path>
git submodule update --init --recursive
```

Then point Flutter `pubspec.yaml` path dependencies to:
`<your-submodule-path>/packages/...`

Example (SaySee):
`app/saysee_client/submodules/sherpa_onnx_ortv2_repo/packages/...`

## Release model

- CI verification: `verify.yml`
- Upstream sync helper: `upstream-sync.yml`
- Manual publish to pub.dev: `release.yml` with `PUB_DEV_TOKEN`
- Maintenance guide: `MAINTENANCE.md`

Version format:

- `<upstream_version>-ortv2.<n>`

