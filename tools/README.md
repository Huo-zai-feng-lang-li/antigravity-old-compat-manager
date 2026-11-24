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

### 工具 1：`invoke_subagent` (单任务 / 兼容并发)

派发任务给独立且完全干净的无状态子代理执行（API 驱动）。专用于代码审查（Code Review）、安全审计、逻辑核验或复杂方案推演。默认使用 **max 顶级思维链推理**，优先 **3.0 (agnes-3.0-flash)**，超时自动无缝降级 **2.5 (agnes-2.5-flash)**。

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `user_goal` | `string` | 推荐必填 | 用户原始目标与核心业务痛点背景（解决什么问题、防御什么场景） |
| `solution_summary` | `string` | 推荐必填 | 主代理修复逻辑与架构改动说明（采用了何种方案、处理了哪些根因） |
| `review_focus` | `string` | 否 | 审查重点关注的边界、竞态、死锁或疑虑点 |
| `task` | `string` | 条件必填 | 自包含综合指令（未提供 user_goal 时必填） |
| `files` | `string[]` | 否 | 需子代理自动读取的源文件绝对路径列表（自动编号装配） |
| `tasks` | `object[]` | 否 | **并发模式**：若传入对象数组，自动并发派出多个子代理并汇总报告 |
| `model` | `string` | 否 | 默认优先 `agnes-3.0-flash`，超时自动降级 `agnes-2.5-flash` |
| `reasoning_effort`| `string` | 否 | 默认锁定 `'max'`（顶级深度思考推理） |
| `timeout` | `number` | 否 | 请求超时秒数（默认 120 秒） |

---

### 工具 2：`invoke_subagents_parallel` (显式并发子代理群)

一次并发派发多个独立的无状态子代理并行执行。各子代理使用 **max 顶级推理强度**，在独立大模型端点并发执行，互不阻塞，并自动汇总各子代理独立审查结论。

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `tasks` | `object[]` | **是** | 并发子代理任务对象列表（包含 `name`, `user_goal`, `solution_summary`, `review_focus`, `task`, `files` 等） |
| `concurrency` | `number` | 否 | 最大并发数（默认 5，范围 1~10） |
| `model` | `string` | 否 | 默认优先 `agnes-3.0-flash`，超时自动降级 `agnes-2.5-flash` |
| `reasoning_effort`| `string` | 否 | 默认锁定 `'max'` |
| `timeout` | `number` | 否 | 单个子代理请求超时秒数（默认 120 秒） |

---

## 3. 安装与配置

### 3.1 IDE MCP 配置

打开全局 MCP 配置文件：
`%USERPROFILE%\.gemini\antigravity\mcp_config.json`，配置如下：

```json
{
  "mcpServers": {
    "subagent": {
      "command": "node",
      "args": [
        "D:\\Desktop\\Super-File\\AI-IDE\\AI\\反重力\\antigravity-old-compat-manager\\tools\\antigravity-subagent-mcp.js"
      ],
      "env": {
        "SUBAGENT_BASE_URL": "https://apihub.agnes-ai.cn/v1",
        "SUBAGENT_API_KEY": "sk-your-api-key-here",
        "SUBAGENT_MODEL": "agnes-3.0-flash",
        "SUBAGENT_FALLBACK_MODEL": "agnes-2.5-flash"
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
