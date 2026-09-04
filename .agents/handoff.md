# Handoff · antigravity-old-compat-manager

## 当前状态 (2026-09-04)
- 发布者统一为 `zk-agent`，与插件 Antigravity-Injection (zk-agent.zk-proxy-pro) 完全匹配
- Bridge AGENT_PRO_ID = zk-agent.zk-proxy-pro
- 扩展目录前缀 = zk-agent.zk-proxy-pro-
- 兼容模式：Gemini37（保留 Claude + Gemini 3.8）
- 已部署到 D:\Antigravity

## 项目分工（零重叠）

### 本项目（兼容层）：
- Bridge 修补部署（OneLSAgentProxyBridge.cjs）
- 模型列表过滤/白名单（Workbench 修改，防 IDE 卡死）
- 版本伪装（product.json ideVersion=2.5.5）
- 认证时序修复（main.js 正则替换）
- 备份/恢复/自愈
- GUI 管理器

### 插件（Antigravity-Injection，注入层 + 模型改写）：
- 提示词注入
- 会话标题简体中文
- 文件上下文元信息
- 历史摘要 <conversation_summaries> 剔除
- 模型解锁（全量模型目录，autoModelUnlock 自动执行）
- 流式响应结束保险（end/close/30s空闲超时三重保险）
- **模型改写 / 动态映射**（v9.9.524+ 从本项目移入）
  - 从 URL 提取实际模型名，改写 LS 占位符 gemini-2.5-pro
  - 支持未来新模型（3.9/4.0/4.1）自动适配，无需改代码
- 本地 HTTP 代理
- 侧边栏 webview

## 关键约束
- 发布者必须是 zk-agent，与插件一致
- 修改发布者必须同步修改：Bridge AGENT_PRO_ID、PSM1 $prefix、测试文件 EXTENSION_ID
- 严禁在 Workbench 动态修改状态机或排序（防卡死）
- 模型改写/动态映射已移入插件（v9.9.524+），本项目不再负责
- `runtime/Gemini37AgentProxyCompat.cjs` 保留为历史参考，不再使用

## 关键文件
- scripts/StableMode.Core.psm1 — 核心模块
- runtime/OneLSAgentProxyBridge.cjs — Bridge（AGENT_PRO_ID 硬编码）
- Antigravity稳定模式.ps1 — GUI 入口
- tests/ — 测试

## 使用流程
- 日常使用：什么都不用管
- 重装 IDE 后：必须执行本项目（Bridge/版本伪装/模型过滤都在 IDE 目录，重装后丢失）
- 更新插件后：不需要执行本项目（模型改写已在插件内，自动生效）
- 官方发布新模型：不需要执行本项目（插件动态映射自动适配）

## 待办
- 无。当前版本功能完整，与插件 v9.9.524 配合正常。
