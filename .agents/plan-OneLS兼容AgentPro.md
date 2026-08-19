# OneLS 兼容 Agent Pro Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 保留 OneLS 发送稳定性的同时，让共享 LS 冷启动后可靠进入 Agent Pro 提示词代理。

**Architecture:** 由无副作用桥接模块等待 extension-host 内 Agent Pro 代理健康；主进程只在严格校验成功后改写共享 LS 的 Cloud Code 端点，失败自动官方直通。Agent Pro 卸载判断同步改为当前目录精确匹配。

**Tech Stack:** PowerShell 7、Node.js/CommonJS、Electron main bundle、VS Code extension、JSONC、现有 PowerShell/Node 回归脚本。

---

### Task 1: Agent Pro 卸载误判 TDD

**Files:**
- Modify: `C:\Users\Administrator\Desktop\windsurf-assistant\tools\checks\antigravity-target-check.js`
- Modify: `C:\Users\Administrator\Desktop\windsurf-assistant\plugins\dao-proxy-pro\extension.js:1331-1349`

- [x] 增加 VM 行为测试：当前目录 obsolete=true → true；仅旧版本 obsolete=true → false；当前仍注册 → false；当前未注册 → true。
- [x] 运行 `node tools/checks/antigravity-target-check.js`，确认红灯为 `older version obsolete expected false, got true`。
- [x] 删除“本族任意版本”循环，仅保留 `j[selfDir] === true` 与注册表缺失兜底。
- [x] 运行目标检查和两个 `node --check`，要求退出码 0。

### Task 2: OneLS 代理等待桥 TDD

**Files:**
- Create: `runtime\OneLSAgentProxyBridge.cjs`
- Create: `tests\Test-OneLSAgentProxyBridge.cjs`

- [x] 先写测试夹具：临时扩展根、`.obsolete`、`origin-port.json`、本地假 `/origin/ping`。
- [x] 红灯覆盖：最高可用 Pro 版本、旧版 obsolete 不影响当前、当前 obsolete 被排除、动态端口成功、`self_file` 不匹配拒绝、无安装立即返回、超时官方回退。
- [x] 实现 `findLatestAgentPro()`、`getCandidatePorts()`、`waitForAgentProxy()`，禁止加载 `source.js`。
- [x] 运行 `node tests/Test-OneLSAgentProxyBridge.cjs`，要求全部 PASS 且测试服务器关闭。

### Task 3: main.js 共享 LS 启动门 TDD

**Files:**
- Modify: `scripts\StableMode.Core.psm1`
- Modify: `tests\Test-StableMode.ps1`
- Create: `tests\Test-OneLSMainBridge.ps1`

- [x] 构造最小 `Gde.t()` 锚点输入，红灯要求桥调用位于 `qZr()` 与 `TBa()` 之间。
- [x] 实现严格一次转换：动态导入 `resources/app/dao-one-ls-agent-pro.cjs`，等待结果；只有 endpoint 有效才替换 Cloud Code 参数。
- [x] 增加结构检查、幂等、Gemini 3.6 回退与未知结构 fail-closed 测试。
- [x] 运行 `Test-OneLSMainBridge.ps1`、`Test-StableMode.ps1`、`Test-Gemini36Mode.ps1`。

### Task 4: 桥文件事务部署

**Files:**
- Modify: `scripts\StableMode.Core.psm1`
- Modify: `StableBootstrap.ps1`
- Modify: `tests\Test-StableInstallIntegration.ps1`
- Modify: `tests\Test-AdaptiveBootstrapIntegration.ps1`

- [x] 红灯要求安装后桥文件存在且 SHA256 正确，失败回滚恢复原文件或删除原本不存在的新文件。
- [x] 把桥加入路径、候选、备份清单、原子替换、健康快速路径和恢复逻辑。
- [x] 运行两项集成测试，确认成功安装、故障回滚和重复安装幂等。

### Task 5: 实机部署与双冷启动闭环

**Files:**
- Runtime: `D:\Antigravity\resources\app\out\main.js`
- Runtime: `D:\Antigravity\resources\app\dao-one-ls-agent-pro.cjs`
- Runtime: `%APPDATA%\Antigravity\logs\<latest>`

- [x] 完全退出 Antigravity 后执行稳定模式安装，运行 JavaScript 语法检查和完整回归。
- [x] 第一次冷启动：验证 bridge 日志、LS Args 本地端点、模型回复、tape transformed=true。
- [x] 关闭后确认无 helper/测试孤儿进程，再第二次冷启动重复同一验收且不切账号。
- [x] 更新 README 和 `.agent/handoff.md`，明确直接 EXE 与稳定快捷方式行为、失败回退和升级自愈边界。
