# 取证笔记

## 已确认事实

- 服务端模型目录进入旧版 `userStatus.cascadeModelConfigData` 后，可触发旧模型选择器渲染与选择状态循环。
- 仅保留 Gemini 3.6 Flash High 时，旧版仍可复现卡死；排除 3.6 后冷启动保持稳定。
- Gemini 3.6 Flash High/Medium/Low 的真实数值 ID 分别为 `1264`、`1265`、`1266`。
- Gemini 3.5 Flash Low 的真实数值 ID 为 `1187`，同样超过旧版枚举名称表末端 `1150`，因此“ID 大于 1150 必卡”已被反证。
- 旧版 `ncn()`、`svo()`、`scn()` 没有直接拒绝未知数值 ID。
- 最可能的反馈路径是 `Xct → setSelectedModel → uss-modelPreferences → Gb → Xct`；当前信心 `7/10`，实施阶段必须记录选择写入前后的真实 ID 进一步确认。
- 协议必须与 main 发布的端口成对：旧 main 发布 `httpPort` 时 workbench 使用 HTTP；当前 `4A911...` main 发布 `httpsPort`，workbench 必须保持 HTTPS。

## 当前稳定安装哈希

- `main.js`: `710FAB9A65D38BAD5923DCF1C99E0D9EDF017B4C3E86985A8A34533D9AA79C1A`
- `workbench.desktop.main.js`: `9207A2E23A78E4A0CACF86E2C4B63EBD401809B16275AF9D560731962578CEE1`
- `product.json`: `CBEF505644AEAC59385B1FD80390B3D6637225A2109CC9C179AD5B81DB385E31`
- `config.json`: `5136B8593B8599766A22EB1F8756B370DF7B3140671DCA99658E4AB00428CBF9`

## 当前稳定模型策略

- 保留：Gemini 3.5 Flash High/Medium/Low、Claude Sonnet 4.6、Claude Opus 4.6。
- 隔离：Gemini 3.1、Gemini 3.6、GPT。

## 设计结论

- 不采用代理模型 ID；模型请求全链路保留服务端真实 ID。
- 对 3.6 和未来未验证模型绕开旧版 USS 模型偏好回写，改用兼容桥本地偏好。
- 未知模型先进入隔离区，只有通过冷启动、选择、真实消息、历史恢复与重启验收后才能放行。

## 官方技术依据

