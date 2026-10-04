# antigravity-old-compat-manager 项目规则

> 修改任何代码前必读。本文档定义项目边界、与插件的分工、编码规范和验证流程。

---


## 0. extension.js 换行符硬性规则（最高优先级 · 血泪教训）

> **2026-09-10 事故复盘**：`E:\Antigravity\resources\app\extensions\antigravity\dist\extension.js` 被文本编辑器打开并保存后，换行符从 LF（`\n`）被自动转换成 CRLF（`\r\n`），全文仅 24 个换行符全部被转换，文件体积正好多 24 字节。该文件是 webpack 单文件打包，内部锚点匹配、source map 偏移、模块 ID 映射均依赖精确字节位置，CRLF 化后导致 `agentSessions` 服务注册失败，IDE 对话框点发送闪一下回弹、无法发送消息给模型。

### 0.1 绝对禁止

- ❌ **禁止用任何文本编辑器（VS Code / Notepad++ / 记事本 / Sublime 等）打开 `extension.js` 并按 Ctrl+S 保存**。查看可以，保存绝对不行。
- ❌ 禁止用 `Set-Content` / `Out-File` / `Add-Content` 等 PowerShell cmdlet 写入 `extension.js`（这些 cmdlet 会自动转换换行符）。
- ❌ 禁止在未归一化换行符的情况下对 `extension.js` 做字符串替换。

### 0.2 必须遵守

- ✅ 写入 `extension.js` **必须**使用 `[IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false))`，且写入前必须调用 `ConvertTo-LfLineEndings` 归一化为 LF。
- ✅ 本项目 `Write-Utf8Atomic` 函数已提供 `-ForceLF` 开关，写入 `extension.js` 时**必须**传 `-ForceLF`。
- ✅ `Test-RestartSafeExtensionContent` 和 `ConvertTo-RestartSafeExtensionContent` 函数入口已自动归一化 LF，新增同类函数必须遵循同样模式。
- ✅ 读取 `extension.js` 用 `Get-Content -Raw` 或 `[IO.File]::ReadAllText`，禁止用逐行读取后拼接（会改变换行符）。

### 0.3 验证

修改 `extension.js` 相关代码后，必须验证：
1. 产出的 `extension.js` 文件不包含 `\r\n`（可用 `Select-String` 或字节检查）。
2. 产出的 `extension.js` SHA256 与 `profiles\local-generated.json` 中对应模式的 `targetExtensionSha256` 一致。
3. IDE 启动后日志中无 `xoe depends on UNKNOWN service agentSessions` 错误。

---


## 0.1 模型版本策略（2026-09-11 定）

- **当前使用模型：3.8**；未来上 3.9 / 4.0 / 4.1+。
- **不需要为 3.7 及更低版本做特殊处理。** Gemini37 模式是历史兼容遗留，保留但不主动维护、不新增低版本适配逻辑。
- 新增高版本模型分两类（2026-10-04 厘清）：
  - **(A) Gemini 同系新档（3.9/4.0…）且旧 UI 能选到**：插件动态映射从请求 URL 提取模型名改写 LS 占位符，自动适配，无需改代码。
  - **(B) 旧 LS 完全没有的全新模型（如 Claude 5.5 六档）**：旧下拉根本无此项，必须走「新模型放行」叠加层——前端 `model-unlock/` 注入下拉项 + zk `/__agtarget` 旁路按 uid 改道（见第 2.5 节），改一张映射表即可；后端通用透传、零协议转换。
- 仅当需要过滤/隐藏/推荐某个特定模型时，才调整基础稳定层（StableMode.Core）的 Workbench 白名单。

### 0.1.1 启动性能硬规则（2026-09-11 定，血泪教训）

- **健康态必须跳过补丁重打。** 当 `Find-TargetProfile` 匹配到当前版本目标哈希（`$targetProfile -ne $null`）时，说明 IDE 文件已是正确补丁状态，**禁止**因任何字符串标记（如 `_agGemini37`）强制把 `$targetProfile` 置 null 重打补丁。
- 仅当 `$targetProfile -eq $null`（重装/更新 IDE 后哈希不匹配）时，才允许执行标记检查和完整补丁流程。
- 违反此规则会导致每次启动多花 ~4 秒强制重打补丁。
- 当前桌面双击到 IDE 窗口出现：**3.7 秒**（2026-09-11 优化后，最初 20.8 秒）。

