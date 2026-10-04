# 旧版 Antigravity 放行新模型 SOP（Claude 5.5 六档 / 未来 Gemini·Claude）

> 适用：锁死不升级的旧版 Antigravity（真实 1.20.6，安装在 `D:\Antigravity`），经 compat-manager + zk 插件在本地代理/前端补丁层放行官方新模型。
> 最近更新：2026-10-04。已实测放行 **Claude Opus/Sonnet 5.5 各 High/Medium/Low 六档**，Gemini 3.8 保持可用，IDE 不卡死。前端工具链已收敛到随仓库入库的 **`model-unlock/`**（一键脚本 `放行Claude六档.ps1 -ForceKill`；`evidence/` 仅留历史一次性取证、不入库）。

## 一、原理（三段，已端到端验证）

旧版语言服务器（LS）持 2026-03 冻结的模型身份表，新模型的 choice value 全为 0，数据层无法直接新增；`model`/`modelAlias` 都是整数 ENUM，塞不进字符串。官方 `daily-cloudcode-pa.googleapis.com` 的 `/v1internal:streamGenerateContent?alt=sse` 是**统一网关，纯凭请求体顶层 `model` 字符串 uid 路由**（Gemini schema 换 `model=claude-...` 直接 200、零协议转换，响应每帧 `modelVersion=<uid>`）。因此用"借壳 + 旁路选择"：

1. **前端 workbench 注入**（`model-unlock\patch-workbench.mjs`，目标 `D:\Antigravity\resources\app\out\vs\workbench\workbench.desktop.main.js`）：
   - 每个放行项借 `modelAlias:8`（RECOMMENDED，唯一能正常发 v1internal 的外壳；alias:7=AUTO 会在 LS 内级联挂起，禁用），并带自定义字段 `__agUid:"真实uid"`（不进 LS 网络请求，仅供上报）。
   - 5 处注入：下拉分组 nKc（无条件 concat）、可见列表 dutE（**条件** concat，官方配置加载后才追加，保证启动默认 3.8）、Xlt 的 vKc（非空才 concat）、回显匹配 Kun（alias:8 共用，按最近选择的 label 精确匹配防串台）、选择器 I（选中即无阻塞 `fetch http://127.0.0.1:8937/__agtarget?uid=...&label=...`）。
2. **zk 路由落盘**（源码 `Antigravity-Injection/plugins/zk-proxy-pro/vendor/bundled-origin/source.js` 的 `/__agtarget`）：收选择 → 读-改-写 `_agcap/_ag-selected.json`（`{last, bySid}`，带 CORS）。renderer 沙箱无 fs，CSP 已放行 `connect-src http://127.0.0.1:*`，故走本地 HTTP。
3. **zk 改道**（同目录 `_ag-gemini37-compat.cjs` 的 `_agReadSelected`）：LS 主对话统一发占位符 `gemini-2.5-pro`，compat 按 `URL 模型名 > 旁路选择（bySid→last，120 分钟新鲜窗口）> 默认 gemini-3.8-flash-high` 覆盖 `body.model`，并在改前把主对话 `thinkingBudget` 提升为 -1（High/动态）。

## 二、一张映射表（以后加模型只改这里）

`model-unlock\patch-workbench.mjs` 顶部的 `MODELS` 数组是**唯一前端映射表**；后端 zk/compat 通用读 uid，**加模型零改后端**。

当前六档（uid 必须与官方完全一致，**Medium 后缀是全称 `-medium`，写 `-med` 会 404**）：

| 显示名 label | 真实 uid |
|---|---|
| Claude Opus 5.5 (High/Medium/Low) | `claude-opus-5-5-high` / `-medium` / `-low` |
| Claude Sonnet 5.5 (High/Medium/Low) | `claude-sonnet-5-5-high` / `-medium` / `-low` |

## 三、放行一个新模型（如未来 Gemini 3.9 / 4.0、Claude 新版）

