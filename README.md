# antigravity-old-compat-manager

[GitHub 仓库](https://github.com/Huo-zai-feng-lang-li/antigravity-old-compat-manager)

## 当前可用交付

- 推荐双击桌面的 `Antigravity 稳定版.lnk`；健康时无黑窗快速启动，IDE 更新后自动检查并在结构兼容时自愈。
- 已完成 OneLS 重启发送、Agent Pro 系统提示词注入、桥文件事务部署、失败回滚与双冷启动验收。
- 提供两种可持久模式：`Stable` 仅保留 Claude；`Gemini37` 保留 Claude、Gemini 3.6 High/Medium 和 Gemini 3.7 High。
- 两种模式都排除 Low、Gemini 3.1、GPT 及未来未知模型，并共用重启发送修复、OneLS Agent Pro 桥、备份与失败回滚。
- Gemini 3.7 Medium 因旧协议当前没有独立稳定的选择载体而暂未发布，避免重新引入模型重复、错误路由或 IDE 卡死。

这是一个面向 Windows 的可视化兼容工具项目，用于安全管理 Antigravity 历史版本、模型目录兼容、备份恢复与运行验收。

## 项目导航

- 使用说明：`README-稳定模式.md`
- 新模型兼容规则：`docs/Gemini新模型兼容指南.md`
- 阶段计划：`task_plan.md`
- 取证笔记：`notes.md`
- 跨会话续接：`.agent/handoff.md`

## 当前生产状态

`D:\Antigravity` 当前已部署 schema 8 / v13 `Gemini37` 组合模式：Claude、Gemini 3.6、Gemini 3.7 High 已实测可正常响应；180 秒冷启动观察中最长无响应 0 秒，`CodeWindow unresponsive` 事件 0。可随时在管理器中切回 `Stable`。

## 获取项目

```powershell
git clone https://github.com/Huo-zai-feng-lang-li/antigravity-old-compat-manager.git
cd antigravity-old-compat-manager
```
