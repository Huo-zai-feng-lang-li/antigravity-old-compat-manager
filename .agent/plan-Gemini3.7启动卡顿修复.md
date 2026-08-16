# Gemini 3.7 启动卡顿修复

## 目标
- Gemini 3.7 只修改 `main.js` 模型名单。
- Workbench 保持 Stable 原生结构，不注入 React/USS 模型状态机。
- 启动参数保持 `--remote-debugging-port=9000`。

## 根因证据
- 失败日志 `20260815T185005`、`20260815T185133` 在启动后出现 `CodeWindow` 无响应。
- 堆栈稳定落在 Workbench `sort/shift/render` 调度，不在模型请求或语言服务器。
- 旧 3.7 Workbench 含 `_agGemini37*`、`qb`、`Db` 注入；Claude/Stable 不含这些注入。
- 缓存 ID 校验仍保留为防御性修复，但不是主根因结论。

## 已完成
- [x] 回归测试先证明 3.7 Workbench 注入存在。
- [x] 3.7 目标 Workbench 改为 Stable 原生字节。
- [x] v4/v5 旧 3.7 Workbench 可精确迁移回 Stable。
- [x] Bootstrap 升级到 schema 6 / `compatibility-v6-gemini37-native-workbench`。
- [x] 部署到 `D:\Antigravity`，静态状态 `Passed=True`。
- [x] 两次独立冷启动各观察 60 秒，无 `CodeWindow` 无响应事件。
- [x] 追加修复 3.7 模型目录大小写重复标签，并升级 Bootstrap schema 7 强制迁移旧 v6 profile。
- [x] 所有任务进程已清理。

## 验证日志
- `20260815T194946\main.log`：窗口约 2.03 秒、CDP 约 1.76 秒、60 秒无响应。
- `20260815T195230\main.log`：窗口约 2.03 秒、CDP 约 1.77 秒、60 秒无响应。

## 2026-08-16 现场复发重新诊断

### 硬约束
- 保留 Claude 模式和现有模型目录行为。
- 只触及兼容管理器启动/部署脚本、对应测试、`D:\Antigravity` 已部署文件及必要用户状态。
- 不升级 Antigravity，不覆盖无关改动，不以模型 ID 猜测根因。

### 阶段计划
- [x] 独占复现当前启动链，记录窗口响应性、进程树、CDP、日志和 `CodeWindow` 事件。
- [x] 定位 v6→v7 部署阻塞层并形成可证伪假设。
- [x] 先添加失败回归并确认旧实现为 RED。
- [x] 实施最小修复并部署到 `D:\Antigravity`。
- [x] 运行定向脚本测试、完整测试和影响面检查。
- [x] 连续两次独占冷启动，各观察 60 秒：窗口可响应且无 `CodeWindow` unresponsive 事件。
- [x] 更新 handoff，并关闭本任务启动的全部进程。

### 当前证据
- 用户在当前 Gemini37 部署上再次得到“窗口未响应”弹框，旧结论已失效。
- `20260816T152501` 启动日志显示语言服务器约 11.7 秒后初始化完成，但普通文本日志没有记录弹框本身。
- 修复前 `StableBootstrap.ps1 -Mode Gemini37 -NoLaunch` 稳定返回退出码 `1`，原始错误为 `A parameter cannot be found that matches parameter name 'or'.`。
- 阻塞链路是 `ConvertTo-StableMainContent` 中未括起的命令调用使 `-or` 被解析为参数；修复该点后，回归继续暴露 `Get-Gemini37ContentGeneration` 未识别 v6 主文件迁移态。
- 回归先后按预期失败于上述两个位置；仅增加命令括号和 v6 `Legacy` 识别后转绿。
- 已部署 schema 7 / `compatibility-v7-gemini37-deduplicated-catalog`；Main 为 `3AF4A1BD9D281D8F6EFCCBFD67D52204B5718F48C2BD1A73C9AE09EE12276693`，Workbench 保持原生 `EF1D5838CAE783E7974DBD876A3B0C121DE861572B246939F8765830296ECA1A`。
- 第一次冷启动 `20260816T162232`：窗口/CDP 约 1.75 秒，最长无响应 0 秒，`CodeWindow` 事件 0。
- 第二次冷启动 `20260816T162406`：窗口/CDP 约 1.73 秒，最长无响应 0 秒，`CodeWindow` 事件 0。
- PowerShell 14/14、.NET 42/42、Node 2/2 通过。

