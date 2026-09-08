# Gemini 3.7 模式踩坑复盘与修复全景记录

本文档详细记录了在 **Antigravity 旧版兼容管理器** 中支持并优化 **Gemini 3.7 模式** 过程中的用户目标、所踩坑点深度剖析、最小根因修复方案、验证矩阵及项目规则固化。

---

## 一、 用户核心目标

1. **模式顺畅应用**：在旧版兼容管理器中选择 `Gemini 3.7` 模式时，能一键成功应用并启动 IDE，彻底解决“应用失败 / 退出码 1”的阻断报错；
2. **首次进入直接响应**：打开 IDE 后，首次直接选 **Gemini 3.7 High** 提问即可立即正常收到回复，无需先切换到其他模型对话“垫刀”再切回；
3. **选择状态智能持久化**：
   - 选了 Claude，重启后依然恢复为 Claude；
   - 选了 Gemini 3.6，重启后依然恢复为 3.6；
   - 选了 Gemini 3.7，重启后依然恢复为 3.7；
   - 仅在**没有任何历史选择**时，以 Gemini 3.7 High 作为默认兜底；绝不能在每次重启时被启动脚本暴力覆盖回 3.6。
4. **硬约束**：Gemini 3.7 / 3.6 / Claude 既有路由零回归，不扩大 allowlist，无未启动残留服务。

---

## 二、 踩坑全景图与根因深度剖析

在实现与部署过程中，共遭遇并攻克了 **5 个典型的硬核工程阻断点**：

### 🛑 坑 1：僵尸进程 & 进程路径空指针误阻断（导致“应用失败”）
- **现象**：点击“应用并启动”提示 Gemini 3.7 模式应用失败，被 `Assert-NoAntigravityProcesses` 拦截。
- **根因剖析**：
  - Windows 环境下，被杀死的旧 Antigravity 进程有时会处于 0 线程、0 句柄的“僵尸”状态；
  - `Get-Process.Path` 无法获取到该进程的安装路径（返回 `$null`），导致定向停止逻辑无法识别并清理它；
  - 随后的安装前置断言因检测到同名进程而误判为“有活跃进程占用”，直接阻断安装。
- **修复措施**：
  - 在 `scripts/StableMode.Core.psm1` 中引入 `Get-ProcessPathSnapshot`，通过 `Get-CimInstance Win32_Process` 补充 `ExecutablePath` 查询；
  - 增加过滤规则：线程数为 0 的对象视为已退出，不再作为活跃阻断。

---

### 🛑 坑 2：CRLF vs LF 换行符严格比对崩溃（导致“补丁不完整”）
- **现象**：Agent Pro 补丁校验失败，报错“补丁不完整，拒绝写入”。
- **根因剖析**：
  - 扩展目录中 Agent Pro 的 `source.js` 文件被统一格式化为 Linux 的 `\n` (LF) 换行；
  - PowerShell 脚本在 Windows 环境下拼接补丁模板时默认带有 `\r\n` (CRLF)；
  - 纯全文本字符串精确匹配因换行符差异全部失效。
- **修复措施**：
  - 在 `scripts/StableMode.Core.psm1` 中对 Agent Pro 补丁结构校验与回退逻辑进行正则化升级，全面兼容 CRLF 与 LF 两种换行格式。

---

### 🛑 坑 3：Electron ESM 模块被 Node 语法检查误杀（导致“语法错误”）
- **现象**：应用时抛出报错：`main.js JavaScript 语法检查失败: (node) Cannot use import statement outside a module`。
- **根因剖析**：
  - Electron 运行环境的 `main.js` 内部包含了顶层 `import` 语句（ES Module 规范）；
  - `Test-JavaScriptSyntax` 在校验 JavaScript 语法时，将临时文件命名为 `.js`；
  - Node.js 18 默认将 `.js` 视为 CommonJS 解析，遇到顶层 `import` 直接判定为语法错误并退出。
- **修复措施**：
  - 改造 `Test-JavaScriptSyntax`：自适应检测代码中是否存在顶层 `import` / `export`，若存在则自动将临时文件扩展名切换为 `.mjs`，既保留了严格的语法拦截，又杜绝了误杀。

---

