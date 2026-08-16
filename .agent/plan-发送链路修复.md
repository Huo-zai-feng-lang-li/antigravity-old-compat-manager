# 发送链路修复

## 目标

修复输入后消息无法发送，同时保持旧版 HTTP 链路与当前新版 HTTPS 链路各自闭环。

## 已完成

- [x] 日志定位 HTTP 请求误发 HTTPS 端口。
- [x] 证明当前 main 发布 `httpsPort`，workbench 仅被误删一个 `s`。
- [x] TDD 实现 `legacy-http-v1` 与 `catalog-filter-http-v2` 显式适配器。
- [x] 旧错误档案自动迁移，状态检查按同一适配器验证。
- [x] 只清理 `modelPreferences`，保留 `userStatus` 与登录状态。
- [x] 修复真实 `D:\Antigravity`，静态检查 7/7。
- [x] PowerShell 5/5、.NET 42/42。
- [x] 清除 USS 旧 HTTPS 本机端点并发布 HTTP 端口。
- [x] 2026-07-24 真实日志复现：HTTP→HTTPS 88 次、`Failed to fetch` 2 次、道 Agent 请求 0 次。
- [x] TDD 改为双协议客户端：USS 单实例走 HTTP，扩展宿主直连保留 HTTPS。
- [x] 真实启动日志：HTTP→HTTPS 0、未知证书 0、`Failed to fetch` 0。
- [x] 用户切换账号后确认可正常发送；最新日志记录 8 次 `streamGenerateContent` 到 `127.0.0.1:8937`。
- [ ] 道 Agent 系统提示词注入内容需单独做请求体级验收。
- [x] 修复旧 UI 拒绝当前 `64C900...` 稳定哈希：检测与安装统一使用自适应档案。
- [x] GUI/安装器当前目标检测通过，7 项状态全部为真。

## 待用户验收

- [ ] 完成账号登录。
- [ ] Gemini 3.5 与 Claude 各发送一条消息。
- [ ] 可见运行 90 秒无卡死。

真实消息往返未在未登录状态下伪造为通过。
