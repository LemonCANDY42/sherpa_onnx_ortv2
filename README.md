# sherpa_onnx_ortv2 (Standalone Repo Layout)

This repository contains the public standalone `sherpa_onnx_ortv2` fork.

## Goals

- Keep package development and release independent from any host application repository.
- Provide Android/iOS ONNX Runtime unification.
- Provide `provider=auto` with safe fallback behavior.

## Repository layout

- `packages/sherpa_onnx_ortv2`
- `packages/sherpa_onnx_ortv2_android`
- `packages/sherpa_onnx_ortv2_ios`
- `.github/workflows/verify.yml`
- `.github/workflows/release.yml`
- `.github/workflows/upstream-sync.yml`
- `.github/workflows/upstream-monitor.yml`

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
- Manual publish to pub.dev: `release.yml` with `PUB_DEV_TOKEN`
- Maintenance guide: `MAINTENANCE.md`

Version format:

- `<upstream_version>-ortv2.<n>`
