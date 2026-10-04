# 最新接续状态 (2026-10-04) · 插件已规范化发布 9.9.530 并安装运行、两仓库均已推送

> **【下次官方发布新模型（Gemini 3.9/4.x、Claude 5.6+）先看这里】**
> 照做 **`model-unlock/说明书-以后加新模型看这里.md`**（6 步傻瓜清单 + 报错对照 + 锚点失配处理）。
> 要点：新模型**不会**自动可用——下拉自动出现≠能用，选中无 `__agUid` 的官方新项会被回退成默认 3.8；正确流程是用 `model-unlock/capture-official-catalog.mjs`（`check`→`install`→重启 IDE→取 `_agcap/_ag-models-catalog.json` 覆盖快照→`restore`）抓官方真实 uid → 在 `model-unlock/patch-workbench.mjs` 顶部 `MODELS` 加一行 → 关 IDE 跑 `放行Claude六档.ps1 -ForceKill` → GUI 验证 `_ag-selected.json` 落盘 uid 与响应 `modelVersion` → 提交。**同代新模型后端零改动**，仅跨大版本改协议才需动 compat。

## ★★★ 最新：插件 9.9.530 规范化发布 + CLI 安装 + GUI 复验通过（2026-10-04）
- 版本 bump：在 Antigravity-Injection 跑 `node scripts/bump-version.mjs 9.9.530`（自动改 package.json/target-check/CHANGELOG/RELEASE_NOTES/README → build 530 vsix → 32 测试 + target-check → commit/push）；产出 `dist/zk-proxy-pro-9.9.530.vsix`（58 files, 519.67 KB），zk release commit `b313c86` 已推送（`2b5f03e..b313c86 main`）。
- 安装（CLI，推荐）：关 IDE（ag=0 ls=0、8937 释放）→ `D:\Antigravity\bin\antigravity.cmd --install-extension <仓库>\dist\zk-proxy-pro-9.9.530.vsix --force` → 自动建 `extensions\zk-agent.zk-proxy-pro-9.9.530\` 并把 529/528 写入 `.obsolete`。文件验证：530 的 package.json version=9.9.530、source.js=314608 含 /__agtarget、compat=6012、探针全无、bundled-origin 19 文件。
- GUI 复验（cu 双击桌面彩色 A → wscript vbs）：扩展详情 **9.9.530 / 源 VSIX / 已启用**；单窗口不卡死、登录正常、默认 Gemini 3.8 Flash (High)、下拉七项齐；选 **Claude Sonnet 5.5 (Low)** 后 530 的 `_agcap/_ag-selected.json` 实时落盘 `last.uid=claude-sonnet-5-5-low`（证明"界面选择→后端上报"链路可靠；此前一度看到落盘 3.8 只是之后又切回了 3.8，非 bug），发 "say ok" 流式回 "ok"。
- 当前运行态 = **9.9.530**；529 目录仍在但已 .obsolete（不加载），干净备份 `backups/zk-529-pre-clean-20261004/` 仍可回滚（功能与 530 等同，仅版本号旧）。
- git：zk 已推送（旁路 `2b5f03e` + release `b313c86`）；compat-manager 已推送（工具链 `cca8fe0`；main 干净基线因含 IDE 内置 OAuth 密钥，按 .gitignore 仅本地保留、不入公开仓库）。

## ★ 前端工具链正式入库 + 全文档同步（2026-10-04 收尾）

- 新建正式目录 **`model-unlock/`（随 git 入库，不被 .gitignore 忽略）**：`patch-workbench.mjs`（原 evidence/patch-wb-claude6.mjs，路径改为 `__dirname` 解析 assets）、`verify-workbench.mjs`、`list-official-uids.mjs`、`fetchAvailableModels.json`（官方 uid 快照）、`assets/prod-wb-pre-claude.js`(23,825,890) + `prod-main-pre-tpe.js`(8,378,330) 两个干净基线、`README.md`。
- 原因：原前端补丁/基线都在被 gitignore 的 `evidence/`，一键脚本与 SOP 却依赖它们，换机/清理即断链；正式工具已全部提升入库。`evidence/` 保留为历史取证（不删，含本轮 audit-mapping.mjs）。
- `放行Claude六档.ps1` 已改指 `model-unlock\patch-workbench.mjs`（BOM EF BB BF / PS 语法 / 路径均校验通过）；SOP 内前端路径全部更新到 model-unlock。
- 校验：三脚本 `node --check`=0；`verify-workbench.mjs` 实测当前 workbench **SIX-TIERS OK（每 uid×3）**；`list-official-uids.mjs` 确认官方最新 Gemini 仅到 3.8（high/low/medium/tiered，**无 3.9/4.0**）、Claude 六档 + 两基础档。
- 映射审计：patch 六 uid 全部在官方目录；备份录制显示所有 Claude 请求（高/中/低）`thinkingBudget` 统一 -1、无 thinkingLevel——**档位靠独立 uid 区分（六档 200 + modelVersion 铁证），thinkingBudget 是 Gemini 语义、对 Claude 冗余但无害**。
- 全文档同步：`README.md`（能力/导航/新模型放行段）、`Antigravity重装到启动使用流程.md`（新增第六节叠加层 + 路径表）、`README-稳定模式.md` 与 `notes.md`（顶部现状指针，历史内容不改写）、`.agents/rules/README.md`（新增 2.5 放行分工/注入红线/工具链入库/版本号约定）、plan（顶部闭环总结）、`SOP-新模型放行.md`（路径/干净部署/回滚）、本 handoff。
- 版本号：当日为 9.9.529（同版本本地修订）；**随后已 bump 到 9.9.530 并 CLI 安装发布（见顶部 ★★★ 区块）**。
- git：两仓库均已提交推送（zk 旁路 `2b5f03e` + release `b313c86`；compat 工具链 `cca8fe0`）；dist vsix 不入 git。

## ★★ 运行态已用干净 vsix 替换（方案2完成，信心 10）
- 部署副本 `~/.antigravity/extensions/zk-agent.zk-proxy-pro-9.9.529/vendor/bundled-origin/` 已用 `Antigravity-Injection\dist\zk-proxy-pro-9.9.529.vsix` 全量覆盖：**source.js=314608、compat=6012（干净加固正式版，node --check 过）**，bundled-origin 收敛为 vsix 的 19 个文件。
- 已删探针/备份/录制：`_ag-fam-matrix.cjs`、source.js 的 FAM 钩子/H2 tee（随覆盖移除）、`source.js.preb2b`、`source.js.precap`、`_ag-gemini37-compat.cjs.preb2b`、`_agcap/` 整目录（40+ h2probe/h2orig/h2route/_fam-matrix 录制）；覆盖还把 77MB `_ea_diag.log` 缩回 vsix 基线。
- **回滚安全网**：替换前整目录 112 文件备份在 `antigravity-old-compat-manager\backups\zk-529-pre-clean-20261004\`（含探针旧版）。回滚：关 IDE（ag=0 ls=0）→ `robocopy <该备份> <...extensions\zk-agent.zk-proxy-pro-9.9.529> /E /IS /IT` → 双击 vbs 重启。
- **GUI 复验（cu 双击桌面彩色 A → wscript vbs）**：认证自动恢复、单窗口、不卡死；启动默认 **Gemini 3.8 Flash (High)**（条件 concat 守卫生效）；下拉七项 = 3.8 + Claude Opus/Sonnet 5.5 各三档 New；扩展详情确认 ZKAgent Pro **9.9.529 / 源 VSIX / 已启用**。
- **端到端铁证（干净版）**：选 Claude Sonnet 5.5 (Medium) 发 "say ok" → 流式回复 "ok"（STOP，带 Copy/反馈）；文件系统 `_agcap/` 仅重新生成 `_ag-selected.json`，`last={uid:"claude-sonnet-5-5-medium",label:"Claude Sonnet 5.5 (Medium)",sid:""}`（-medium 全称正确、原子写无 .tmp 残留）；**无任何 h2/fam 录制重新生成**。
- 528 仍在 .obsolete（不加载），未动；桌面/开始菜单图标仍 wscript vbs 接管。
- 当前 IDE 保持打开（选中 Claude Sonnet Medium 的会话）；下次重启启动 effect 仍默认 3.8。
- 部署/校验脚本（取证用，可留）：`evidence\replace-precheck.mjs`、`evidence\verify-deploy.mjs`。

---

# (2026-10-04 稍早 · 审计后) · 六档可用 + 后端已固化进 vsix + 独立审计通过

## ★本轮收尾（2026-10-04，审计 + 加固，信心：可交付）
- **独立子 agent 七项审计结论：可交付**；两红线（启动不强选合成模型 dutE/vKc 条件 concat；/__agtarget 严格 pathname 匹配、三路皆 return 不 fall-through）均 **PASS**；无严重问题；审计信心 8.5。30 项测试与双 node --check 经审计独立复跑。
- **已采纳并修复（落源码/生成器，未扰动已验证运行态）**：
  1. `放行Claude六档.ps1`：language_server 计数/查杀收紧为 `Path -like 'D:\Antigravity\*'`，避免误杀 VS Code/Cursor 等其它 IDE 的语言服务器（UTF-8 BOM，PS 语法校验过）。
  2. 源码 `source.js` 的 /__agtarget：空 uid 回 **400**（不覆盖既有选择）；状态文件改 **同目录 tmp+rename 原子落盘**。
  3. `patch-wb-claude6.mjs`：注入后 node --check 失败时**回滚 workbench 到干净基线**（不留半成品），并删除 23MB 临时校验文件；成功路径注入内容逐字节不变（运行态无需重打）。
  4. 测试补 2 个时间戳边界（未来 ts / 非数字 ts）+ clearState 删空目录；**三文件合计 32 pass / 0 fail**，无 _agcap 残留。
  5. **新 vsix 已重建**：`Antigravity-Injection\dist\zk-proxy-pro-9.9.529.vsix`（58 files, **519.62 KB**），`antigravity-target-check ok`。
  6. SOP 补：passthrough 模式旁路停用、上报失败静默回退 3.8、8937 为用户名 FNV 派生端口、h2route/h2probe 仅探针态有、后端加固说明。
- **未采纳/延后（已在 SOP 第七节说明）**：①前端选中上报失败的 res.ok/console.warn 可感知告警——需改已端到端验证的 workbench 注入并 GUI 复验，失败概率极低且安全回退 3.8，本轮不动；②环回 /__agtarget 加 nonce/自定义头——与既有 /origin 环回免鉴权信任模型一致、收益低，不做；③把 patch6 五处注入做进 `scripts/StableMode.Core.psm1` 启动自愈（109KB 核心、有回归风险）——**待用户决策**，当前用一键脚本 + SOP。
- **运行态保持上轮已验证状态未动**：workbench=patch6（23831768，六档可用、默认 3.8、不卡死）；部署 529 副本仍带实验 FAM/H2 tee 探针（无害，运行态依赖其 /__agtarget+旁路）。加固在**源码 vsix / 生成器 / SOP**：下次安装新 vsix（去探针）或重跑 `放行Claude六档.ps1` 即生效，本轮不在运行态冒险替换/重启。
- **交付物**：`放行Claude六档.ps1`（一键恢复前端六档）、`SOP-新模型放行.md`（加模型只改 patch6 顶部 MODELS 一行）、`dist\zk-proxy-pro-9.9.529.vsix`（后端正式固化）。

---

# (2026-10-04 06:45) · Claude 5.5 六档已端到端打通（运行态完成，待 B3 固化）

> 下方 02:45 区块已过时（当时是"安全回滚、旁路待做"）。以此区块为准。

## 结论：六档全部可用（信心 10，网络层 modelVersion 铁证）
- 选 Claude 任一档 → renderer 经本地 HTTP 旁路上报 uid → zk 落盘 `_ag-selected.json` → compat 读盘把请求体 `model` 改成该 uid → 官方统一网关返回**真正的 Claude** Gemini-SSE（每帧 `modelVersion=<uid>`、responseId=`req_vrtx_`），IDE 流式出字、**不卡死**；切回 Gemini 3.8 同理正常。
- 六档后端 200 实测（`evidence\tier-summary.mjs` 汇总，录制在 zk `_agcap\h2probe-resp-*.txt`）：claude-{sonnet,opus}-5-5-{high,medium,low} 各 ≥1 条 200。GUI 端到端实测 Sonnet High / Opus High / Sonnet Medium（选中→上报→出字）；其余档后端 200 + 前端同构注入。
- **正确 uid 后缀是 `-medium`（全称），不是 `-med`**：用 `-med` 官方 404（rid1590 铁证），改 `-medium` 即 200。真实 uid 来源 `evidence\fetchAvailableModels-full.json`。Gemini 官方当前最新到 3.8（high/medium/low/tiered），无 3.9/4.0。

## 当前生产运行态（持久，IDE/扩展不更新即一直有效）
- renderer：`D:\Antigravity\resources\app\out\vs\workbench\workbench.desktop.main.js` = **patch6，23831768 字节**（六档 + 启动修复）。生成器 `evidence\patch-wb-claude6.mjs`（幂等：先还原干净态 `evidence\prod-wb-pre-claude.js`=23825890 再注入，顶部 MODELS 即唯一映射表）。校验 `evidence\verify-patch6.mjs`（每 uid×3、SIX-TIERS OK）。
- main.js = 8378330 标准 Gemini37 补丁态（备份 prod-main-pre-tpe.js，勿动）。
- zk 部署副本 `C:\Users\Administrator\.antigravity\extensions\zk-agent.zk-proxy-pro-9.9.529\vendor\bundled-origin\`：
  - `source.js`（含 `/__agtarget` 路由 + 实验 FAM 钩子/H2 tee；备份 .preb2b=315216、.precap=312067）。
  - `_ag-gemini37-compat.cjs`（含 `_agReadSelected` 旁路改道 + h2route/h2orig 录制；备份 .preb2b=4093；DEFAULT_TARGET_MODEL=gemini-3.8-flash-high，SOURCE_MODEL=gemini-2.5-pro）。
  - `_agcap\_ag-selected.json`（选择状态 last/bySid，120 分钟新鲜窗口）、`h2route.log`（改道铁证）。
- 启动器：cu 双击桌面 Antigravity 图标（wscript→Launch-StableHidden.vbs）；**启动默认 Gemini 3.8（已修复，不再默认 Claude）**。

## 架构（三段，全部已验证）
1. **workbench patch6**：六档 OPT 都借 `modelAlias:8`(RECOMMENDED，唯一能正常发 v1internal 的外壳) + 自定义 `__agUid:"claude-..."`（mUc 只读 modelAlias/value，__agUid 不进 LS wire，仅供上报）。5 处注入：nKc（下拉分组无条件 concat 六档）、dutE（visibleModelConfigs **条件** concat：仅 `(o?.cascadeModelConfigData?.clientModelConfigs||[]).length>0` 才追加，修启动早期 E 仅含合成项被当默认选中）、vKc（Xlt store，`a.concat(a.length?六档:[])`）、Kun（回显优先按 globalThis.__agSelLabel 的 label 精确匹配，解决 alias:8 共用回显串台）、I=setSelectedModelConfig（选中即 `fetch('http://127.0.0.1:8937/__agtarget?uid=__agUid||gemini-3.8-flash-high&label=...')`，无阻塞 .catch 吞错）。
2. **source.js `/__agtarget`**：在 `_mainHandler` try 块最开头插分支，OPTIONS 回 204+CORS，GET/POST 解析 uid/label/sid，读-改-写 `_agcap/_ag-selected.json`（{last,bySid}），回 200 + CORS `*`。CSP 已放行 connect-src `http://127.0.0.1:*`（renderer 沙箱无 fs，故走 HTTP 带外）。
3. **compat `_agReadSelected`**：rewriteRequestBody 占位符分支目标 = `extractModelFromUrl(url) || _agReadSelected(req) || DEFAULT_TARGET_MODEL`；先按 request.request.sessionId 查 bySid、回退 last、120 分钟外回退 null；thinkingBudget=-1 的 lift 在改 model 前统一做（六档 + 3.8 均生效）。

