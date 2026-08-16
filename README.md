# Antigravity 旧版兼容管理器

## 当前可用交付

- 推荐双击桌面的 `Antigravity 稳定版.lnk`；健康时无黑窗快速启动，IDE 更新后自动检查并在结构兼容时自愈。
- 已完成 OneLS 重启发送、Agent Pro 系统提示词注入、桥文件事务部署、失败回滚与双冷启动验收。
- 提供两种可持久模式：`Stable` 仅保留 Claude；`Gemini36` 在相同稳定底座上额外启用 Gemini 3.6 High/Medium。
- 两种模式都排除 Gemini 3.1、GPT 及未来未知模型，并共用重启发送修复、OneLS Agent Pro 桥、备份与失败回滚。

这是一个面向 Windows 的可视化兼容工具项目，用于安全管理 Antigravity 历史版本、模型目录兼容、备份恢复与运行验收。

## 项目导航

- 设计书：`docs/superpowers/specs/2026-07-23-antigravity-compat-manager-design.md`
- 阶段计划：`task_plan.md`
- 取证笔记：`notes.md`
- 跨会话续接：`.agent/handoff.md`

## 当前生产状态

`D:\Antigravity` 当前已部署 `Gemini36`：三档 3.6 均真实发送成功，重启后无需切号仍可发送；Agent Pro 主聊天请求继续在 `request.systemInstruction.parts` 完成系统提示词变换。可随时在管理器中切回 `Stable`。