---


## 1. 项目定位与分工边界（最高优先级）

本项目是 **Antigravity IDE 兼容层管理器**，与 Antigravity-Injection 插件（zk-agent.zk-proxy-pro）配合使用。

### 1.1 本项目只做（兼容层）

| 功能 | 代码位置 | 说明 |
|---|---|---|
| Bridge 修补部署 | `runtime/OneLSAgentProxyBridge.cjs` | 部署到 Antigravity app 目录，让后台规划器 LS 走本地代理 |
| 模型列表过滤 | `scripts/StableMode.Core.psm1` (Workbench) | 修改 workbench.js，白名单过滤模型列表，防止未知模型 ID 导致 IDE 前端死循环卡死 |
| 新模型前端放行 | `model-unlock/patch-workbench.mjs`（一键 `放行Claude六档.ps1`） | 在 workbench 追加放行下拉项（借 modelAlias:8 外壳）+ 选中旁路上报；只加 UI 项与上报，**不改写网络请求体**（body 改写在插件） |
| 版本伪装 | product.json ideVersion=2.5.5 | 低版本 IDE 绕过版本检查 |
| 认证时序修复 | main.js 正则替换 | 修复认证启动时序 |
| 备份/恢复/自愈 | `scripts/StableMode.Core.psm1` | 应用前备份，失败自动回滚 |
| GUI 管理器 | `Antigravity稳定模式.ps1` + `StableBootstrap.ps1` | 可视化检测状态、应用模式、恢复备份 |

> 注：模型改写/动态映射已于 v9.9.524 从本项目移入插件源码（`Antigravity-Injection/plugins/zk-proxy-pro/vendor/bundled-origin/_ag-gemini37-compat.cjs`）。本项目不再负责模型改写注入。`runtime/Gemini37AgentProxyCompat.cjs` 保留为历史参考，不再使用。

### 1.2 本项目绝对不做（注入层 → Antigravity-Injection 插件）

以下功能由插件独立负责，本项目不得实现：

- ❌ 提示词注入（System Prompt 替换/注入）
- ❌ 会话标题简体中文转换
- ❌ 文件上下文元信息注入
- ❌ 历史摘要 `<conversation_summaries>` 剔除
- ❌ 模型改写 / 动态映射（v9.9.524+ 已移入插件）
- ❌ 本地 HTTP 代理服务器
- ❌ 侧边栏 webview UI

### 1.3 红线：发布者必须一致

- **插件 publisher**：`zk-agent`
- **插件完整 ID**：`zk-agent.zk-proxy-pro`
- **本项目 Bridge AGENT_PRO_ID**：必须等于 `zk-agent.zk-proxy-pro`
- **本项目扩展目录前缀**：必须等于 `zk-agent.zk-proxy-pro-`

> ⚠️ **绝对禁止**：修改插件 publisher 时不同步修改本项目的 `runtime/OneLSAgentProxyBridge.cjs`（AGENT_PRO_ID）和 `scripts/StableMode.Core.psm1`（$prefix）。发布者不一致会导致 Bridge 匹配失败，LS 不走本地代理。

---

## 2. 模型升级规则

模型改写/动态映射已移入插件（v9.9.524+），采用**动态映射**：从请求 URL `/v1beta/models/{model}:generateContent` 提取用户实际选择的模型名，改写 LS 占位符 `gemini-2.5-pro`。

**官方发布新模型（3.9/4.0/4.1）时**：
- 账号登录后官方本身返回全量模型（含新模型，免费/VIP 皆然）；插件模型解锁 v9.9.528 起默认禁用，不靠它解锁
- 插件动态映射会自动将占位符改写成用户选择的新模型（从 URL 提取），**插件侧不需要改任何代码**
- 仅当本项目要过滤/推荐/隐藏某个新模型时，才调整下方 Workbench 白名单
- 不需要重新执行本项目（除非 IDE 重装/更新覆盖了 app 目录）