## B3 固化（待做，红线：动态映射归 zk 源码项目，部署副本仅临时取证）
- 源码项目 `D:\Desktop\Super-File\AI-IDE\AI\反重力\Antigravity-Injection`，插件源在 `plugins\zk-proxy-pro\vendor\bundled-origin\`：
  - **源码 source.js=312067（干净 precap 版，无 FAM/H2 tee、无 /__agtarget）**；**源码 compat=3773（旧，无 _agReadSelected）**。
  - 需 diff 部署副本 vs 源码，**只把正式逻辑落源码**：source.js 的 `/__agtarget` 路由；compat 的 `_agReadSelected` + 六档/3.8 改道 + thinkingBudget lift。**实验探针不带入正式 vsix**：FAM 钩子、H2 tee（h2probe 录制）、_ag-fam-matrix、h2orig 录制（h2route 可保留为精简日志或用调试开关）。
  - 落源码后 `node --check` + `npm test`（gemini-compat 等）+ `npm run build` 出 dist vsix；vsix 可先产出不强制重装（运行态继续用 529 副本，待扩展更新到 530 时安装新 vsix）。
- workbench patch6 注入做进 compat-manager 补丁生成器（StableMode.Core.psm1 的 workbench ConvertTo/ConvertFrom/Test 成套，离线喂 prod-wb-pre-claude.js 做往返断言），MODELS 映射表外置/集中，SOP 化。
- 清理：还原部署 source.js=precap、删 _ag-fam-matrix.cjs、清实验录制 _agcap（保留/正式化 _ag-selected.json 机制）；桌面/开始菜单图标确认 wscript vbs 接管；180s 无 CodeWindow unresponsive 验收。
- B4：SOP（未来加 Gemini 3.9/4.0 或新 Claude：从 fetchAvailableModels 取真实 uid → 改 patch6 顶部 MODELS 一行重跑 → 重启；后端 zk/compat 零改）+ 子 agent 七项 checklist 审计 + 同步 .agents/rules、plan。

## 回滚安全网（已验证）
- workbench 坏：`Copy-Item evidence\prod-wb-pre-claude.js D:\Antigravity\resources\app\out\vs\workbench\workbench.desktop.main.js -Force`；main 坏：用 prod-main-pre-tpe.js(8378330)；zk 坏：source.js.preb2b / _ag-gemini37-compat.cjs.preb2b 回拷。还原后 cu 双击 vbs（3.8 可用）。
- 重启/重打补丁前关全部 Antigravity/language_server（常残留 1 个需二次强杀，确认 ag=0 ls=0）。
- 辅助脚本：set-target.mjs <uid>（手动写旁路目标，后端验档用）、read-selected.mjs、scan-resp.mjs、tier-summary.mjs、extract-uids.mjs。
- cu 坐标：发送箭在底部工具栏行（对话后约 cu(980,856)）易点偏麦克风，**回车发送最稳**；下拉向下展开行 cu y：Opus H/M/L≈611/650/688、Sonnet H/M/L≈725/763/800（选择器 cu(675,489)）。

---

# 旧接续状态 (2026-10-04 02:45) · 旧版放行 Claude 5.5（方案 B）【已过时，仅存档】

> 完整过程/SOP/锚点见 `.agents/plan-旧版协议适配-新模型放行.md` 末尾「★B2 UI 层突破 + alias:7 证伪」章节。本节只给恢复任务所需的最小现场。

## 当前生产环境 = 安全可用基线（已回滚并实测）
- `D:\Antigravity\resources\app\out\vs\workbench\workbench.desktop.main.js` = **干净 Gemini37 补丁态 23825890 字节**（=备份 `evidence\prod-wb-pre-claude.js`，**无 Claude 注入**）。
- `...\out\main.js` = **8378330 标准 Gemini37 补丁态**（=备份 `evidence\prod-main-pre-tpe.js`）。
- cu 双击桌面图标（wscript→Launch-StableHidden.vbs）启动正常、认证约 15-20s 自动恢复、**Gemini 3.8 Flash (High) 实测发消息流式出字正常、IDE 不卡死**。
- 回滚命令：`Copy-Item evidence\prod-wb-pre-claude.js D:\Antigravity\resources\app\out\vs\workbench\workbench.desktop.main.js -Force`（main 同理用 prod-main-pre-tpe.js）。

## 任务与已攻克
- 目标：锁死旧版 Antigravity 1.20.6 不升级，放行今天新发布的 **Claude 5.5 六档** + 未来 Gemini 新模型；Gemini 3.8 只做恢复（一直能用）。
- **网络层已攻克（信心 10）**：官方 `daily-cloudcode-pa.googleapis.com` 的 `/v1internal:streamGenerateContent` 是统一网关，纯凭请求体顶层 `model` 字符串 uid 路由；Gemini schema 换 `model=claude-sonnet-5-5-high` 直接 HTTP 200、Gemini SSE、每帧 modelVersion=claude-sonnet-5-5-high、STOP（铁证 zk `_agcap\h2probe-req/resp-472.*`）。**零协议转换**。
- **UI 层已攻克显示/选中/回显**：下拉真身在 renderer `workbench.desktop.main.js`（不是 main.js）；根因 nKc 只渲染 modelSorts 中 name==="recommended" 分组。成功脚本 `evidence\patch-wb-claude4.mjs`（nKc+dutE+vKc 三处纯表达式 concat 注入），实测下拉出现并可选中 "Claude Sonnet 5.5 (High) New"、底部回显正常、过启动器自检、不卡死。

## 唯一卡点 + 下一步（B2-b renderer 旁路）
- **alias:7(AUTO) 已证伪（信心 9.5）**：选中 modelAlias:7 后主对话 "Working" 永久挂起（6 分钟+不出字，zk 无 h2orig、无新 streamGenerateContent rid）——AUTO 走级联非标准路径，不发主对话。其余功能别名 1/3/4/5/6 同理大概率不可用。
- 唯一能正常发 v1internal 的是 **alias:8(RECOMMENDED)**（3.8 已占用）。→ Claude 条目须也借 alias:8（LS 无法区分），再由**带外旁路**告诉 zk 当前选的是哪个 uid：
  1. 首选：workbench renderer 内 VSCode DI 拿 **IFileService 写盘** `_ag-selected.json`（sandboxed renderer 无 fs，此法绕开 CSP）；
  2. 次选：renderer fetch 127.0.0.1:8937 + zk 加 CORS 路由（先 CDP 测 CSP）；
  compat 按 body.request.sessionId 读盘覆盖 body.model（读盘热更有 _origin_canon 先例）。
- 待办：CDP 探针定带外通道 → patch5（OPT 改 alias:8+__agUid、注入六档、mUc 上报、Kun 回显校正）→ compat 读盘映射六档 uid（sonnet/opus 5-5 high/med/low）→ 抽测出字 → 外置映射表+SOP → B3 固化（还原 source.js、拆探针、出 vsix）→ B4 七项审计。
- zk 部署 529 的 compat 含本轮 h2orig 录制、source.js 含 FAM/H2 探针（均无害、不影响对话，B3 统一清理）。

---

# 历史接续状态 (2026-09-11 16:36)

## 核心进展

Antigravity IDE（基于 VS Code 的 AI IDE，安装路径 `D:\Antigravity`）四个阶段问题全部闭环：
1. **E盘换行符故障**：`extension.js` 被编辑器 LF→CRLF 致 agentSessions 服务注册失败，回滚 LF 版恢复；给 compat + injection 两项目加四层换行符防护并提交推送。
2. **D盘证书崩溃**：本地语言服务器自签证书 `cert.pem` 已于 2026-09-05 过期 → Node 端每秒报 certificate has expired → exthost 约35秒崩溃重启循环。修复：`NODE_TLS_REJECT_UNAUTHORIZED=0` + Chromium `--ignore-certificate-errors`。commit c21ba13。
3. **快捷方式接管 + 重装文档**：桌面 `Antigravity.lnk` 直连 exe 会崩；新增 `Invoke-StableShortcutTakeover` 自动扫描4个位置改写为兼容启动（wscript→VBS→pwsh→StableBootstrap）。commit a33428d。重装流程文档交付到 `D:\Desktop\脚本\Antigravity重装到启动使用流程.md`。
4. **启动慢性能优化（两轮，最新）**：桌面双击启动从 **20.8s 降到 3.7s**（共省17.1s）。
   - 第一轮（a4557c7）：`Test-RestartSafeExtensionContent` 里 `AuthSafePattern`（含3个反向引用）对 2.9MB extension.js 用 `[regex]::Matches` 全扫描需 8.0-8.5s（灾难性回溯），改为 `[regex]::IsMatch` 仅 0.5s。启动 20.8s→7.6s。
   - 第二轮（5662143）：StableBootstrap.ps1 第361行 Gemini37 模式下**无条件强制重打补丁**的 bug——只要 workbench.js 包含 `_agGemini37` 就把已匹配的 targetProfile 置 null，导致每次启动都走完整补丁流程（~4.2s）。修复：仅当 targetProfile 为 null（未匹配当前版本目标哈希）时才执行标记检查。健康态跳过补丁，启动 7.6s→3.7s。StableBootstrap 进程 5.45s→1.24s。

## 核心动机与背景 (Motivation & Background)

- 用户重装 IDE 到 D 盘后，点发送对话框闪一下不动 → 逐层定位到证书过期导致 exthost 崩溃循环。
- 修复后桌面双击启动需 20-30 秒 → 只读性能分析定位到正则灾难性回溯。
- 用户要求：重装后能自动注入、自动接管快捷方式、启动快、不破坏现有功能。

## 关键设计与实现 (Implementation & Decisions)

### 性能优化（a4557c7）
- **文件**：`scripts/StableMode.Core.psm1`，函数 `Test-RestartSafeExtensionContent`（约第1119-1126行）
- **改动**：`[regex]::Matches(...).Count` → `[regex]::IsMatch(...)`；返回式 `$early.Count -eq 0 -and $safe.Count -eq 1` → `-not $early -and $safe`
- **语义等价依据**：两模式均含唯一字符串字面量锚点（`"extension activate: unleash init"` / `"extension activate: sentry init"`），在 webpack 单文件打包的 extension.js 里不可能匹配2次，故 Count==1 等价于 IsMatch==true
- **验证数据**：`Test-RestartSafeExtensionContent` 9400ms→1196ms；完整启动（桌面双击→IDE窗口出现）20.8s→7.6s

### 证书绕过（c21ba13）
- `StableBootstrap.ps1` 启动 Antigravity.exe 前设置环境变量 `NODE_TLS_REJECT_UNAUTHORIZED=0`
- 启动参数加 `--ignore-certificate-errors`
- 证书文件：`D:\Antigravity\resources\app\extensions\antigravity\dist\languageServer\cert.pem`，CN=localhost，NotAfter 2026-09-05（已过期，靠客户端绕过）

### 快捷方式接管（a33428d）
- 函数 `Invoke-StableShortcutTakeover` 扫描4个位置：桌面、开始菜单、任务栏（如有）、项目内"稳定版.lnk"
- 改写目标为 `wscript.exe` + 参数指向 `Launch-StableHidden.vbs` → `pwsh.exe -NoProfile -File StableBootstrap.ps1`
- 原始快捷方式备份到 `backups\shortcuts\<时间戳>\`

### 换行符防护（两项目均已加）
- 四层防护：pre-commit hook、编辑器 .gitattributes、CI 检查、运行时 ConvertTo-Lf 强制归一
- 核心规则：**禁止修改 `extension.js` 的换行符**；该文件必须保持 LF

## 待办事项 (Next Steps)

- [ ] 用户可选择继续做方案 B（健康态缓存，预计 7.6s→~5s）：在 `Get-CompatibilityInstallStatus` 入口加文件哈希+时间戳缓存，健康态跳过结构检查
- [ ] 用户实测桌面双击启动速度确认 7.6s
- [ ] 远期：证书过期问题的根治方案（重新生成 cert.pem 或配置 IDE 信任本地 CA），当前靠客户端绕过

## 关键上下文

- **IDE 路径**：`D:\Antigravity\Antigravity.exe`，版本 2.5.5
- **compat 项目**：`D:\Desktop\Super-File\AI-IDE\AI\反重力\antigravity-old-compat-manager`（本次所有修改都在这里）
- **injection 项目**：`D:\Desktop\Super-File\AI-IDE\AI\反重力\Antigravity-Injection`（注入提示词等功能，本次未改代码，只加了换行符防护规则）
- **远程仓库**：https://github.com/Huo-zai-feng-lang-li/antigravity-old-compat-manager.git（main 分支）
- **git 代理**：`http://127.0.0.1:51081`（dotsvpn），push 用 `git -c http.proxy=http://127.0.0.1:51081 push origin main`
- **pwsh 版本**：用户系统 `pwsh.exe` = 7.6.5（`C:\Program Files\WindowsApps\Microsoft.PowerShell_7.6.5.0_x64__8wekyb3d8bbwe\pwsh.exe`）；Bash 工具会话默认 shell = Windows PowerShell 5.1，**执行项目脚本必须用 `pwsh -NoProfile -File`**
- **启动链路**：桌面 lnk → wscript.exe → Launch-StableHidden.vbs → pwsh.exe -NoProfile -File StableBootstrap.ps1 → 补丁/校验 → Start-Process Antigravity.exe（--remote-debugging-port=9000 --ignore-certificate-errors，前置 NODE_TLS_REJECT_UNAUTHORIZED=0）
- **已验证死路**：workbench ReadAllText→GetBytes→字符串哈希合并（2.8s，比流式哈希+单独ReadAllText慢13倍），禁止采用
- **用户偏好（已持久化）**：Windows 上执行 PowerShell 必须显式用 pwsh（PS7），不依赖 Bash 会话默认的 PS5.1
