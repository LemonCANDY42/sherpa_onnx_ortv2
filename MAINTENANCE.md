# sherpa_onnx_ortv2 维护与发布流程

更新时间：2026-02-28

## 仓库定位

本仓库是 `sherpa_onnx` 的功能性 fork（Android/iOS 优先），目标是：

- 统一 ORT 版本线，降低与 `onnxruntime_v2` 共存冲突风险
- 提供 `provider=auto` 自动后端选择
- 在自动选择失败时稳定回退到 CPU

建议远端仓库地址：
`https://github.com/LemonCANDY42/sherpa_onnx_ortv2.git`

## CI / Workflow

- 验证：`.github/workflows/verify.yml`
- 发布：`.github/workflows/release.yml`
- 上游同步辅助：`.github/workflows/upstream-sync.yml`

## 与原计划对比（审计）

### 已实现

- Fork 包拆分与功能命名：`sherpa_onnx_ortv2*`
- Android ORT 版本线固定为 `onnxruntime-android:1.23.2`
- Dart 层 `provider=auto` 策略与统一诊断字段输出
- `compat-matrix.yaml` + API 导出守卫 + CI 验证流程
- 子仓库消费模型（供 SaySee 等业务仓库接入）

### 本轮修复

- 修复 `qnn` 在 provider 列表中被遗漏的问题
- 修复 probe 失败/关闭时的“盲选 provider”风险：默认保守回退 CPU
- 增加可选开关 `allowOptimisticSelectionWithoutProbe`（默认 `false`）
- 增加 iOS linkage guard：`tools/check-ios-linkage.ps1`
- `verify.yml` 新增 `macos-latest` 的 iOS linkage 检查 job

### 仍未完全闭环（需后续阶段）

- 按每个上游 tag 自动重建 Android/iOS 原生二进制（目前是同步与守卫，非完整自动重编）
- 设备矩阵级稳定性测试（500 次连续推理、前后台切换、多机型硬件 EP 验证）
- iOS 侧 ORT 版本线的“重编译级”统一验证（当前为产物守卫，非全链路重建）

## 发布规则

- 版本号遵循：`<upstream_version>-ortv2.<n>`
- 发布前必须通过：
  - `verify.yml`
  - `dart pub publish --dry-run`（三个包）
- 正式发布由 `release.yml` 手动触发并要求 `PUB_DEV_TOKEN`

## 上游同步建议流程

1. 触发 `upstream-sync.yml` 拉取新版本源码。
2. 重新应用 ORTv2 patch（provider auto、版本线、守卫脚本）。
3. 更新 `compat-matrix.yaml` 状态。
4. 跑 `verify.yml`。
5. 通过后再触发 `release.yml`。
