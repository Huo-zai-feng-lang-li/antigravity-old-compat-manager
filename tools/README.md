# Antigravity Subagent MCP 服务说明书

> 专为反重力 IDE（Antigravity）打造的独立上下文代码审查与安全审计 MCP 引擎。

---

## 1. 架构定位

在复杂的企业级项目或深度通道重构任务中，主代理容易受到单会话上下文过长、注意力分散以及“自己的代码自己看很难发现盲区”的局限。

本工具为反重力 IDE 提供了**第二大脑（独立审校子代理）**：
- **完全独立的执行上下文**：不受主会话上文干扰；
- **全权限物理源码装配**：自动从磁盘读取目标源文件并打上行号，无缝组装至审计 Prompt；
- **独立 API 直连**：直连用户独立大模型 API 端点，支持提取完整的深度推理思考链（`reasoning_content`）；
- **结论置顶交付**：将最关键的结论、审查得分（1-10分）与问题清单排在最前，便于主代理快速消化并闭环修复。

---

## 2. 工具定义与协议规范

### 工具名称：`invoke_subagent`

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `task` | `string` | **是** | 审查任务的具体要求、改动说明、架构背景及关注重点 |
| `files` | `string[]` | 否 | 需要子代理从物理磁盘自动读取的源文件绝对路径列表（支持批量装配） |
| `agent_type` | `string` | 否 | 兼容旧版参数保留，默认留空即可 |
| `timeout` | `number` | 否 | API 调用超时时间（毫秒，默认 120,000 即 2 分钟） |

---

## 3. 安装与配置

### 3.1 IDE MCP 配置

打开全局 MCP 配置文件：
`%USERPROFILE%\.gemini\antigravity\mcp_config.json`（或项目级 `.vscode/mcp.json`），配置如下：

```json
{
  "mcpServers": {
    "subagent": {
      "command": "node",
      "args": [
        "D:\\Desktop\\Super-File\\AI-IDE\\AI\\反重力\\antigravity-old-compat-manager\\tools\\antigravity-subagent-mcp.js"
      ],
      "env": {
        "SUBAGENT_BASE_URL": "https://apihub.agnes-ai.com/v1",
        "SUBAGENT_API_KEY": "sk-your-api-key-here",
        "SUBAGENT_MODEL": "agnes-2.5-pro-beta"
      }
    }
  }
}
```

> **安全约定**：
> - 源码中严禁硬编码 API Key，必须通过环境变量 `SUBAGENT_API_KEY` 注入。
> - 未配置时会通过友好错误提示指引用户在 `mcp_config.json` 中配置。

---

## 4. 主代理与子代理双代理互检闭环机制

根据系统级研发规范，在【深度通道】（架构重构、新建模块、复杂Bug排查、跨层链路修改）任务中，强制执行**双代理互检闭环**：

```
[主代理] 完成核心业务代码编写与基础自检
   │
   ▼
[主代理] 调用 invoke_subagent(task, files: [待审文件物理路径])
   │
   ▼
[子代理 MCP] 自动读取磁盘文件并编号装配 -> 独立 API 深度推理审计
   │
   ▼
[子代理] 输出：审查结论 (1-10分) + 致命Bug + 潜在隐患 + 修复方案
   │
   ▼
[主代理] 深度复核子代理意见，逐项落实闭环修复
   │
   ▼
[主代理] 执行端到端构建/测试并最终交付用户
```

---

## 5. 本地联调与实战测试

仓库内附带了自动化测评套件：
- 测试靶场：`tools/subagent-real-test/`（包含类型契约、Pinia Store、Vue SFC 跨层预埋靶场）
- 测评报告：`tools/subagent-real-test/audit-result.md`（记录了子代理排查 100% 致命 Bug 的真实取证记录）