- [.NET 单文件部署](https://learn.microsoft.com/en-us/dotnet/core/deploying/single-file/overview)
- [.NET CLI 发布模式](https://learn.microsoft.com/en-us/dotnet/core/deploying/deploy-with-cli)
- [Windows Forms 概览](https://learn.microsoft.com/en-us/dotnet/desktop/winforms/overview/)

本机已验证 `.NET SDK 9.0.304` 可用。
# 2026-07-23 实施取证

## 稳定脚本快速交付

- 当前实际旧版目录重新发现为 `D:\Antigravity`；`D:\Antigravity IDE` 当前不存在。
- 当前真实文件仍为原始状态：main `C98CFE9D...`，workbench `EA1037E9...`，`ideVersion=1.23.2`。
- 内存补丁候选精确得到已验证稳定哈希：main `710FAB9A...`，workbench `9207A2E...`。
- 临时安装副本验证：应用、静态检查、重复应用、字节级恢复全部通过。
- 真实 `D:\Antigravity` 未由开发过程修改，等待用户通过 GUI 点击应用。

## R1 自愈启动器结果

- 新源 main：`4A91118CECAAD47C30867DF082EF9920B79CB051DE910A75E75F086191577FB3`。
- 新源 workbench：`E47834FAE17018E24B7D171F4E75F6A63DC3B94FE785ACDAB8201FE5BFBF0970`。
- 新稳定 main：`4559D1A3371D5497B7CDB27D5F0446EC4357B6A193BBB75526DE8E7F2C08BF8D`。
- 双协议稳定 workbench：`EF1D5838CAE783E7974DBD876A3B0C121DE861572B246939F8765830296ECA1A`。
- 2026-07-24 真实启动证据：HTTP→HTTPS 0、未知证书 0、`Failed to fetch` 0；当前 Agent 面板要求登录，未产生模型请求。
- 用户切换账号后发送恢复；最新会话 8 次 `streamGenerateContent` 均路由到道 Agent 本地代理 `127.0.0.1:8937`。
- 双边界过滤：在线模型目录 + 本地 userStatus 缓存读写；解析失败为空状态。
- 临时副本自适应、档案注册、产品漂移自愈、第二次快启均通过。
- 真实安装静态检查通过；只清理 `modelPreferences`，保留 `userStatus` 与登录状态。
- 桌面已创建 `Antigravity 稳定版.lnk`，PowerShell 目标使用稳定 WindowsApps 执行别名。

## 2026-07-23 发送链路事故闭环

- 原错误组合：main `64C900...` 发布 `httpsPort`，workbench `27690FE...` 却使用 HTTP。
- 运行证据：旧日志重复 `client sent an HTTP request to an HTTPS server` 与 `Failed to fetch`。
- 修复组合：main `64C900...` + workbench `E47834...`；新日志上述两类错误均为 0。
- A/B 证据：原始 main `4A911...` 与过滤 main `64C900...` 都显示当前账号需要登录，说明该提示不是模型过滤补丁造成。
- 尚未完成：账号未登录，无法自动完成真实消息往返；需用户登录后自行发送验收。
- UI 回归：旧 UI 未传 `-AllowAdaptive`，导致已修复 main `64C900...` 被旧白名单拒绝；现已与 StableBootstrap 共用结构适配和状态推导。
- 二次根因：只把发布端口改成 HTTP 仍不够；`uss-lsClientMachineInfos` 保留旧 HTTPS 本机记录，renderer 的首条匹配继续命中旧端口。最终补丁会过滤全部空资源本机记录后写入唯一 HTTP 端点。

## 当前已知文件

- `main.js` SHA-256：`710FAB9A65D38BAD5923DCF1C99E0D9EDF017B4C3E86985A8A34533D9AA79C1A`。
- `workbench.desktop.main.js` SHA-256：`9207A2E23A78E4A0CACF86E2C4B63EBD401809B16275AF9D560731962578CEE1`。
- 稳定模式 allowlist 锚点唯一 1 次；加入 Gemini 3.6 三档后的候选 `main.js` SHA-256 为 `47C93571D4375B7C15759CB671F48910D82038AA11FCDBC18942E8DAD1B346FA`。
- 3.6 偏好桥 5 个工作台锚点均唯一 1 次；内存替换和片段语法检查通过，候选工作台 SHA-256 为 `8263287CF89B6DB681B84305673EC8DF20BA85695059A6F8F1D97C72FA4CBF37`。

## 3.6 偏好桥边界

- 自动回退从持久化改为 `persist=false`。
- Gemini 3.6 `1264/1265/1266` 不写入旧 `uss-modelPreferences`，只写无凭据的本地偏好。
- 冷启动优先恢复本地偏好，`currentModelConfig` 继续用真实 ID 匹配。
- 普通发送和历史映射保持真实 requestedModel ID，不做代理 ID。
- Battle 在无法核验每个子会话真实 ID 前保持禁用。

## 2026-07-25 Gemini 3.6 现场闭环

- 生产 Gemini36 main/workbench SHA-256：`EBB3116072CA0084FE5478CE3F08446ACB6231006DFAC7587CAB155C7364E1A6` / `4854976232E7E9B4620453FDFA97F04A410C89B31CE1AD17537C0F9B9FD0C346`；`product.json` checksum 静态复验通过。
- High/Medium/Low 真实发送分别返回 `42/43/44`；完全关闭并重启后 Low 返回 `45`，无需切号。
- 最新重启日志：`streamGenerateContent=2`，TLS、`Failed to fetch`、`CodeWindow: detected unresponsive` 均为 `0`，OneLS Agent Pro bridge ready 为 `1`。
- Agent Pro 主聊天仍在 `request.systemInstruction.parts` 注入：`GEMINI_REST_CHAT`、`role=system`、`transformed=true`、`25661 -> 1384` 字符。
- 90 秒 18 个样本中最大单进程私有内存 `355.2 MB`，主窗口持续响应；未复现旧版 700MB–1GB 持续暴涨。
- 稳定/3.6 双向切换、同模式零备份、失败字节级回滚、双模式 profile 并存均由自动化测试通过。
- 独立复审发现并闭环三项可靠性边界：Gemini36 健康检查会剥离包装后继续验证底层 Stable/OneLS 传输；CDP 仅接受发送后的新增回复；每个请求均有超时且断连会清空 pending。
- 修正 CDP 边界后再次发送 Gemini 3.6 Low，历史中已有 `45`，本次新增回复为 `46`，工具退出 `0`。
- 最终 13 组 PowerShell/Node/.NET/真实大文件安装回归全部退出 `0`；.NET `39+3` 失败 `0`；新增函数最大圈复杂度 `7`。
