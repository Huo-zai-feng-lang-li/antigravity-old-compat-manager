# 最新接续状态（2026-08-17）

## 当前部署
- 安装根目录：`D:\Antigravity`。
- 模式：`Gemini37`。
- Bootstrap：schema 8 / `compatibility-v13-gemini37-real-route-gemini36`。
- Main：`4B85AFF243E17F93F371611B965617E16A0169AC9566E395941866CEA4BBCE75`。
- Workbench：`3BF9D0BE3A07B1D3F545A85323183E00C2E48B3AA736B0E6D9CC7F823C114F8D`。
- Agent Pro source：`B4ECAA4B5DB9EE8E13844905188AAB9EB62813AE017732A629AE2F05C3783B67`。
- Agent Pro helper：`25C56FC5AA5D483E6AF0854737FE098C3E81BB34159B37E758A19D4166C522B7`。
- `Get-CompatibilityInstallStatus` 为 `Passed=True`，16 项检查全部为 true，v13 Gemini37 目标档案唯一。

## 根因与修复
- 503 的真实请求模型是 `gemini-2.5-pro`，不是界面显示的 Gemini 3.7。
- v13 在 Agent Pro 边界只把 Gemini37 兼容占位请求精确改写为 `gemini-3.7-flash-high`；Gemini 3.6、Claude、非 JSON 请求保持原字节。
- 目录同时保留 Claude、Gemini 3.6 High/Medium、Gemini 3.7 High，不放出 Low。
- Agent Pro source/helper 已纳入 Bootstrap 备份、哈希、自愈和失败回滚事务。

## 验证
- 用户现场确认 Gemini 3.6 与 Gemini 3.7 High 可正常响应；Claude 已在同一环境正常响应。
- PowerShell 15/15，Node 路由/桥接全部通过，.NET 42/42。
- 180 秒冷启动日志 `C:\Users\Administrator\AppData\Roaming\Antigravity\logs\20260817T025704`：窗口/CDP 2.66 秒，最长无响应 0 秒，`CodeWindow unresponsive` 0。
- 本任务启动的 Antigravity/语言服务器进程已清理。

## 已知限制
- Gemini 3.7 High 与 Medium 当前共用 `RECOMMENDED` alias 8，UI 按 choice 去重后只显示 High。
- 在找到独立稳定选择载体前，不得删除去重或恢复动态 Workbench 状态机强行显示 Medium。
- 项目强制规则：`.agent\rules\README.md`。
- 失败复盘与未来 3.8/3.9 流程：`docs\Gemini新模型兼容指南.md`。