1. **取真实 uid**：以官方 `fetchAvailableModels` 返回为准（快照 `model-unlock/fetchAvailableModels.json`，可跑 `node model-unlock/list-official-uids.mjs` 列出全部 uid；新模型发布后重新抓包更新该快照）。命名规律：Gemini `gemini-X.Y-flash-{high,medium,low,tiered}`；Claude `claude-{sonnet,opus}-<ver>-{high,medium,low}`。**不要凭缩写猜**（-med 404 教训）。
2. **加一行**：在 `model-unlock\patch-workbench.mjs` 的 `MODELS` 追加 `{ label: '下拉显示名', uid: '真实uid' }`（六档都借 modelAlias:8，无需改其它）。
3. **关 IDE**：完全退出 Antigravity（含残留 language_server，确认 `ag=0 ls=0`）。
4. **一键应用**：`pwsh -File .\放行Claude六档.ps1 -ForceKill`（脚本从干净基线还原→注入→node --check，幂等；直接 `node model-unlock\patch-workbench.mjs` 等价）。
5. **启动验证**：桌面 Antigravity 图标（wscript→Launch-StableHidden.vbs）。下拉见新项、启动默认 3.8；选中发 "say ok"，正常流式出字、不卡死。
6. **落盘/网络确认（最硬证据）**：选中后 zk 的 `_agcap/_ag-selected.json` 里 `last.uid` 应为该 uid（120 分钟新鲜窗口）；正常流式出字即网关 200、`modelVersion` 为该 uid。404 = uid 写错（如把 `-medium` 写成 `-med`）；Working 久挂 = 误用了非 alias:8 外壳。正式干净 vsix 不含 h2route/h2probe 录制探针（历史探针脚本留在 evidence/，不入库）。

> 新 Gemini 模型若请求体还缺该版本必需字段，先靠 compat 既有的 thinkingBudget 提升；如仍 400，再在 compat 按 uid 做通用字段补齐（这是唯一可能需要动后端的情况）。Claude 全系已验证零转换。

## 四、IDE 更新/修复后恢复前端补丁

IDE 自动更新或修复会覆盖 `workbench.desktop.main.js`，Claude 注入会丢（3.8 的 Gemini37 补丁由 compat-manager 启动器自愈，Claude 这层目前用独立脚本恢复）：

- 完全退出 IDE → 运行 `pwsh -File .\放行Claude六档.ps1 -ForceKill` → 重新启动。
- 干净基线 `model-unlock\assets\prod-wb-pre-claude.js`（23,825,890 字节，Gemini37 补丁态，随仓库入库）是脚本的还原源，勿删。
- 若 IDE 跨大版本导致 5 个锚点失配（脚本会打印 `ANCHOR CHECK FAILED` 且不写入），需按第三节重新定位 workbench 锚点（渲染链 nKc/dutE/vKc/Kun/I，逆向脚本在 evidence/inspect-*.mjs、dump-anchors.mjs）。

## 五、zk 扩展更新（后端固化）

后端改动已落源码项目 `Antigravity-Injection`，当前发布版 **9.9.530**：`dist/zk-proxy-pro-9.9.530.vsix`（含 `/__agtarget` 与 `_agReadSelected`，**不含** FAM/H2 tee 等实验探针；9.9.529 是首个含本功能的同版本本地修订，9.9.530 为规范化 bump 发布版，二者后端代码一致）。安装该 vsix（或按版本同步源码重新 build）即可保留旁路改道。