### 🛑 坑 4：alias 8 状态被丢弃 & 启动强制重置 3.6（导致“重启丢选择、首次发不出”）
- **现象**：每次重启 IDE 选中的总是 Gemini 3.6；首次选 3.7 提问无响应，必须先切其他模型。
- **根因剖析**：
  - Gemini 3.6 使用的是数字 model ID（1264、1265），而 3.7 在旧协议中使用的是别名 `alias 8`；
  - 旧版 Workbench 的 `qb` 仅对数字 ID 做了持久化，遇到非 model choice（如别名）直接 `return` 丢弃；
  - 启动逻辑中的覆盖安全逻辑主动将选择重置回 3.6，导致 3.7 选择从未被持久化，首次请求也没有对应的模型映射。
- **修复措施**：
  - 为 3.7 模式增加独立的本地存储键 `_agGemini37PreferenceKey`，当选中 alias 8 时单独持久化；
  - 在启动恢复时优先恢复 `alias 8`，无历史选择时以 3.7 High 兜底；
  - 保持 Agent Pro 首次请求将 `gemini-2.5-pro` 映射为 `gemini-3.7-flash-high` 的改写逻辑。

---

### 🛑 坑 5：3.6 与 3.7 共享 Replacement 互相污染
- **现象**：直接修改 Workbench 共享替换块后，导致纯 3.6 模式逻辑异常，升级旧版本部署时报错。
- **根因剖析**：
  - 违背了单一职责与状态隔离原则，让 3.6 和 3.7 共用了同一套 Workbench replacement；
  - 缺乏对已部署历史结构（如 `gemini37-combined-v2`）的迁移路径。
- **修复措施**：
  - 将 Gemini 3.7 的 Workbench Replacement（`Gemini37QbReplacement` / `Gemini37DbReplacement`）与 3.6 完全分离；
  - 在 `ConvertFrom-Gemini37WorkbenchContent` 和 `ConvertTo-Gemini37WorkbenchContent` 中补充上一代结构的精确迁移与回退支持。

---

## 三、 修复闭环状态与验证矩阵

| 目标与功能项 | 修复方案 | 验证结果 |
| :--- | :--- | :---: |
| **应用安装阻断** | CIM 路径快照 + 0 线程僵尸进程过滤 | ✅ **通过** (`Test-ScopedProcessShutdown.ps1`) |
| **换行符兼容** | LF / CRLF 通用正则匹配 | ✅ **通过** (`Test-Gemini37AgentProPatch.ps1`) |
| **ESM 语法检查** | 智能 `.mjs` 扩展名分流 | ✅ **通过** (`Test-JavaScriptSyntax`) |
| **首次 3.7 发送响应** | 请求级精准映射 `gemini-3.7-flash-high` | ✅ **通过** (`Test-Gemini37AgentProxyCompat.cjs`) |
| **跨重启持久化** | 独立 `_agGemini37PreferenceKey` + 智能恢复矩阵 | ✅ **通过** (`Test-Gemini37Mode.ps1`) |
| **历史升级与隔离** | 独立 Replacement + 上一代结构兼容迁移 | ✅ **通过** (`Test-Gemini36Mode.ps1`) |
| **安装静态合规** | 16 项结构与哈希全量校验 | ✅ **通过** (`Passed = True`) |

---

## 四、 项目规则固化（防后续 Agent 改坏）

已在 `.agent/rules/README.md` 中强制写入以下门禁规则：

1. **独立 Replacement 铁律**：Gemini 3.6 与 Gemini 3.7 必须使用各自独立的 Workbench replacement；禁止为单一模式修改共享 replacement 避免污染其他模式；
2. **状态分离铁律**：模型目录、当前 choice、默认模型、最后选择持久化、上游路由是独立状态，必须分别处理与验证；
3. **重启恢复矩阵**：修改任何持久化逻辑后，必须验证 `Claude -> 重启`、`Gemini 3.6 -> 重启`、`Gemini 3.7 -> 重启` 全矩阵均能准确恢复；
4. **历史升级迁移路径**：结构升级必须提供上一已发布版本的精确回退与迁移逻辑，禁止仅验证全新安装；
5. **进程诊断与僵尸过滤**：严禁仅依赖 `Get-Process.Path`，必须结合 CIM 进程快照且过滤 0 线程对象；
6. **换行符与语法校验自适应**：补丁结构必须通吃 CRLF/LF，JavaScript 语法校验必须自适应顶层 ESM 切换 `.mjs`。

---

## 五、 相关代码与配置索引

