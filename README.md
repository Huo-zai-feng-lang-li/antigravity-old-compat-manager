# antigravity-old-compat-manager

[GitHub 仓库](https://github.com/Huo-zai-feng-lang-li/antigravity-old-compat-manager)

## 项目定位

Antigravity IDE **兼容层管理器**，与 [Antigravity-Injection](https://github.com/Huo-zai-feng-lang-li/Antigravity-Injection) 插件（zk-agent.zk-proxy-pro）配合使用。

- **本项目（兼容层）**：Bridge 修补部署、模型列表过滤、版本伪装、认证时序修复、备份恢复
- **插件（注入层）**：提示词注入、会话标题简体中文、文件上下文元信息、历史摘要剔除、模型解锁（全量模型目录）、流式响应结束保险、模型改写/动态映射、本地 HTTP 代理

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

## 项目导航

- 使用说明：`README-稳定模式.md`
- 项目规则：`.agents/rules/README.md`
- 跨会话续接：`.agents/handoff.md`
- 取证笔记：`notes.md`

## 获取项目

```powershell
git clone https://github.com/Huo-zai-feng-lang-li/antigravity-old-compat-manager.git
cd antigravity-old-compat-manager
```
