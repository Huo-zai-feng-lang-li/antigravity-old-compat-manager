# antigravity-old-compat-manager

[GitHub 仓库](https://github.com/Huo-zai-feng-lang-li/antigravity-old-compat-manager)

## 项目定位

Antigravity IDE **兼容层管理器**，与 [Antigravity-Injection](https://github.com/Huo-zai-feng-lang-li/Antigravity-Injection) 插件（zk-agent.zk-proxy-pro）配合使用。

- **本项目（兼容层 & 审查工具箱）**：Bridge 修补部署、模型列表过滤、版本伪装、认证时序修复、备份恢复、**独立 API 驱动代码审查子代理 MCP（Subagent MCP）**
- **插件（注入层）**：提示词注入、会话标题简体中文、文件上下文元信息、历史摘要剔除、模型解锁（全量模型目录，v9.9.528+ 默认禁用、保留手动恢复）、流式响应结束保险、模型改写/动态映射、**推理强度 High 提升（v9.9.529+：主对话 thinkingBudget 1024→-1）**、**Claude 5.5 六档与未来新模型放行（v9.9.529+：前端 model-unlock 注入 + zk `/__agtarget` 选择旁路，默认 Gemini 3.8）**、本地 HTTP 代理

两个项目功能零重叠，必须同时运行才能获得完整功能。

> 注：模型改写/动态映射已于 v9.9.524 从本项目移入插件源码。本项目不再负责模型改写注入。

## 当前可用交付

- 推荐双击桌面的 `Antigravity 稳定版.lnk`；健康时无黑窗快速启动，IDE 更新后自动检查并在结构兼容时自愈。
- 提供两种可持久模式：
  - `Stable`：仅保留 Claude
  - `Gemini37`：保留 Claude + Gemini 3.8 Flash (High)
- 两种模式都排除 Low、GPT 及未来未知模型，防止未知模型 ID 导致 IDE 前端死循环卡死。
- 发布者统一为 `zk-agent`，与插件完全匹配。
- 模型改写/动态映射已移入插件（v9.9.524+），本项目不再负责。

### 新模型放行（Claude 5.5 六档 / 未来 Gemini·Claude）

- 在上述基础稳定层之上，另有一层“新模型放行”（2026-10-04 起）：模型下拉默认 **Gemini 3.8 Flash (High)**，并放行 **Claude Opus/Sonnet 5.5 各 High/Medium/Low 六档**；启动不强选合成模型、IDE 不卡死。
- 前端工具链在随仓库入库的 **`model-unlock/`**（含补丁生成器、只读校验、官方 uid 快照与干净基线），一键脚本 **`放行Claude六档.ps1 -ForceKill`**；后端改道在 zk 插件的 `/__agtarget` 选择旁路。
- 以后官方发布新模型（如 Gemini 3.9/4.0、Claude 新版）通常只需改 `model-unlock/patch-workbench.mjs` 顶部一张映射表，后端零改动；完整步骤见 **`SOP-新模型放行.md`**。

### 子代理独立代码审查 MCP（Subagent Reviewer v2.0）

- 位于 **`tools/antigravity-subagent-mcp.js`**，专为反重力 IDE 打造的独立上下文代码审查与安全审计服务。
- **独立 API 驱动引擎**：告别外部 CLI 进程依赖，直接对接独立大模型 API 端点，支持深度推理链（`reasoning_content`）完整提取与格式化输出。
- **物理磁盘多文件装配**：原生支持 `files` 绝对路径数组，自动读取本地源码并注入带行号的代码上下文，告别手动复制代码的繁琐。
- **双代理互检架构**：主代理编写核心代码后，调用 `invoke_subagent` 在全新干净上下文进行独立代码审计，结论置顶前置，由主代理复查闭环后方可交付。
- **环境隔离脱敏**：敏感 API Key 与端点全量收口于 IDE 的 `mcp_config.json` 环境变量，实现源码级安全防泄漏。

## 项目导航

- **子代理审查引擎说明**：`tools/README.md`
- **新模型放行 SOP（Claude 六档 / 未来模型）**：`SOP-新模型放行.md`
- **前端放行工具链**：`model-unlock/README.md`
- 重装到启动全流程：`Antigravity重装到启动使用流程.md`
- 基础稳定层使用说明：`README-稳定模式.md`
- 项目规则：`.agents/rules/README.md`
- 跨会话续接：`.agents/handoff.md`
- 历史取证笔记：`notes.md`

## 获取项目

```powershell
git clone https://github.com/Huo-zai-feng-lang-li/antigravity-old-compat-manager.git
cd antigravity-old-compat-manager
```