**本项目需要关注的模型相关变更**：
| 层级 | 文件 | 修改点 |
|---|---|---|
| 选择层（IDE） | `scripts/StableMode.Core.psm1` (Workbench) | 白名单标签、RECOMMENDED alias（如果需要过滤/推荐特定模型） |
| 展示层（UI） | `scripts/StableMode.Core.psm1` + `Antigravity稳定模式.ps1` | GUI 单选框名称、Format-Status 显示名 |

**防卡死红线**：严禁在 Workbench 动态修改状态机或排序，否则导致 `CodeWindow` 渲染死循环崩溃。

---

## 2.5 新模型放行叠加层（2026-10-04 定，model-unlock + zk 旁路）

针对旧 LS 完全没有的全新模型（Claude 5.5 六档；未来 Claude 新版同理）。完整原理与操作见 `SOP-新模型放行.md`、`model-unlock/README.md`。

**分工（不得越界）**
- 前端（本项目 `model-unlock/`）：向 workbench 注入下拉/可见列表/store/回显/选择回调共 5 处；合成项借 `modelAlias:8`(RECOMMENDED，唯一能正常发 v1internal 的外壳；alias:7 会挂起)、带 `__agUid`，选中即 `fetch http://127.0.0.1:8937/__agtarget?uid=...&label=...` 上报。**只加 UI 项与上报，不改写请求体、不碰协议。**
- 后端（Antigravity-Injection 插件）：`/__agtarget` 落盘 `_agcap/_ag-selected.json`；`_ag-gemini37-compat.cjs` 按 `URL 模型名 > 旁路(bySid→last，120 分钟新鲜窗口) > 默认 gemini-3.8-flash-high` 覆盖主对话占位符 `gemini-2.5-pro` 的 body.model。模型 body 改写**只能在插件源码改并 build vsix**，禁止直接手改运行态部署副本（部署副本只允许用 vsix 文件级覆盖）。

**前端注入红线（违反会导致 IDE 卡死）**
- 只能用“表达式内 `.concat(内联字面量)`”或函数块体 `{}` 内独立语句；禁止在逗号连接的 let/const 声明链中间插以分号结尾的独立语句。
- 启动不强选合成模型：可见列表 dutE、store vKc 必须**条件 concat**（官方 clientModelConfigs 非空才追加），默认选中永远由官方配置驱动（=默认 3.8）；合成项一律 concat 在官方项之后。
- 不动 workbench 状态机/排序；5 个锚点各自计数必须恰为 1，否则 `ANCHOR CHECK FAILED` 不写入；注入后必须 `node --check`，失败回滚干净基线。

**工具链入库红线**
- 正式工具与干净基线放 `model-unlock/`（随 git 入库）：`patch-workbench.mjs`、`verify-workbench.mjs`、`list-official-uids.mjs`、`fetchAvailableModels.json`、`assets/prod-wb-pre-claude.js`（workbench 干净基线，补丁幂等还原源，必须入库、勿删）。
- **例外（密钥红线）**：`assets/prod-main-pre-tpe.js`（main.js 基线）含 IDE 官方内置 OAuth client_id/secret（GOCSPX），被 .gitignore 排除、**不入公开仓库**，仅存本机/私有备份；前端补丁不依赖它，仅手动回滚 main.js 时用。任何含 OAuth secret / API 私钥的文件都不得推入公开仓库（GitHub Push Protection 会拦截）。
- `evidence/`、`backups/` 已被 .gitignore 忽略，只放一次性取证 / 本地备份，**不得**让一键脚本或 SOP 的正式恢复链路依赖其中文件。
- 本地旁路端口 8937 按 Windows 用户名 FNV 派生（Administrator=8937），不是源码常量；换用户/机器需同步改 patch 里的端口。
- 加新模型只改 `model-unlock/patch-workbench.mjs` 顶部 `MODELS` 一张表；uid 以官方 `fetchAvailableModels` 快照逐字为准（`-medium` 不是 `-med`，写错 404）。

**版本号约定**
- 当前插件 `9.9.529`；本轮在同版本内改源码并重新 build 同名 vsix、文件级覆盖部署（本地锁死补丁工作流，未 bump）。
- 要规范化发布时，跑 Antigravity-Injection 的 `node scripts/bump-version.mjs` 升版本（如 9.9.530）→ build → 安装为新扩展目录（旧目录进 .obsolete）；不 bump 则靠 `backups/` 与 target-check 区分本地修订。

