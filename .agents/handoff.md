# Handoff · antigravity-old-compat-manager

## 当前状态 (2026-09-04)
- 发布者统一为 `zk-agent`，与插件 Antigravity-Injection (zk-agent.dao-proxy-pro) 完全匹配
- Bridge AGENT_PRO_ID = zk-agent.dao-proxy-pro
- 扩展目录前缀 = zk-agent.dao-proxy-pro-
- 目标模型：gemini-3.8-flash-high（从 gemini-2.5-pro 占位符改写）
- 兼容模式：Gemini37（保留 Claude + Gemini 3.8）
- 已部署到 D:\Antigravity

## 项目分工（零重叠）
### 本项目（兼容层）：
- 模型改写注入（Gemini37AgentProxyCompat.cjs）
- Bridge 修补部署（OneLSAgentProxyBridge.cjs）
- 模型列表过滤/白名单（Workbench 修改）
- 版本伪装（product.json ideVersion=2.5.5）
- 认证时序修复（main.js 正则替换）
- 备份/恢复/自愈
- GUI 管理器

### 插件（Antigravity-Injection，注入层）：
- 提示词注入
- 会话标题简体中文
- 文件上下文元信息
- 历史摘要 <conversation_summaries> 剔除
- 模型解锁（GetUserSettings 注入全量模型目录，autoModelUnlock 自动执行）
- 流式响应结束保险（end/close/30s空闲超时三重保险，防 Generating 卡死）
- 本地 HTTP 代理
- 侧边栏 webview

## 关键约束
- 发布者必须是 zk-agent，与插件一致
- 修改发布者必须同步修改：Bridge AGENT_PRO_ID、PSM1 $prefix、测试文件 EXTENSION_ID
- 模型升级必须三层同步（路由层/选择层/展示层）
- 严禁在 Workbench 动态修改状态机或排序（防卡死）

## 关键文件
- scripts/StableMode.Core.psm1 — 核心模块
- runtime/OneLSAgentProxyBridge.cjs — Bridge（AGENT_PRO_ID 硬编码）
- runtime/Gemini37AgentProxyCompat.cjs — 模型改写（TARGET_MODEL）
- Antigravity稳定模式.ps1 — GUI 入口
- tests/ — 测试

## 待办
- 用户需运行 GUI 点「应用并启动」注入兼容补丁（插件更新后需重新应用）
- 两个项目同时运行时功能互补，互不影响