- **核心逻辑**：`scripts/StableMode.Core.psm1`
- **代理映射**：`runtime/Gemini37AgentProxyCompat.cjs`
- **项目规则**：`.agent/rules/README.md`
- **接续文档**：`.agent/handoff.md`
- **测试套件**：
  - `tests/Test-Gemini37Mode.ps1`
  - `tests/Test-Gemini36Mode.ps1`
  - `tests/Test-Gemini37AgentProPatch.ps1`
  - `tests/Test-ScopedProcessShutdown.ps1`
  - `tests/Test-Gemini37AgentProxyCompat.cjs`

---

## 六、 2026-09-08 补充：Gemini 3.8 Flash Fast 版推理强度被压为 Low（0.25）→ 提升至 High

### 🛑 坑 6：Fast 版模型 thinkingBudget 被 LS 固定为 1024（Low），无法从 UI 切换档位

- **现象**：Gemini 3.8 Flash (High) 条目带 Fast 徽标 + "Limited time" 气泡，模型两次一致自报 `EFFORT LEVEL: 0.25`（Low）。用户要求推理强度为 High（1.0 满载长链思考）。
- **排查过程**：
  1. IDE 全部源码（main.js / workbench.desktop.main.js / jetskiAgent/main.js）grep `thinkingBudget/thinkingConfig/reasoningEffort/effortLevel` **零命中**——客户端不显式设置思考参数
  2. 插件外接 api 适配层的 `thinkingBudget→budget_tokens` 映射只服务外部渠道（deepseek/claude），官方 Gemini 请求不过该层
  3. 官方请求实际为 `POST /v1internal:streamGenerateContent?alt=sse`（host=daily-cloudcode-pa.googleapis.com，Antigravity 私有端点）
  4. 在 compat 层注入诊断 dump，抓到真实请求体结构：`request.generationConfig.thinkingConfig.thinkingBudget = 1024`（主对话，顶层 model 为 LS 占位符 `gemini-2.5-pro`）；另一条 `gemini-3.1-flash-lite`（标题生成）为 0
  5. **关键发现**：thinkingBudget 是 token 数（1024=Low），不是 0~1 比例；模型把 1024 token 预算表述为 0.25 档位
- **根因剖析**：
  - Antigravity 私有端点 `/v1internal` 为**旧版 schema**，只认 `thinkingConfig.thinkingBudget`（token 数），**不认 Gemini 3 新字段 `thinkingLevel`**（实测加了会 400 INVALID_ARGUMENT：`Unknown name "thinkingLevel" at 'request.generation_config'`）
  - LS 给 Fast 版模型固定写入 1024（Low 档），覆盖了 Gemini 3 默认的 high 动态思考
  - Fast 是模型条目自带属性，非可关开关（用户确认"fast 没法关闭，是 ide 模型自带的"）
  - 服务器唯一可用 Gemini ID 为 `gemini-3.8-flash-high`，不存在 `gemini-3.8-pro`
- **修复措施**：
  - 在插件 `_ag-gemini37-compat.cjs` 的 `rewriteRequestBody` 中新增 `_agLiftThinking(request)`
  - 对主对话请求（顶层 model === LS 占位符 `gemini-2.5-pro`），将 `request.generationConfig.thinkingConfig.thinkingBudget` 从 1024 提升为 **-1**
  - 官方定义 `thinkingBudget=-1` 为动态思考（模型按任务复杂度自行决定，等同 High 满载），且字段为端点认识的旧版字段，不会 400
  - 仅改主对话，不动 lite/标题摘要等附属请求（避免副作用）
- **验证结果**：重载窗口后模型自报推理强度 high/动态，复杂任务思考深度显著提升；请求无 400。
- **影响范围**：仅影响经插件代理的 Gemini 主对话请求（LS 占位符模型），外接 API 渠道、Claude、非 Gemini 请求不受影响；thinkingBudget 改动仅作用于请求体转发，不修改模型列表、提示词注入或其他代理逻辑。
- **回滚方案**：还原 `_ag-gemini37-compat.cjs` 至 v9.9.528 版（删除 `_agLiftThinking` 调用），重载窗口即可恢复 1024(Low)。
- **关联提交**：插件 v9.9.529（`_ag-gemini37-compat.cjs` + package.json 版本号 + CHANGELOG/RELEASE_NOTES）；兼容管理器 StableMode.Core.psm1 v13 检测修复（同期部署，解决插件 9.9.528 内置 Gemini 路由改写被误判为"打了一半补丁"的问题）。