---

## 3. 关键文件

| 文件 | 职责 |
|---|---|
| `scripts/StableMode.Core.psm1` | 核心模块：检测、注入、备份、回滚、Workbench 修改 |
| `runtime/OneLSAgentProxyBridge.cjs` | Bridge：AGENT_PRO_ID 硬编码，部署到 app 目录 |
| `Antigravity稳定模式.ps1` | GUI 入口 |
| `StableBootstrap.ps1` | 启动引导 |
| `tests/` | 集成测试和单元测试 |
| `model-unlock/` | 新模型前端放行工具链（补丁/只读校验/官方 uid 快照/干净基线），随 git 入库 |
| `放行Claude六档.ps1` | 一键关闭 D:\Antigravity 进程并应用 model-unlock 前端补丁（`-ForceKill`） |
| `SOP-新模型放行.md` | 新模型放行权威操作手册（原理/唯一映射表/zk 部署/回滚/边界） |

> 注：`runtime/Gemini37AgentProxyCompat.cjs` 已移入插件（v9.9.524+），本项目保留为历史参考，不再使用。

---

## 4. 验证清单

修改完成后，按顺序执行：

1. **语法检查**：
   - `node --check runtime/OneLSAgentProxyBridge.cjs`
2. **发布者一致性检查**：
   - Bridge AGENT_PRO_ID === 插件 publisher.name
   - PSM1 $prefix === 插件 publisher.name + "-"
   - 测试文件 EXTENSION_ID === 插件 publisher.name
3. **集成测试**：
   - `pwsh -NoProfile -File tests/Test-CompatibilityInstallIntegration.ps1`
4. **真实端到端验证**：
   - 运行 GUI 点「检测状态」→「应用并启动」
   - 启动 IDE 发真实请求，确认 Bridge 部署成功且代理正常
   - 确认启动 180 秒内无 `CodeWindow unresponsive` 事件

---

## 5. 使用流程（用户视角）

### 5.1 什么时候需要执行本项目

| 场景 | 是否需要执行 | 原因 |
|---|---|---|
| 日常使用 | ❌ 不需要 | 已注入的代码持久化在 IDE 目录 |
| 重新安装 IDE | ✅ 必须执行 | 本项目改的是 IDE 安装目录文件（Bridge/版本伪装/模型过滤），重装后全部丢失 |
| 更新插件版本 | ❌ 不需要 | 模型改写/动态映射已在插件内（v9.9.524+），更新插件后自动生效 |
| 切换目标模型（如 3.8→4.0） | ❌ 不需要 | 动态映射自动适配，不需要改代码 |
| IDE 版本更新 | ✅ 建议执行 | IDE 更新可能覆盖 workbench.js/product.json，需要重新应用 |

### 5.2 执行步骤

1. 确保插件（zk-agent.zk-proxy-pro）已安装
2. 运行「一键安装稳定模式-反重力.cmd」或 GUI「应用并启动」
3. 等待注入完成（Bridge部署到 app 目录 + 版本伪装 + 模型过滤）
4. 启动 IDE

### 5.3 本项目注入的内容

| 注入目标 | 内容 | 丢失场景 |
|---|---|---|
| IDE app 目录 | `dao-one-ls-agent-pro.cjs`（Bridge） | 重装 IDE/更新 IDE |
| IDE product.json | ideVersion=2.5.5（版本伪装） | 重装 IDE/更新 IDE |
| IDE workbench.js | 模型白名单过滤 + 模型偏好 | 重装 IDE/更新 IDE |

> 注：模型改写/动态映射已在插件内（v9.9.524+），不再由本项目注入。

---

## 6. 相关项目

| 项目 | 路径 | 职责 |
|---|---|---|
| 本项目 | antigravity-old-compat-manager | 兼容层（Bridge/过滤/伪装/备份） |
| 插件 | Antigravity-Injection | 注入层 + 模型改写动态映射（提示词/标题汉化/文件上下文/摘要剔除/流式结束保险/模型改写/代理；模型解锁默认禁用、保留手动恢复） |

两个项目必须同时运行才能获得完整功能：插件负责注入提示词和模型改写，本项目负责让 LS 走本地代理（Bridge）和低版本 IDE 兼容。功能零重叠，互不影响。
