# antigravity-old-compat-manager 项目规则

> 修改任何代码前必读。本文档定义项目边界、与插件的分工、编码规范和验证流程。

---

## 1. 项目定位与分工边界（最高优先级）

本项目是 **Antigravity IDE 兼容层管理器**，与 Antigravity-Injection 插件（zk-agent.dao-proxy-pro）配合使用。

### 1.1 本项目只做（兼容层）

| 功能 | 代码位置 | 说明 |
|---|---|---|
| 模型改写注入 | `runtime/Gemini37AgentProxyCompat.cjs` + `scripts/StableMode.Core.psm1` | 将旧协议占位模型 gemini-2.5-pro 改写为目标模型（当前 gemini-3.8-flash-high） |
| Bridge 修补部署 | `runtime/OneLSAgentProxyBridge.cjs` | 部署到 Antigravity app 目录，让后台规划器 LS 走本地代理 |
| 模型列表过滤 | `scripts/StableMode.Core.psm1` (Workbench) | 修改 workbench.js，白名单过滤模型列表，防止未知模型 ID 导致 IDE 前端死循环卡死 |
| 版本伪装 | product.json ideVersion=2.5.5 | 低版本 IDE 绕过版本检查 |
| 认证时序修复 | main.js 正则替换 | 修复认证启动时序 |
| 备份/恢复/自愈 | `scripts/StableMode.Core.psm1` | 应用前备份，失败自动回滚 |
| GUI 管理器 | `Antigravity稳定模式.ps1` + `StableBootstrap.ps1` | 可视化检测状态、应用模式、恢复备份 |

### 1.2 本项目绝对不做（注入层 → Antigravity-Injection 插件）

以下功能由插件独立负责，本项目不得实现：

- ❌ 提示词注入（System Prompt 替换/注入）
- ❌ 会话标题简体中文转换
- ❌ 文件上下文元信息注入
- ❌ 历史摘要 `<conversation_summaries>` 剔除
- ❌ 本地 HTTP 代理服务器
- ❌ 侧边栏 webview UI

### 1.3 红线：发布者必须一致

- **插件 publisher**：`zk-agent`
- **插件完整 ID**：`zk-agent.dao-proxy-pro`
- **本项目 Bridge AGENT_PRO_ID**：必须等于 `zk-agent.dao-proxy-pro`
- **本项目扩展目录前缀**：必须等于 `zk-agent.dao-proxy-pro-`

> ⚠️ **绝对禁止**：修改插件 publisher 时不同步修改本项目的 `runtime/OneLSAgentProxyBridge.cjs`（AGENT_PRO_ID）和 `scripts/StableMode.Core.psm1`（$prefix）。发布者不一致会导致 Bridge 匹配失败、模型改写注入找不到目标，Gemini 模型全部 503。

---

## 2. 模型升级规则（三层同步）

新增或升级模型时，必须三层同步修改：

| 层级 | 文件 | 修改点 |
|---|---|---|
| 路由层（Agent） | `runtime/Gemini37AgentProxyCompat.cjs` | `TARGET_MODEL = "目标 slug"` |
| 选择层（IDE） | `scripts/StableMode.Core.psm1` (Workbench) | 白名单标签、RECOMMENDED alias |
| 展示层（UI） | `scripts/StableMode.Core.psm1` + `Antigravity稳定模式.ps1` | GUI 单选框名称、Format-Status 显示名 |

**防卡死红线**：严禁在 Workbench 动态修改状态机或排序，否则导致 `CodeWindow` 渲染死循环崩溃。

**特征码子约束**：模型改写仅将旧协议生成的占位符 `gemini-2.5-pro` 改写为目标模型；Claude 及其他请求原样透传，不误伤。

---

## 3. 关键文件

| 文件 | 职责 |
|---|---|
| `scripts/StableMode.Core.psm1` | 核心模块：检测、注入、备份、回滚、Workbench 修改 |
| `runtime/OneLSAgentProxyBridge.cjs` | Bridge：AGENT_PRO_ID 硬编码，部署到 app 目录 |
| `runtime/Gemini37AgentProxyCompat.cjs` | 模型改写：SOURCE_MODEL/TARGET_MODEL |
| `Antigravity稳定模式.ps1` | GUI 入口 |
| `StableBootstrap.ps1` | 启动引导 |
| `tests/` | 集成测试和单元测试 |

---

## 4. 验证清单

修改完成后，按顺序执行：

1. **语法检查**：
   - `node --check runtime/OneLSAgentProxyBridge.cjs`
   - `node --check runtime/Gemini37AgentProxyCompat.cjs`
2. **发布者一致性检查**：
   - Bridge AGENT_PRO_ID === 插件 publisher.name
   - PSM1 $prefix === 插件 publisher.name + "-"
   - 测试文件 EXTENSION_ID === 插件 publisher.name
3. **集成测试**：
   - `pwsh -NoProfile -File tests/Test-CompatibilityInstallIntegration.ps1`
   - `node tests/Test-Gemini37AgentProxyCompat.cjs`
4. **真实端到端验证**：
   - 运行 GUI 点「检测状态」→「应用并启动」
   - 启动 IDE 发真实请求，确认代理日志收到目标模型且响应成功
   - 确认启动 180 秒内无 `CodeWindow unresponsive` 事件

---

## 5. 使用流程（用户视角）

### 5.1 什么时候需要执行本项目

| 场景 | 是否需要执行 | 原因 |
|---|---|---|
| 日常使用 | ❌ 不需要 | 已注入的代码持久化在 IDE 目录和插件目录 |
| 重新安装 IDE | ✅ 必须执行 | 本项目改的是 IDE 安装目录文件，重装后全部丢失 |
| 更新插件版本 | ✅ 必须执行 | 新插件的 source.js 不含模型改写代码，需要重新注入 |
| 用项目源码覆盖已安装 source.js | ✅ 必须执行 | 覆盖会冲掉模型改写注入 |
| 切换目标模型（如 3.8→4.0） | ✅ 必须执行 | 需要修改 TARGET_MODEL 后重新注入 |

### 5.2 执行步骤

1. 确保插件（zk-agent.dao-proxy-pro）已安装
2. 运行「一键安装稳定模式-反重力.cmd」或 GUI「应用并启动」
3. 等待注入完成（模型改写注入到插件 source.js + Bridge部署到 app 目录 + 版本伪装 + 模型过滤）
4. 启动 IDE

### 5.3 本项目注入的内容

| 注入目标 | 内容 | 丢失场景 |
|---|---|---|
| 插件 source.js | `require("./_ag-gemini37-compat.cjs")` + 改写 hook | 更新插件/覆盖 source.js |
| 插件 vendor 目录 | `_ag-gemini37-compat.cjs` 文件 | 更新插件 |
| IDE app 目录 | `dao-one-ls-agent-pro.cjs`（Bridge） | 重装 IDE |
| IDE product.json | ideVersion=2.5.5（版本伪装） | 重装 IDE |
| IDE workbench.js | 模型白名单过滤 + 模型偏好 | 重装 IDE/更新 IDE |

---

## 6. 相关项目

| 项目 | 路径 | 职责 |
|---|---|---|
| 本项目 | antigravity-old-compat-manager | 兼容层（模型改写/Bridge/过滤/伪装/备份） |
| 插件 | Antigravity-Injection | 注入层（提示词/标题汉化/文件上下文/摘要剔除/代理） |

两个项目必须同时运行才能获得完整功能：插件负责注入提示词和代理请求，本项目负责让模型可用。功能零重叠，互不影响。
