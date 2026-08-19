# 最新接续状态 (2026-08-17 21:22)

## 核心进展
- Bug 修复型任务：已修复 Gemini37 模式应用失败、旧 IDE 进程误阻断、ESM `main.js` 被 CommonJS 语法检查误判、Agent Pro LF/CRLF 补丁误判，以及 Gemini 3.7 选择无法跨重启持久化的问题。
- 已部署到 `D:\Antigravity`；部署后 `Get-CompatibilityInstallStatus -Mode Gemini37 -AgentProSourcePath <source.js>` 返回 `Passed=True`。
- Gemini 3.7 使用旧协议 `RECOMMENDED` alias 8；首次请求仍由 Agent Pro 精确改写 `gemini-2.5-pro -> gemini-3.7-flash-high`。Gemini 3.6、Claude 和未命中请求保持原样。

## 核心动机与背景 (Motivation & Background)
- 用户现场问题一：点击“应用并启动”提示 Gemini37 模式应用失败。
- 根因链一：`Get-Process.Path` 为空时定向停止逻辑无法识别安装目录进程；另有 PID 29472 为 0 线程、0 句柄的僵尸对象，被误判为活跃进程。
- 根因链二：已安装 Agent Pro 补丁使用 LF，校验器按 Windows CRLF 整块匹配，误报“不完整补丁”。
- 根因链三：Electron `main.js` 包含顶层 `import`，临时文件固定使用 `.js`，Node 18 按 CommonJS 执行 `--check`，误报 `Cannot use import statement outside a module`。
- 用户现场问题二：首次选择 Gemini 3.7 无响应；先使用其他模型再切回才恢复；重启始终回到 Gemini 3.6。
- 根因链四：Gemini37 Workbench 仅持久化 Gemini 3.6 的 model ID；Gemini 3.7 使用 alias 8，旧 `qb` 对非 model choice 直接返回，因此 3.7 选择从未持久化。

## 关键设计与实现 (Implementation & Decisions)
- `scripts/StableMode.Core.psm1`：
  - 新增进程路径快照，优先使用 `Get-Process.Path`，为空时回退 `Win32_Process.ExecutablePath`；0 线程进程视为已退出。
  - Agent Pro 补丁结构校验和回退同时支持 LF/CRLF。
  - `Test-JavaScriptSyntax` 根据顶层 `import`/`export` 自动选择 `.mjs` 或 `.js` 临时扩展名，继续保留严格语法检查。
  - 为 Gemini37 增加独立 `_agGemini37PreferenceKey`，选择 alias 8 时持久化；选择 Gemini 3.6 或其他模型时清除冲突状态。
  - 恢复模型时优先恢复 Gemini 3.7 alias 8，否则恢复 Gemini 3.6/native modelPreferences。
  - 无历史选择时，Gemini 3.7 High 作为默认兜底；已有 Claude、Gemini 3.6 或 Gemini 3.7 选择应保持最后选择。
  - Gemini37 使用专用 Qb/Db replacement，未污染纯 Gemini36 模式。
  - 增加上一版 `gemini37-combined-v2` Workbench 的精确迁移路径，允许现有部署升级。
- `tests/Test-Gemini37Mode.ps1`：更新断言，要求 Gemini37 Workbench 存在 alias 8 持久化状态。
- 已通过：`Test-Gemini36Mode.ps1`、`Test-Gemini37Mode.ps1`、`Test-Gemini37AgentProPatch.ps1`、`Test-Gemini37AgentProxyCompat.cjs`、`git diff --check`。
- 部署静态证据：`Persistence=True`、`Alias8=True`、`Passed=True`；任务结束前活跃 Antigravity/语言服务器进程计数为 0。

## 待办事项 (Next Steps)
- [ ] 用户真实启动 IDE 后，首次直接选择 Gemini 3.7 High 并发送消息，确认无需先使用其他模型。
- [ ] 分别选择 Claude、Gemini 3.6、Gemini 3.7 后重启 IDE，逐项确认最后选择恢复正确。
- [ ] 若真实首次请求仍无响应，抓取 Agent Pro 首次请求日志，确认是否出现 `GEMINI37-MODEL-REWRITE` 及上游 `gemini-3.7-flash-high`，不要继续猜测 UI 状态。
- [ ] 当前修改尚未提交：`scripts/StableMode.Core.psm1`、`tests/Test-Gemini37Mode.ps1`。

## 关键上下文
- 目录: `D:\Desktop\Super-File\AI-IDE\AI\反重力\antigravity-old-compat-manager`
- 安装目录: `D:\Antigravity`
- Agent Pro: `C:\Users\Administrator\.antigravity\extensions\dao-agi.dao-proxy-pro-9.9.500\vendor\bundled-origin\source.js`
- 主要文件: `scripts\StableMode.Core.psm1`、`runtime\Gemini37AgentProxyCompat.cjs`、`StableBootstrap.ps1`、`tests\Test-Gemini37Mode.ps1`、`tests\Test-Gemini37AgentProPatch.ps1`、`tests\Test-Gemini37AgentProxyCompat.cjs`
- 项目规则: `.agent\rules\README.md`