**升级版本号（推荐，2026-10-04 实操到 9.9.530）**：在 Antigravity-Injection 跑 `node scripts/bump-version.mjs 9.9.530`（自动改版本号 → build → 32 测试 + target-check → commit/push；该仓库已配 `http.proxy=http://127.0.0.1:51081` 供 push）。关 IDE（ag=0 ls=0、8937 释放）后用 CLI 安装：`D:\Antigravity\bin\antigravity.cmd --install-extension <仓库>\dist\zk-proxy-pro-9.9.530.vsix --force`。CLI 自动新建 `extensions\zk-agent.zk-proxy-pro-9.9.530\` 并把旧版（529/528）写入 `.obsolete`，无需手动删旧目录。本次 GUI 复验：扩展详情 9.9.530、默认 3.8、七档齐、选 Sonnet Low 落盘 `claude-sonnet-5-5-low` 且流式回 "ok"。源码侧验证：`npm test`（compat **19** 项单测，含旁路 bySid/新鲜窗口/时间戳/回退；三文件合计 **32** pass）、`node tools/checks/antigravity-target-check.js`（校验 dist 与源码一致）。

**2026-10-04 已完成干净部署（运行态 = 该 vsix）**：运行态 529 已用此 vsix 文件级覆盖、实验探针与录制全清，并 GUI 复验通过（默认 3.8、六档在、选 Sonnet Medium 回复正常、`_ag-selected.json` 落盘正确、不再产生任何 h2/fam 日志）。
**同版本内本地修订**（不 bump、版本号不变）时 CLI `--install-extension` 会跳过，改用文件级覆盖法（以下为 2026-10-04 对 529 的实操存档，需先关 IDE 确认 ag=0 ls=0）；**跨版本升级（如 529→530）优先用上方 CLI 法**：
1. 备份整目录 `~/.antigravity/extensions/zk-agent.zk-proxy-pro-9.9.529`（本次备份在 `backups/zk-529-pre-clean-20261004`）。
2. 解压 vsix（zip）到临时目录，`robocopy <临时>\extension <529目录> /E /IS /IT`（只增/覆盖，不删运行时数据）。
3. 删除 vsix 不含的探针/备份：`_ag-fam-matrix.cjs`、`*.preb2b`、`*.precap`，并清空 `vendor/bundled-origin/_agcap/`（运行时自动重建，启动默认 3.8）。
4. `node --check` 覆盖后的 `source.js`、`_ag-gemini37-compat.cjs`；双击 vbs 重启复验。校验脚本：`evidence/verify-deploy.mjs`（期望 source.js=314608、compat=6012、探针全部 absent）。

## 六、回滚安全网

- 前端：`Copy-Item model-unlock\assets\prod-wb-pre-claude.js D:\Antigravity\resources\app\out\vs\workbench\workbench.desktop.main.js -Force`（回到仅 Gemini37，3.8 可用）。
- main.js：用本机 `model-unlock\assets\prod-main-pre-tpe.js`（8,378,330）。该文件含 IDE 官方内置 OAuth client_id/secret，**不入公开 git**（.gitignore 排除），换机需从本机或私有备份复制；前端六档补丁不依赖它。
- zk 部署副本：干净部署前的整目录（含旧探针版）备份在 `backups/zk-529-pre-clean-20261004/`（本地、不入 git）。关 IDE（ag=0 ls=0）后 `robocopy backups\zk-529-pre-clean-20261004 <...\extensions\zk-agent.zk-proxy-pro-9.9.529> /E /IS /IT` 整体回滚，再重启。
- 重启/重打补丁前关全部 Antigravity/language_server（常残留 1 个需二次强杀）。

## 七、已知边界 / 后续可选增强

- 启动默认模型固定为官方 3.8（条件 concat 已保证不强选合成项）；合成模型仅用户主动选。
- 多会话隔离：compat 已支持按 `sessionId` 精确路由（bySid），但前端上报当前 sid 传空，单活跃会话用 last 已够；需要多会话并行不同模型时，再在 workbench 注入处把当前会话 id 随 `/__agtarget` 带上。
- 更彻底的前端自愈：可把 model-unlock\patch-workbench.mjs 的 5 处注入做进 `scripts/StableMode.Core.psm1` 的 workbench 补丁生成器（ConvertFrom/ConvertTo/Test 成套 + 离线往返断言），使 IDE 更新后启动即自动恢复 Claude，无需手动跑脚本（当前为独立脚本 + 本 SOP）。
- **模式前提**：模型旁路改道与 thinkingBudget 提升只在 zk 模式为 `custom`（默认）时生效；切到 `passthrough`（官方直连/零改写紧急模式）时所有改写静默停用、占位符直透。要放行新模型必须保持 custom。
- **上报失败静默回退**：renderer 选中后 `fetch /__agtarget` 若失败（zk 未启动/写盘 500），前端不弹窗，会安全退回默认 3.8（界面显示与实际模型可能短暂不符）。zk 与 IDE 同扩展启动、正常在线时不触发；后续可在补丁 catch 加 `console.warn` 并检查 `res.ok`（需重打 workbench + GUI 复验，当前未改已验证前端）。
- **端口 8937 的由来**：zk 本地端口按 Windows 用户名 FNV 派生（本机 Administrator=8937，另一用户示例为 8981），并非源码常量。换用户/机器时 model-unlock\patch-workbench.mjs 与本文中的 8937 需同步改。
- **网络核验日志的适用范围**：第三节的 `h2route.log` / `h2probe-resp-*.txt` 是当前部署副本里的实验录制探针；正式干净 vsix **不含**这些文件。正式版核验以 `_agcap/_ag-selected.json`、实际流式回复为准（如需正式抓包要另加日志）。
- **正式 vsix 已含的后端加固**：`/__agtarget` 对空 uid 请求回 400（不覆盖既有选择）、状态文件用同目录 tmp+rename 原子落盘（防崩溃留截断 JSON）。
