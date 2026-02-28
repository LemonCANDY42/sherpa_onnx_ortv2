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

## Consume from SaySee (submodule)

In the SaySee repo root:

```bash
git submodule add <PUBLIC_REPO_URL> app/saysee_client/submodules/sherpa_onnx_ortv2_repo
git submodule update --init --recursive
```

SaySee `pubspec.yaml` should reference paths under:
`submodules/sherpa_onnx_ortv2_repo/packages/...`

## Release model

- CI verification: `verify.yml`
- Upstream sync helper: `upstream-sync.yml`
- Manual publish to pub.dev: `release.yml` with `PUB_DEV_TOKEN`
- Maintenance guide: `MAINTENANCE.md`

Version format:

- `<upstream_version>-ortv2.<n>`