## 2026-08-16 v9 模型列表与启动修复

- [x] CDP 复现 v8 模型选择器为空：两个工作区均为 `No Model Selected`。
- [x] 撤销把完整模型配置写入 `defaultOverrideModelConfig` 的错误方案。
- [x] 改为仅在默认覆盖解析为 Gemini 3.7 时清空覆盖，不修改模型数组。
- [x] Bootstrap 升级为 `compatibility-v9-gemini37-default-override-safety`，强制迁移旧档案。
- [x] Gemini37 实际目录包含 High/Medium 与两项 Claude，不含 3.6 和 Low。
- [x] 60 秒独占冷启动：窗口/CDP 1.82 秒，最长无响应 0 秒，日志事件 0。
- [x] 修正冷启动脚本对 `ExecutablePath` 为空进程的漏检，并确认任务进程已清理。

### 当前部署
- 模式：`Gemini37`。
- Main：`49C46CF2E3FA11E2EF4F89F6840FA72D5A80D294B4B9D4751388E6A2D4706700`。
- 冷启动日志：`20260816T232152`。

## 2026-08-17 真实路由与 3.6 共存修复

### 新目标
- 保留 Claude、Gemini 3.7、Gemini 3.6。
- IDE 启动后不出现 `CodeWindow` 无响应。
- 三类模型都必须实际返回响应，不能只显示目录。

### 已取证
- Trajectory `7cf3cf7c-39f6-4ef7-aa7d-e40440c9fcdd` 与 `a05c81ec-3927-4acb-8b12-a1c6363c8604` 均返回 `MODEL_CAPACITY_EXHAUSTED`，服务端实际模型为 `gemini-2.5-pro`。
- Agent Pro 诊断 `#192` 对应 Trace `b8cc51e1f0196d96`，请求类型为 `GEMINI_REST_CHAT`。
- 无提示词诊断确认请求是 JSON，顶层字段为 `model`，键集合为 `enabledCreditTypes/model/project/request/requestId/requestType/userAgent`。
- 结论：旧协议 `RECOMMENDED` alias 只能稳定承载选择，不能代表真实 3.7；必须在本地代理边界把占位模型精确改写为 `gemini-3.7-flash-high`。

### 实施边界
- Gemini37 模式目录改为 Claude + Gemini 3.7 + Gemini 3.6，不放出 Low。
- Workbench 仅复用 Gemini 3.6 已验证的固定 ID `1264/1265` 本地持久化，不恢复动态 3.7 ID 状态机。
- 代理改写仅在 Gemini37 模式补丁存在且请求模型严格等于 `gemini-2.5-pro` 时生效；3.6、Claude、非 JSON 请求保持原字节。
- Agent Pro 源文件与兼容 helper 纳入同一备份、哈希、回滚和 Bootstrap 自愈链。

### 阶段状态
- [x] 复现并确认 503 的服务端实际模型。
- [x] 确认请求体模型字段位置与代理修改点。
- [x] 添加失败回归测试，分别覆盖组合名单、精确请求改写和 Agent Pro 可逆补丁。
- [x] 实现组合目录、固定 Workbench 桥与代理改写。
- [x] 部署后实测三类模型响应及长时不卡死。

### 代码验证
- PowerShell：15/15 通过，包含 Bootstrap v13 迁移、Agent Pro 同事务部署/回滚和跨模式自愈。
- Node：Gemini 3.7 精确改写通过，3.6、Claude、非 JSON 请求保持原字节；OneLS 桥 10/10。
- .NET：Core 39/39、Windows Infrastructure 3/3。

### 最终现场证据
- 已部署 schema 8 / `compatibility-v13-gemini37-real-route-gemini36`，静态检查全部通过且目标档案唯一。
- 用户现场确认 Gemini 3.6 与 Gemini 3.7 High 均可正常响应；Claude 在同一兼容链上已正常响应。
- 180 秒独占冷启动：窗口/CDP 2.66 秒就绪，最长无响应 0 秒，`CodeWindow unresponsive` 事件 0；日志目录 `20260817T025704`。
- 已知限制：Gemini 3.7 Medium 与 High 共用 `RECOMMENDED` alias 8，当前按 choice 去重后不显示；已记录到项目规则和兼容指南，未恢复会导致卡死的动态 Workbench 状态机。
