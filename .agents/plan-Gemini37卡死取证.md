# Gemini 3.7 卡死取证计划

## 目标
- 判定当前 IDE 卡死是否由 Gemini 3.7 兼容层或模型状态触发。

## 约束
- 只读现机取证，不修改安装、不切换模型、不杀用户进程。
- 结论必须绑定安装状态、状态库、进程参数或日志证据。

## 阶段
1. [x] 核对已部署模式、主文件与 Workbench 状态。
2. [x] 核对实际进程参数、CDP 与模型偏好状态。
3. [x] 分析最新日志并区分模型、兼容层、环境三类根因。
4. [x] 给出结论和最小复现动作。

## 证据
- `D:\Antigravity` 静态状态：`Gemini37`、`Passed=True`，Workbench 哈希为已验证 Stable 内容。
- 17:42、17:45、17:46 三次用户启动日志出现 `CodeWindow unresponsive`，最新一轮 14 个采样后恢复。
- 状态库 `antigravityUnifiedStateSync.modelPreferences` 为空；认证模型状态未出现 Gemini 3.7 选中或调用记录。
- 同一 Gemini37 安装的 30 秒独占冷启动，以及全新 APPDATA 冷启动，均 `MaxUnresponsiveSeconds=0`、事件数 `0`。
- 结论：不是 Gemini 3.7 模型调用导致的必现卡死；问题仍是间歇性 UI 渲染/用户状态路径，需在复现时保留当次日志和交互步骤才能继续定位。

## 完成标准
- 明确回答 Gemini 3.7 是否有直接证据。
- 明确列出已排除项和仍缺失的证据。
