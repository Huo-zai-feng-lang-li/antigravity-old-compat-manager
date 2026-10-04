# 旧版 Antigravity 1.20.6 协议适配 · 放行官方新模型（Gemini 3.8 high / Claude 5.5 全档）

## ★★★ 全部闭环完成（2026-10-04）

> 本节为最终落地状态，优先于下方早期计划。早期 Architecture 设想的“目录降级补占位 ID”最终被更简的“借壳 + 旁路”方案取代。

**四个目标全部达成，并经独立审计 + 干净部署 + GUI 复验**：
1. Gemini 3.8 恢复可用，启动默认 **Gemini 3.8 Flash (High)**；
2. Claude **Opus/Sonnet 5.5 各 High/Medium/Low 六档**全部放行、端到端出字（官方统一网关按 body.model 的 uid 路由，零协议转换；六档 uid 已与 fetchAvailableModels 逐字核对一致）；
3. 老模型保留、IDE 不卡死（启动不强选合成模型，dutE/vKc 条件 concat 双守卫）；
4. 未来新模型收敛为“改 `model-unlock/patch-workbench.mjs` 顶部一张 MODELS 映射表 + 重跑 `放行Claude六档.ps1 -ForceKill`”，后端通用透传通常零改动；完整手册见 `SOP-新模型放行.md`。

**最终方案（实际落地）**：前端 workbench 借 `modelAlias:8`(RECOMMENDED) 外壳注入合成下拉项（带 `__agUid`），选中经 renderer `fetch http://127.0.0.1:8937/__agtarget` 旁路落盘；zk 插件 compat 对主对话占位符 `gemini-2.5-pro` 按 `URL 模型名 > 旁路(bySid→last，120 分钟新鲜) > 默认 gemini-3.8-flash-high` 覆盖 body.model。

**关键产物**：
- 后端（Antigravity-Injection，git 已暂存 3 个改动文件）：`plugins/zk-proxy-pro/vendor/bundled-origin/source.js`（新增 `/__agtarget`：CORS/OPTIONS、空 uid 回 400、tmp+rename 原子写）、`_ag-gemini37-compat.cjs`（`_agReadSelected` 旁路 + thinkingBudget lift，去除实验录制）、`test/gemini-compat.test.js`（19 用例）；构建物 `dist/zk-proxy-pro-9.9.529.vsix`（不入 git）。
- 前端（本项目，随 git 入库）：正式工具链 `model-unlock/`（patch-workbench.mjs / verify-workbench.mjs / list-official-uids.mjs / fetchAvailableModels.json / assets 两个干净基线 / README）、一键 `放行Claude六档.ps1`、`SOP-新模型放行.md`。
- 运行态：529 扩展已用干净 vsix 文件级覆盖（source.js=314608、compat=6012，FAM/H2 探针与录制全清）；workbench 为六档注入态。
- 回滚：`backups/zk-529-pre-clean-20261004/`（本地、不入 git）、`model-unlock/assets/*.js` 前端基线。
- 质量：三文件 32 单测全过、双 `node --check`、只读独立审计（7 项 checklist + 2 红线，结论可交付，信心 8.5），并采纳中等级加固（ps1 进程匹配收紧到 D:\Antigravity、状态原子写、空 uid 400、补丁失败回滚）。

**文档同步（2026-10-04）**：README.md / README-稳定模式.md / Antigravity重装到启动使用流程.md / notes.md / .agents/rules/README.md / 本计划 / handoff.md / SOP 均已同步到“六档放行 + model-unlock 正式工具链 + 干净 vsix 部署”现状。

**已知遗留（非阻塞，详见 SOP 第七节）**：多会话 bySid 隔离前端暂未带 sid；前端上报失败暂静默回退 3.8；patch 未做进 StableMode.Core 启动自愈；Claude medium/low 档位靠独立 uid 区分（thinkingBudget=-1 是 Gemini 语义，对 Claude 冗余但六档均 200、无害）；插件版本已由 9.9.529 **bump 到 9.9.530 并 CLI 安装、529/528 进 .obsolete、GUI 复验（选 Low 落盘 claude-sonnet-5-5-low 并流式出字）通过、zk 已推送（release commit b313c86）**，该遗留项关闭。

---

> 复杂任务计划。用户已在「升级新版 / 维持旧版做适配」中二选一，明确选择：**维持旧版 1.20.6，做协议适配补丁**（2026-10-03）。
> 执行方式：分阶段、每阶段以真实抓包/发消息取证驱动，禁止脑补模型 ID 与 wire 字段。

## Goal

不升级 IDE（锁定真实安装 Antigravity **1.20.6**，Antigravity.exe / language_server 均为 2026-03-17 编译），在 zk 本地代理层做「目录降级 + 发消息路由」双向协议适配，让：
1. **Gemini 3.8（high 推理）** 能显示、能选中、能正常出字；
2. **Claude 全系列（5.5 Opus/Sonnet 各档）** 全部放行可用；
3. 老模型（Gemini 3.6/3.1、GPT-OSS）保持可用；IDE 不卡死、能正常进；
4. 「未来官方新模型（3.9/4.0…）跟进」收敛为**改一张映射表 + 一份 SOP（半自动）**。

> 已向用户如实说明并获认可：旧语言服务器是固定二进制，无法做到「未来模型 100% 自动、永不维护」；本方案把每次跟进成本压到「改映射表」级别。真正零维护只有升级新版（用户已暂不选）。

## Architecture（双向适配，挂在 zk origin 代理）

- **目录方向（官方→LS）**：zk `source.js` 拦 JSON-RPC `GetUserSettings / GetCascadeModelConfigs` 响应里的 `cachedCascadeModelConfigs`（JSON，非 protobuf，可改）。保留官方可解析模型；给数字 ID 被读成 0 的 Claude 5.5 各档补「稳定占位 ID」；把 tiered 3.8 补成旧 LS 能渲染的旧结构条目。占位 ID ↔ 真实字符串 uid 存外置映射表。
- **发消息方向（LS→官方）**：扩展插件 `_ag-gemini37-compat.cjs`（挂载点 `source.js:6990`，kind=`GEMINI_REST_CHAT`）。旧 LS 对所有 Gemini 发占位 `gemini-2.5-pro`；现逻辑从 URL 提模型名、回退写死 `gemini-3.8-flash-high`（该 uid 已被 tiered 取代 → 今天 404）。改为：按「占位 ID / 显示名 / 请求体」查映射表改写真实 uid；3.8 走 tiered 真实 uid + `thinkingBudget=-1`（high 满载，现有逻辑已提预算）。
- **前端 main/workbench（compat-manager）**：放弃 Gemini37 窄白名单（实证会把官方 12 模型在 LS 侧丢光，只剩 3.8 壳）。改为「全量透传 + 仅补官方缺失的 3.8 条目」（数据层 13 项、UI 13 项均已实测可行）。选择状态机**启动不强选、不悬空**占位模型（这是今日卡死根因，防卡死红线）。
- **固化**：compat-manager 新增「全量+适配」补丁模式；模型改写与映射表归插件项目 Antigravity-Injection（zk）；恢复图标 wscript→vbs 接管（证书双绕过固化）。

## Tech Stack

Node 本地代理（zk `source.js` / `_ag-gemini37-compat.cjs`，零依赖）、PowerShell 补丁模块（`StableMode.Core.psm1`）、CDP（9000）UI 验收、sqlite/leveldb 状态、Wireshark 级流量录制改由 zk 代理内录制。

## Global Constraints

- extension.js 必须保持 **LF**（项目最高红线）：写入用 `Write-Utf8Atomic -ForceLF`，禁用 Set-Content/Out-File/编辑器保存。
- 插件 publisher 固定 `zk-agent.zk-proxy-pro`；改 publisher 必须同步 bridge `AGENT_PRO_ID` 与 PSM1 `$prefix`。
- 分工边界：模型改写/动态映射/代理归**插件（Antigravity-Injection / zk）**；compat-manager 只做 bridge 部署、product 伪装、前端全量/补条目、备份自愈。
- 防卡死红线：**不在 workbench 动态改状态机/排序；启动不强制 setSelectedModel 到 alias/占位 ID**；启动回退官方默认有效项。
- 所有模型 uid、字段号、参数值必须抓包/官方证据，标注信心；拿不到标 [待验证]，不写死猜测值。
- 出墙代理 `127.0.0.1:51081`（version.dll 启动瞬间加载）；跑 ps1 一律 `pwsh -NoProfile -File`；复杂 JSON/中文写临时脚本或 node，不内联 pwsh。
- 每阶段以「真实选中 + 真实发消息出字」验收，不能只看列表显示。
- 重打补丁/重启前关闭所有 Antigravity / language_server 进程。

## File Structure

**插件侧（Antigravity-Injection 源码；部署到 `C:\Users\Administrator\.antigravity\extensions\zk-agent.zk-proxy-pro-9.9.529\vendor\bundled-origin\`）**
- 改 `_ag-gemini37-compat.cjs`：发消息真实模型路由（映射表 + tiered/high + 修 v1internal 下 URL 提取失效）。
- 建 `_ag-model-map.json`：`{ 占位ID/显示名 -> 真实 uid、思考档参数 }`，未来新模型只改此文件。
- 改 `source.js`（谨慎、最小）：目录响应适配（给 Claude 5.5/3.8 补条目）+ 完整流量录制开关（取证用，验收后可关）。

**compat-manager 侧（`D:\Desktop\Super-File\AI-IDE\AI\反重力\antigravity-old-compat-manager\`）**
- 改 `scripts/StableMode.Core.psm1`：新增「全量+适配」模式（main 全量透传+补 3.8；workbench 可选中但不强选）；复用现有备份/回滚/健康态。
- 复用 `runtime/OneLSAgentProxyBridge.cjs`（dao 桥接，LS→zk）。

**取证/验收（`evidence\`，非交付）**：流量录制解码、CDP 下拉/选中/截图、发消息出字核验脚本。
**文档**：本计划；`新模型跟进SOP.md`；同步 `.agents/handoff.md`、`rules/README.md`。

---

## Task 0：可观测链路 + 今日协议取证（go/no-go 闸门）

**Files**
- 改（临时插桩）：zk `vendor/bundled-origin/source.js`（加录制，写日志到 evidence）
- 复用：compat-manager bridge 部署（让 LS→zk）
- 产出：`evidence/protocol-20261003/` 下目录与发消息证据

**Interfaces（本任务产出供后续所有任务）**
- Produces：`model-map` 真值表（3.8 tiered 真实 uid + high 参数；Claude 5.5 六档真实 uid + 端点形态）；目录 JSON 中两类新模型真实结构；旧 LS 选中 id=0/占位模型时发出的请求字段。

- [ ] Step 1：部署 bridge 让 LS 走 zk（关进程后 Apply Gemini37，或手工放 dao cjs），确认 zk origin 端口（8937/8938）与 CDP 9000 可达。
- [ ] Step 2：在 source.js 目录注入点（~6284）与请求改写点（~6990）加录制：完整记录 GetUserSettings/GetCascadeModelConfigs 响应 JSON、GEMINI_REST_CHAT 的请求 URL+body、上游响应状态码+body（完整，不截断；尤其 404）。
- [ ] Step 3：启动 → 开下拉 → 选「Gemini 3.8 Flash (High)」发一句 → 选「Claude Sonnet 5.5 (High)」发一句；老模型 3.6 发一句做对照。
- [ ] Step 4：解码并回答 4 个问题，写入证据文件并标信心：
  1. 今天 3.8 的**真实可调用 uid**（`gemini-3.8-flash-tiered`？还是带档位变体）与 **high 档参数**（thinkingBudget=-1 是否够 / 是否需 reasoningLevel 或别的字段）；
  2. Claude 5.5 六档**真实 uid**（`claude-sonnet-5-5-low/medium/high`、opus 同构？）与发消息端点（`/v1internal:streamGenerateContent` 还是 `/v1beta/models/...`）；
  3. 旧 LS 选中「id=0 / 占位 id」模型时，发消息请求里 model/uid/显示名字段是什么——代理能否在发消息层识别并改写；还是 LS 在本地就拦截不发请求；
  4. GetUserSettings 目录 JSON 里 Claude 5.5 / 3.8 的真实结构，确认「JSON 层补条目」可行、补哪些字段前端能渲染能选中。
- [ ] **闸门判定**：
  - 若代理能在发消息层看到并改写请求 → 按主架构推进（占位 id + 发消息路由）。
  - 若旧 LS 对未知 id 本地拦截、根本不发请求 → 目录策略改为「复用 LS 认识的现有数字 id 段 + 靠请求体显示名路由」，Task1/2 据此调整后再继续。

## Task 1（M1）：Gemini 3.8 high 端到端恢复

**Files**：插件 `_ag-gemini37-compat.cjs`、`_ag-model-map.json`（建）；compat-manager `StableMode.Core.psm1`（main 全量+补 3.8、workbench 可选中不强选）。
**Consumes**：Task0 的 3.8 uid/high 真值。**Produces**：可复用的「映射表改写」compat 接口与「全量+补条目」前端模式。

- [ ] Step 1：compat 用 Task0 真值替换写死的 `gemini-3.8-flash-high`；修 v1internal 下 `extractModelFromUrl` 取不到模型名的问题（改为映射表/请求体/显示名兜底）；保留并校准 high（thinkingBudget 以 Task0 实测为准）。
- [ ] Step 2：compat-manager 落地「全量透传 + 补 3.8 条目」正式补丁（替换手改探针），workbench 仅在用户主动选 3.8 时记忆，启动回退官方默认。
- [ ] Step 3：真实发消息验收：下拉含 3.8 + 官方 12 项；选 3.8 出字、自报 high 推理、无 404；3.6 等老模型仍正常；启动 180s 无 CodeWindow unresponsive。

## Task 2（M2）：Claude 5.5 六档端到端

**Files**：zk `source.js`（目录补条目，最小改动）、`_ag-model-map.json`（加 Claude 六档映射）、`_ag-gemini37-compat.cjs`（Claude 路由，或新增同类 router）。
**Consumes**：Task0 的 Claude uid/端点、占位 id 可行性结论。

- [ ] Step 1：按 Task0 闸门方案，在 GetUserSettings 目录 JSON 给 6 个 Claude 5.5 条目补可区分、可选中的稳定标识，保留 quota/mime/tag 等元数据。
- [ ] Step 2：发消息层按显示名/占位标识映射到 `claude-...-5-5-low/medium/high`（opus、sonnet 各三档），确保不串模型。
- [ ] Step 3：验收：六档至少抽测 Sonnet low/high、Opus high 真实出字且身份正确；3.8 与老模型同时正常；不卡死。

## Task 3：固化为正式补丁模式 + 图标/证书接管

**Files**：`StableMode.Core.psm1`、`StableBootstrap.ps1`（如需）、插件源码与部署、快捷方式。
- [ ] Step 1：compat-manager 新模式接入备份/回滚/健康态跳过；移除全部手改探针与临时录制（或留默认关闭开关）。
- [ ] Step 2：插件改动落到 Antigravity-Injection 源码并部署到 9.9.529 扩展目录；`node --check`；集成测试 `tests/Test-CompatibilityInstallIntegration.ps1`；发布者一致性；extension.js LF 与目标哈希校验。
- [ ] Step 3：桌面/开始菜单/任务栏 Antigravity.lnk 恢复为 `wscript.exe "...\Launch-StableHidden.vbs"`（原始备份在 backups\shortcuts\）；确认 `NODE_TLS_REJECT_UNAUTHORIZED=0` + `--ignore-certificate-errors` 生效。
- [ ] Step 4：一键安装→点图标启动全链路验收：13+ 模型显示/选中/出字；无 certificate、无 unresponsive、无发送回弹。

## Task 4：未来新模型跟进 SOP + 独立审计

- [ ] Step 1：写 `新模型跟进SOP.md`：官方更新后如何用 Task0 录制脚本抓新目录/发消息 → 在 `_ag-model-map.json` 加映射 → 如何验收；明确「哪些自动、哪些必须改表」的边界。
- [ ] Step 2：按 AGENTS.md 七项 checklist 建子 agent 独立审计（测试是否弱化/硬编码、生产改动最小化与 API 契约、边界异常并发、覆盖率、安全、命名注释文档、性能）；父 agent 核验并处置建议。
- [ ] Step 3：同步 `rules/README.md`（模型策略表）、`.agents/handoff.md`、本计划勾选状态；按需提交（git 代理 51081）。

## Self-Review

- **Spec 覆盖**：3.8 high→Task1；Claude 全放→Task2；老模型/不卡死/能进→各任务验收+不强选；未来模型→Task4+映射表（诚实标注半自动边界）；证书图标→Task3。
- **占位符扫描**：所有真实 uid/wire 值刻意不在此写死，由 Task0 抓包产出（规则三要求）；计划已给出取证位置、命令意图与判定标准，非「待补充」式空泛。
- **一致性**：`_ag-model-map.json` 的键（占位 id/显示名）与值（真实 uid+档位参数）在 Task0 锁定后，Task1/2/4 共用同一 schema，落地时先定 schema 再写两处。
- **已知风险**：①旧 LS 可能本地拦截未知 id（Task0 闸门已备退路）；②tiered high 参数形态未知（Task0.1）；③Claude 走 v1internal 时的路由键未知（Task0.2/0.3）；④source.js 为第三方大文件，改动需最小且可回滚。

---

## Task0 实战结论（2026-10-03 深夜，决定性，推翻部分早期假设）

**抓包链路**：zk `proxyToCloud`（source.js:6548）h2c→h2 TLS，host `daily-cloudcode-pa.googleapis.com`。已在 source.js 装只读抓包插桩（锚点 `__agcap`，原件备份 `source.js.precap`），录制目录 `_agcap\`。

1. **目录接口是 `POST /v1internal:fetchAvailableModels`，响应是 gzip JSON（不是 protobuf）**，顶层 `models`(map) + `defaultAgentModelId` + `agentModelSorts` + `tieredModelIds` + 各 *ModelIds。完整解码存 `evidence\fetchAvailableModels-full.json`（37版）与 zk `_agcap\fam-seen.json`（31版）。前端下拉实际只渲染 `agentModelSorts[0].groups[0].modelIds` 列出的 uid。

2. **同一账号两次拿到不同目录（灰度/版本相关，机制待查，信心7）**：
   - 补丁/伪装新版态：**37 模型**，`default=gemini-3.8-flash-high`，含 3.8 high/med/low=**M318/M319/M320** + tiered=M322，3.7 三档 M298-300+tiered M301。
   - 真实旧版 1.20.6 态（官方main+仅dao）：**31 模型**，`default=gemini-3.6-flash-high`，**3.8 只有 `gemini-3.8-flash-tiered`(M322) 且不在 agentModelSorts、无 displayName**；3.7 仅 tiered(M301)；**Claude 5.5 六档都在 sorts**（opus/sonnet low/med/high = M400-M405，vertexModelId `claude-{opus,sonnet}-5-5@default`，thinkingLevel 1/2/3）。
   - 旧版 sorts 12 项 = 3.6 三档(M71/72/73→前端1071/1072/1073) + gemini-pro-agent(M16) + 3.1pro-low(M36) + Claude六档(M400-405) + gpt-oss(具名→342)。

3. **3.8 high 在完整补丁链路实测可用（铁证）**：补丁态启动后台请求 `model="gemini-3.8-flash-high"`、`thinkingConfig.thinkingBudget=-1`，响应 **200**、`modelVersion="gemini-3.8-flash"`、模型自报 "I am ... Gemini 3.8 Flash"、回"我是 Gemini 3.8 Flash"（cap rid 86）。**用户 14:53 的 404 来自"官方干净main+注入 alias:8 壳但无 bridge/zk/compat"的实验态**，不是补丁方案固有问题；早期"3.8 -high uid 被官方删除"的推断**已被完整目录证伪**（M318 在新版目录仍在）。

4. **旧 LS 模型身份 enum 边界 = `MODEL_PLACEHOLDER_M0..M150`**（二进制 strings 实锤，连续 151 个占位 enum 名；内置明文模型仅到 `claude-sonnet-4`/`claude-sonnet-4-5`，无任何 gemini-3.x/5.5 明文 uid）。新模型 M187/196/198/298-301/318-322/400-405 全部 >150。

5. **三次探针证伪"只改 placeholder 即可"（关键负结果）**：在 zk 拦 fetchAvailableModels JSON 改写（钩子已验证可缓冲/gunzip/改/gzip/回写，`_fam-diag.log` changed=1）：
   - claude-sonnet-5-5-high `M405→M150`（空占位）：前端仍 `model/0`；
   - claude-sonnet-5-5-high `M405→M73`（**已证明有效**的 3.6-low 占位，前端 3.6-low=1073）：Claude 5.5 high **仍 `model/0`**，3.6-low 仍 1073。
   - **结论（信心8.5）**：旧 LS 不是单按 placeholder M 值映射 id，而是按模型**字符串 uid（models map key / vertexModelId）查内置表**；新 uid（claude-sonnet-5-5-high 等）不在 3 月表里 → 一律落 0/丢弃。改 JSON 的 `model`(placeholder) 字段无效。

6. **修正后的真正架构 = 模型身份双向 NAT（在 zk）**：
   - 目录向：把新模型**整条身份伪装成旧 LS 内置认识的旧字符串 uid**（models map 的 key + agentModelSorts 里的 id + vertexModelId 一起改），`displayName` 保留新名（前端 label 来自 displayName），让 LS 查到非 0 旧 id、可选中；
   - 发消息向：LS 用旧 uid 发请求，zk compat 按"旧外壳 uid→真实新 uid"映射表改回（同现 `_ag-gemini37-compat.cjs` 思路，泛化为多模型 NAT）；
   - **硬约束/风险**：外壳池=旧 LS 内置 uid，数量有限（Claude 明文仅 sonnet-4/4-5，opus 旧 uid 待枚举），6 档能否各给一个可区分外壳、Anthropic Vertex provider/thinkingLevel 能否走通，均待验证。若外壳不足，档位可能要收敛为"每家族 1 个外壳 + thinkingLevel 参数"或仅放行部分档。

7. **3.8 落点**：旧版客户端稳定可拿到的是 `gemini-3.8-flash-tiered`(M322, thinkingBudget=-1 自适应含 high, recommended)，但需在目录向把它**加进 agentModelSorts + 补 displayName**才会进下拉；固定 high(M318) 仅新版/灰度目录出现，不作为依赖。tiered 自适应即官方"flash 档"推荐形态（tieredModelIds.flash）。

8. **下一步决定性实验（验证 NAT 成立与否）**：把 `claude-sonnet-5-5-high` 整条伪装成旧 uid `claude-sonnet-4-5`（map key + sorts id + vertexModelId 同步改，displayName 留 "Claude Sonnet 5.5 (High)"），重启看 n9a 是否变非 0、能否选中；选中发消息看 zk 是否抓到 model=claude-sonnet-4-5（若是→NAT 成立，compat 改回 5.5-high 即通；若 LS 本地拦截不发请求→走 Task0 闸门退路）。

**当前生产/环境现场（恢复时先读这里）**：
- 生产 4 bundle：`out\main.js` = **`evidence\probe-main-dump.js`**（官方干净 main + 仅 dao 桥接锚点 + n9a 埋点写 `evidence\runtime-probe-n9a.jsonl`）；workbench/extension/product = 官方备份（真实 ideVersion 1.20.6）；`app\dao-one-ls-agent-pro.cjs` 在位。
- zk `source.js`：含抓包插桩 + FAM JSON 改写探针（当前 `_remap = {claude-sonnet-5-5-high: M73}`，诊断写 `_agcap\_fam-diag.log`、解压目录存 `_agcap\fam-seen.json`）；原件 `source.js.precap`。
- IDE 探针态运行中（ag≈20, ls=1；启动偶发卡 1 进程，用 `evidence\robust-start.ps1` 自动重试，start-patched 带 TLS+9000）。
- 探针 main 生成器：`evidence\build-probe-main.mjs`（官方+dao）、`build-probe-dump.mjs`（再加 n9a 埋点）。还原官方基线用 `backups\stable-20260910T160253038Z\`；回补丁态用 `-Mode Apply -CompatibilityMode Gemini37`。
- 关键证据：`evidence\cap-decoded.txt`（37目录+3.8出字）、`fam-table.txt`（37目录对照）、`fam-seen-summary.txt`（31目录 sorts/tiered/Claude）、`ls-model-strings.txt`（M0-M150/旧Claude）、`runtime-probe-n9a.jsonl`（前端12项 choice 真值）。

### Task0 最终铁证（数据链全程打通，2026-10-03 16:1x）

- **前端病灶唯一定位**：完整 dump `evidence\runtime-probe-n9a-full.json` + 解析 `full-compare.txt`。每模型是 `exa.codeium_common_pb.ClientModelConfig`，Claude5.5 与 3.6 **唯一差异是 `modelOrAlias.choice.value`（0 vs 1071）**；Claude5.5 `disabled=false / isPremium=false / allowedTiers=[] / quotaInfo 正常(0.998) / provider=0` → **不是权限/Pro 锁**，zk 的 GetUserStatus field20/field4 解锁对此无效。
- **数字 id 由 LS 二进制分配、main.js 纯透传**：`out\main.js` 里 `r9a(e)` 遍历 `e.agentModelSorts[].groups[].modelIds` 取 `e.models[uid]`，调 `e9a(uid,entry)`；`e9a` 内 `modelOrAlias.choice.value = entry.model`（**直接透传，无任何 enum 转换**）；main bundle **搜不到 `MODEL_PLACEHOLDER_*` 字符串**。故 placeholder→数字的转换在 `language_server_windows_x64.exe`（内置槽位表 M0-M150，3月冻结），JS 侧无 enum 表可改。
- **codeium 数字只是 UI 槽位句柄；发消息用字符串 uid**：抓包铁证 streamGenerateContent 请求体 `"model":"gemini-3.8-flash-high"`（字符串 uid）。即 LS 内部维护「槽位/codeium id ↔ 当前 fetchAvailableModels 里该槽位 uid」，发消息翻回 uid。**NAT 只需让 LS 给新模型一个有效槽位 id，发消息 uid 可由 zk compat 改道。**
- **槽位映射是稀疏表**：M71/72/73→1071/1072/1073（3.6 high/med/low）、M36→1036（3.1pro-low）、M37→1016（3.1pro-high，非线性）；大量 M 是未发布空预留（借 M150 得 0）。LS 明文 uid 仅 `claude-sonnet-4`、`claude-sonnet-4-5`、`gemini-tool-calling`；3月的 Claude 4.6 走 placeholder 槽位（无明文 4.6 uid）。
- **zk BYOK 与官方槽位无关**：`_full_model_catalog.json`(108)/`_model_uid_map.json` 走 `https://server.codeium.com` 外接通道、用 modelUid 字符串/harnessUids，**无 codeium 数字 id（1071/1073 均 NOT FOUND）**，不能为官方 n9a 槽位提供外壳。
- **4 次改 JSON 证伪**（M405→M150、M405→M73、整条 uid 伪装 claude-sonnet-4-5+vertex+M150）：value 仍 0。推测 LS 对「uid ↔ 槽位」有一致性/已知 uid 校验；**尚未试「新 uid 配同家族活槽位」「旧 uid 配活槽位（非空预留 M150）」的正确组合**。
- **下一步最小决定性实验=探针矩阵**（在真实 31 目录仅追加 ~7 条、复制正常 Gemini 条目元数据，一次重启 dump n9a value）：P1 新uid`gemini-3.8-flash-high`+活槽M71；P2 同 uid+空槽M150；P3 旧uid`claude-sonnet-4-5`+活槽M71；P4 旧uid`claude-sonnet-4-5`+空槽M150；P5 具名旧uid`gemini-2.5-pro`+M71；P6 合成uid`probe-xyz`+M71；P7 新uid`gemini-3.8-flash-high`+近邻空槽M74。一次确定：①Gemini 新 uid 借活槽/空槽能否非0（决定 3.8 新增还是顶替）②旧 Claude uid 能否借槽激活（决定 Claude 可放档数）③纯槽位 vs uid 校验规则。
- **交付路径预判**：Gemini 3.8/3.9/4.0 同 provider NAT 高可行（借 Gemini 槽 + compat 改 uid，3.8-high 已实测 200 出字）；Claude 六档取决于矩阵是否给出可用 Anthropic 槽位，若不足需与用户对齐档位取舍（每家族 1 外壳+thinkingLevel，或仅放部分档）。

### 环境现场（16:1x，恢复先读）
- zk 部署 `source.js` **已还原干净 312067B（抓包/FAM 探针全拆，=源码版=precap）**；`_agcap\` 已清。
- 生产 `out\main.js` = `evidence\probe-main-dump.js`（官方干净+dao 桥+n9a 埋点，**新增完整 entry dump→`evidence\runtime-probe-n9a-full.json`**，仅首次写）；workbench/extension/product 官方 1.20.6；dao cjs 在位；IDE ag≈20/ls=1 运行中（不卡死）。
- **正式开发地=源码项目 `D:\Desktop\Super-File\AI-IDE\AI\反重力\Antigravity-Injection`**：`plugins\zk-proxy-pro\vendor\bundled-origin\source.js`（干净 312067，与部署 precap 一致）、`_ag-gemini37-compat.cjs`（3773B，已在树）；构建 `npm run build`→`scripts\build-vsix.mjs`（vsce 出 dist\zk-proxy-pro-9.9.529.vsix）；测试 `test\gemini-compat.test.js` 等（`npm test`）；dao 桥在 `vendor\bridge-patch\dao-one-ls-agent-pro.cjs`。正式改动落源码→node --check/npm test→构建/同步部署，勿再手改部署目录（仅临时取证可）。

### 探针矩阵结果（16:26，决定性 · 数据层路线判定为硬墙）

- 注入器 `_ag-fam-matrix.cjs`（部署临时，待拆）在真实 31 目录追加 6 条并加入推荐组，`_fam-matrix.log` 确认 `added=6 bytes 168082→208799`（确已改写下发）。6 条覆盖：新 Gemini uid+活槽 M71（P1）、新 uid+空槽 M150（P2）、**旧 uid `claude-sonnet-4-5`+活槽 M72（P3）、`claude-sonnet-4`+活槽 M73（P4，Claude 模板/Anthropic 元数据）**、合成 uid+M71（P5）、新 uid+近邻空槽 M74（P6）。
- **结果：n9a 仍只有 12 项，6 条探针被 LS 整条丢弃（无一进入 clientModelConfigs）**。r9a 对 sorts 里找不到于 `e.models` 的 uid 只 `console.warn not found` 不 add → 证明 LS 在解析 fetchAvailableModels 阶段就剔除了身份不被认可的条目。
- **5 次数据层实验一致（信心 9）**：改 placeholder（M150/M73）、整条 uid 伪装（claude-sonnet-4-5）、新增探针条目（含 LS 明文旧 uid + 有效活槽）全部无法获得有效可选 id。旧 LS 对目录持 **3 月冻结的严格模型身份白名单（uid + 配套 provider/placeholder 等一整套 enum）**；真实下发的新 uid 条目被宽容保留但 `model=0`，zk 新增/改名条目被严格丢弃。`claude-sonnet-4`/`claude-sonnet-4-5` 在 binary 中疑似状态检查串（相邻 `...invalid`/`...available`），并非可用对话模型 uid。
- **main.js 层（JS）可硬改**：r9a/e9a 是 JS，可 patch 强制给条目赋有效 codeium id / 手动注入条目，使 UI 可显示可选中；但**发消息**时 LS 按 codeium id 反查 uid 并按该 id 的 provider 协议构造请求。
- **同 provider（Gemini）改道已实测成功**：Gemini37 补丁链路中 LS 发 Gemini 占位 uid、compat 改写成 `gemini-3.8-flash-high` 后 **200 出字、模型自报 3.8**（cap rid86）——这就是「借 Gemini 身份 + zk 改 uid」同协议 NAT 成立的铁证。Gemini 新模型（3.8/3.9/4.0）高确定性可交付，剩余工作是前端稳定显示/不卡死/尽量保留老模型（顶替现有 Gemini 槽位，或找到当前未占用的有效 Gemini codeium id）。
- **Claude 跨 provider 是硬边界**：旧 LS 12 个有效项里**没有任何有效 Anthropic codeium id**（Claude 5.5 全 0）；借 Gemini/GPT 的 id 会让 LS 按 Google/OpenAI 协议与端点构造请求，zk 必须实现 **Google(v1internal streamGenerateContent)→Anthropic Vertex 的请求体/鉴权/端点/SSE 响应全协议网关**，工作量大、脆弱、不保证六档全成、后续每次官方改动都要跟。轻量 NAT 对 Claude 不可行。
- **三方案需用户拍板**：A=先交付 Gemini 新模型 NAT（稳、半自动，3.8 立刻可用），Claude 暂缓（走 zk BYOK 外接或日后升级）；B=立项做跨 provider 协议网关硬攻 Claude（重/不保证/维护贵）；C=升级新版 IDE（Claude/Gemini 官方原生支持、最干净，但放弃锁死 1.20.6，用户此前已否决）。
- **环境现场（16:26）**：部署 `source.js` 含矩阵注入钩子（探针被 LS 忽略，官方 12 项正常、不卡死；待随正式方案拆除并还原 312067）；`_ag-fam-matrix.cjs` 临时在位；生产 main=`probe-main-dump.js`（含完整 n9a dump）；IDE ag≈20/ls=1 运行中。

---

## 用户决策（2026-10-03 16:3x）= 方案 B：硬攻 Claude，Gemini 一并交付

用户在 A（仅 Gemini）/B（硬攻 Claude 跨协议）/C（升级新版）中**明确选 B**。Gemini NAT 仍按高确定性路径交付，Claude 立项攻关。

**先取证再写网关（规则三，不脑补协议）**。两个可能大幅简化的假设须先证实/证伪：
- H1：旧 LS 3 月既已支持 Claude 4.6（补丁白名单 label 为证），其二进制**自带 API_PROVIDER_ANTHROPIC_VERTEX 请求构造分支**；若能把模型身份导向该分支，LS 自己发 Anthropic 形态，zk 只改 uid。
- H2：官方 `v1internal:streamGenerateContent` 是**统一 schema 网关**（所有模型同一请求体，靠 model 字符串 + provider 标志由后端路由），若真，则 Claude 与 Gemini 同构，仅需 uid/provider 字段改道。
- 仅当 H1/H2 皆否，才实现完整 Google→Anthropic 请求/鉴权/端点/SSE 响应转换网关。

### Task B0：Claude 协议取证（go/no-go，先做）
- B0.1 本地静态（零风险）：①完整 dump 37 目录 Claude 5.5 条目全字段（`evidence\fetchAvailableModels-full.json`，找 endpoint/harness/provider/请求模板线索，产出 `evidence\claude-entry.txt`）；②扫 LS binary 的 Anthropic 痕迹（端点路径、`v1/messages`、anthropic 字段、API_PROVIDER_/MODEL_PROVIDER_ enum、Claude 4.6 触发 id，产出 `evidence\ls-anthropic.txt`）；③读 zk 外接api（`外接api/core/cascade_wire.js`/`adapters.js`/`zk_router.js`）是否已有可复用 Anthropic wire 代码。
- B0.2 动态（关键）：patch main.js r9a/e9a，把一个 Claude 项的 value 从 0 硬改为有效 codeium id（临时借壳，必要时临时移走同 id 老项避免冲突），UI 选中真实发消息，zk 抓 LS 实际发出的**端点 + 请求体 schema + model/provider 字段 + 响应/报错**——一锤定音 H1/H2。
- B0.3 仅当 B0.2 拿不到真实 Anthropic 请求模板：临时**并行**（不覆盖 D:\Antigravity 旧版）装一个新版 Antigravity 到临时目录，同账号登录、经代理抓一次 Claude 5.5 请求；需用户授权安装/登录，抓完可删。

### Task B1：Gemini 3.8 同协议 NAT 正式落地（先交付，NAT 框架首例）
- main 侧稳定显示 3.8（可选中、启动不强选、不卡死）；zk compat 按外置映射改道真实 uid + high budget；真实出字验收；尽量保留老模型（顶替 vs 唯一空 id 依 B 系列取证结论定）。

### Task B2：Claude 放行（依 B0 结论选实现路径）
- 若 H1/H2 成立：与 Gemini 同构（main 身份注入 + zk uid/provider 改道），逐档（先 Sonnet low/high、Opus high）真实出字、自报身份正确、不串模型。
- 若皆否：实现跨协议网关（请求体/鉴权/端点/SSE），明确告知用户工作量与维护成本，档位不足时按"每家族 1 外壳 + thinkingLevel"降级并对齐。

### Task B3：固化到源码项目
- 改动落 `Antigravity-Injection`（source.js / compat / 新 router / `_ag-model-map.json` 外置）；`node --check` + `npm test`（含 gemini-compat.test.js，必要时新增 claude 用例）+ `npm run build` 出 vsix；compat-manager 侧正式"全量+适配"模式；恢复图标 wscript→vbs、证书双绕过；**拆除全部临时探针**（还原 source.js 312067、删 `_ag-fam-matrix.cjs`/抓包插桩/`_agcap`、生产 main 去埋点）；180s 无 CodeWindow unresponsive 验收。

### Task B4：SOP + 独立审计 + 文档
- 未来模型（3.9/4.0/Claude 新版）跟进 SOP（改映射表为主）；子 agent 按 AGENTS.md 七项 checklist 独立审计；同步 `rules/README.md`、`.agents/handoff.md`、本计划勾选；按需 git 提交（代理 51081）。

### 用户事实校准 + enum 数字表逆向 / H1 证伪（16:4x）
- **用户明确**：Gemini 3.8 **一直都能用、不是今天新模型**（今日 404/消失是我中途实验态所致，最终按"恢复可用"处理，不做跨版本攻关）；**Claude 5.5 才是今天新发布、旧版完全没有的模型，攻关唯一焦点 = Claude 5.5**。
- **重要机制（读 compat 确认）**：LS 主对话请求体顶层 `model` 统一写占位符 `gemini-2.5-pro`，真实模型靠 URL `/models/{m}:streamGenerateContent`；但 v1internal 路径不含模型名 → compat `extractModelFromUrl` 返回 null → 回退 `DEFAULT_TARGET_MODEL`（当前=gemini-3.8-flash-high）。**这正是"3.8 一直能用"的实现：compat 把 v1internal 主对话强制改道 3.8-high + thinkingBudget→-1。**
- descriptor 提取（`extract-enum-numbers.mjs`/`dump-anthropic-hex.mjs`，布局 `12 len 0a namelen name 10 varint`）校准：M0=1000、M50=1050、M71/72/73=1071/72/73、M74=1074、M150=1150、M36=1036、M37=1037（descriptor 原值；前端 3.1pro-high=1016 是另一具名映射）、GEMINI_2_5_PRO=246、GPT_OSS=342。
- **H1 证伪**：`MODEL_ANTHROPIC_ANTIGRAVITY_RESEARCH(_THINKING)`/`MODEL_ANTHROPIC_COMPATIBLE`/`MODEL_VERTEX_COMPATIBLE` 在二进制里是 field5(`0x2a`) 重复字符串名单（兼容/分组配置），**非带数字 Model enum 值，旁无 `10 varint`** → 旧 codeium Model 数字 enum（1000–1150+少量具名）**无任何 Anthropic 编号**。LS 有 Anthropic 代码（max_tokens/thinking_level/API_PROVIDER_ANTHROPIC_VERTEX/GetHasAnthropicModelAccess）但目录层未绑定可选数字 id，无法借壳走 LS 原生 Claude。
- `claude-sonnet-4(-5)` 两处均为日志/错误模板拼接（`...invalid bit size...`、`ratio: %s...@20250929error...`），非 uid。
- 6 次目录改写 + enum 逆向一致：**数据层无法给 Claude 身份；唯一路径 = zk 网关（用户选定 B）**。
- **H2 判别实验（B0.2，进行中）**：临时把部署副本 compat 的 `DEFAULT_TARGET_MODEL` 改为 `claude-sonnet-5-5-high`（Gemini schema 其余不动），在 proxyToCloud 录请求/响应，IDE 发一条主对话：200 出 Claude 内容=H2 成立（网关仅改 model/provider，极轻）；返回 anthropic 专用 schema/端点错误=做双向转换（错误体给字段线索）。源码项目 compat 不动，测完还原。

### ★H2 实验结果（01:21，决定性，信心 10）：统一网关，零协议转换
- 启动要点：工具后台 `Start-Process` 起的 IDE 窗口会 **DWM cloaked 不可见**（进程活、rect 正常、任务栏无按钮、任务视图无卡片、单虚拟桌面）；**必须经 vbs 交互式启动**（cu 双击桌面图标 = 真人）窗口才正常。vbs 当时 blocked 于"无法识别 main.js 模型过滤结构"，因生产 main 是 n9a 埋点探针版；**恢复官方 main（backups\stable-20260910...\769F675ABDD4-main.js，8376223B）后 vbs 重打 Gemini37 补丁启动成功**，补丁态默认/显示 **Gemini 3.8 Flash**（再次印证 3.8 一直可用 = Gemini37 compat 改道）。
- 主对话 **rid472**：UI 选 Gemini 3.8 Flash，zk 把 body.`model` 改成 `claude-sonnet-5-5-high`（其余 Gemini schema 全保留，thinkingBudget=-1），POST `/v1internal:streamGenerateContent?alt=sse` → **HTTP 200、text/event-stream 正常流式中文出字、无报错**；**每个 SSE chunk 的 `modelVersion` 均为 `claude-sonnet-5-5-high`**，`responseId=req_vrtx_011CffgtcvTiBucpyDd32NVo`（Anthropic 风格），finishReason STOP，token 计量正常（prompt 26290/completion 63）。
- **结论**：v1internal 是**统一网关**，纯凭请求体**顶层 `model` 字符串 uid** 路由（`gemini-*`/`claude-*` 都认），服务端完成 Gemini schema ↔ Claude 适配并以 Gemini SSE 返回。**无需任何 Anthropic 协议/鉴权/端点/SSE 转换**。方案 B 从"跨协议重网关"**降级为与 Gemini 完全同构的 uid 改道**（现有 compat 已在做）。
- 请求体顶层 keys=`project,requestId,request,model,userAgent,requestType`；`model`=真实 uid 字符串；**无 apiProvider/modelProvider 字段**；thinkingConfig 在 `request.generationConfig.thinkingConfig`。附属 lite 请求（标题/摘要）`model=gemini-3.1-flash-lite`（LS 直接写真 uid，不走占位符）。
- 证据：`_agcap\h2probe-req-472.json`、`h2probe-resp-472.txt`（modelVersion=claude-sonnet-5-5-high 铁证）；提取脚本 `evidence\extract-h2req.mjs`。
- **剩余唯一工程 = UI 下拉身份（B2 核心）**：让 Claude 5.5 六档 / 未来新 Gemini 在旧 UI 显示且可选中，并让 zk 按"用户选中的真实 uid"改道 body.model（而非写死 DEFAULT）。下一步取证：增强探针录 `req.url`(含 query) + compat 改写**前**原始 body，UI 分别选 3.6-high / 3.1-pro 各发一条，定位 LS 在 v1internal 携带"UI 选中模型"的字段（URL query / body 子字段 / 会话级 cascade 绑定）；若主对话确实写死占位符不带选择，则需前端 patch 把选择注入请求。

### B0 收尾：请求只认 model 字符串 + alias 是枚举（信心 10）
- 对比 rid332（真实 id，model=gemini-3.6-flash-high）与 rid472（alias:8）：请求结构**完全同构**，模型身份**仅顶层 `model` 字符串**，无 codeium id / alias 编号 / provider 字段；`request` 子对象仅 contents/systemInstruction/tools/toolConfig/generationConfig/sessionId。脚本 `evidence/inspect-req-model-fields.mjs`。
- **ModelOrAlias proto（LS descriptor hex 铁证，dump-alias-descriptor.mjs）**：oneof 两字段**均为 ENUM(type=0x0e)**：field1 `model`→enum **Model**；field2 `alias`→enum **ModelAlias**。**alias 是整数枚举、不是 string → "字符串 uid 直通 alias"方案 B2-c 证伪**。
- **ModelAlias enum 值**：UNSPECIFIED=0、CASCADE_BASE=1、(2 缺)、VISTA=3、SHAMU=4、SWE_1=5、SWE_1_LITE=6、AUTO=7、**RECOMMENDED=8**（补丁 alias:8 即 RECOMMENDED）。
- 补丁借壳机制（StableMode.Core.psm1 Ensure-StableCatalogAliasCompatibility + n9a）：官方 recommended 新模型无 Model 数字 id → 编码器统一改 `recommended?{case:"alias",value:8}:{case:"model",value:0}`；白名单 `Gemini37Allowlist` 现含 "Gemini 3.8 Flash (High)"；`_agSeenChoices` 按 choice 去重；Db 启动默认 alias:8；运行时 cascade 仅 1 项（`evidence/runtime-cascade.json` 铁证：label=Gemini 3.8 Flash High、choice alias:8、isRecommended）。
- 外壳供给：有效 model id≈6-7 个（1071/72/73=3.6 三档、1016/1036=3.1 两档、342=gpt-oss、246=2.5pro；选中会发**真实 Gemini/GPT uid**=占用老模型）+ alias 8 个具名功能别名（LS 语义绑定，可能走非 v1internal）。**纯借壳方案 B2-a 稀缺/混乱/牺牲老模型/不可持续，否决**。

### ★B2 架构决策：前端注入条目 + 文件旁路上报 + zk 读盘映射（B2-b）
- 这是唯一不抢稀缺 enum 外壳、不牺牲老模型、未来新模型"改一张表"即可扩展的可维护方案。
- 机制：
  1. **前端补丁（out/main.js，Node 环境可 fs）注入目标条目表**：Gemini 3.8 Flash High 保留 alias:8（官方 recommended）；Claude Opus/Sonnet 5.5 各三档分配**互不相同的合法 alias 值**（拟 1/3/4/5/6/7）+ 正确 label（如 "Claude Sonnet 5.5 (High)"）；按 e9a 真实结构构造 ClientModelConfig 并入 clientModelSorts 分组；放开/改造按 choice 去重。
  2. 补丁内维护 `choice → 真实 uid` Map；hook `setSelectedModel`（Db 已被补丁 hook，沿此挂），用户选中即 `fs.writeFileSync` 写 zk 扩展目录 `_ag-selected.json` = {choice,uid,label,provider,ts}。
  3. **zk compat 读盘热更**（沿用现有 _origin_canon 磁盘热更先例），主对话覆盖 body.model=选中 uid；thinkingBudget=-1 已被 rid472 证明 Claude high 接受（**暂不需要 thinkingLevel 转换**，med/low 后续微调）；Gemini 推荐档未来改为**从官方目录动态取 recommended uid**，去掉写死 DEFAULT。
- 条目表外置 JSON（label/uid/provider/档/alias 值），未来 3.9/4.0/Claude 新版只改这张表 + SOP。
- 风险/实测点：①合成 ClientModelConfig 须照抄 e9a 真实字段结构；②选 alias:1/3/4/5/6/7 时 LS 是否仍正常发 v1internal（不卡死/不换协议/不报错）需逐个实测；③setSelectedModel hook 确切位置；④红线：不动 workbench 状态机/排序、启动不强选 setSelectedModel、官方 main 备份可一键回滚。
- 推进法（小步可回滚）：先最小可行——注入 **1 条**合成 Claude（借 alias:7）跑通「下拉显示→选中→写盘→zk 改道→200 出字」，再复制六档 + Gemini 表 + 外置映射 + SOP。

---

### ★B2 UI 层突破 + alias:7 证伪（2026-10-04 02:4x，workbench renderer）

**A. 下拉 UI 真身 = renderer `workbench.desktop.main.js`（不是 main.js）**
- main.js 的 tPe 是另一份不被下拉使用的拷贝（在 main.js 注入 option 能过自检但下拉无变化，check-bundle.mjs 定位）。模型下拉 React 组件全在 `out/vs/workbench/workbench.desktop.main.js`（23.8MB）。
- 渲染链（workbench 变量名）：NIo(透传)→oKc(容器,`r=iKc(modelOptions,modelSorts)`)→iKc→**nKc**；浮层 hKc 先渲染固定标题 "Model" 再 `groups.map`。
- **nKc 根因（决定性）**：`nKc=(t,e)=>({groupName:"Recommended",options:xi(()=>{let i=t.find(n=>n.name.toLowerCase()==="recommended");return i?(i.groups[0].options||[]).filter(n=>!e.some(s=>s.label===n.label)):[]})})` —— **只渲染 modelSorts 里 name==="recommended" 的那一个 sort 的 options**；新建 name:"Claude" 分组被完全忽略（前 3 版补丁不显示的根因）。
- 两个 NIo 实例：vKc(@12534475,用 Xlt store,setSelectedModel 仅传 p.value) 与 **@13318037（dut 组件 @13317050，setSelectedModel=E=setSelectedModelConfig→mUc 认 option.modelAlias；主 Agent 输入框实际走这条）**。

**B. 成功补丁 patch4（显示+选中+回显全部通过）**
- 脚本 `evidence\patch-wb-claude4.mjs`（幂等：先 Copy `evidence\prod-wb-pre-claude.js`=23825890 干净 Gemini37 补丁态→生产 workbench，再打 3 处纯表达式 `.concat([内联 option 字面量])`，复制成 .mjs `node --check` 自检）。
- 三处锚点：①**nKc** recommended options 整体 `.concat([OPT])`（核心，让浮层显示）；②dut visibleModelConfigs(E) `.concat([OPT])`（扁平/搜索集合）；③vKc `modelOptions:a.concat([OPT])`（modelSorts 不动）。
- OPT 字面量（UI 原型版 modelAlias:7）：`{label:"Claude Sonnet 5.5 (High)",value:0,modelAlias:7,disabled:!1,supportsImages:!0,supportedMimeTypes:new Map(),betaWarningMessage:"",isBeta:!1,pricingType:0,description:"",quotaInfo:{remainingFraction:1,resetTime:{seconds:"0",nanos:0}},tagTitle:"New",tagDescription:""}`。
- 实测：下拉出现 "Gemini 3.8 Flash (High)" + "Claude Sonnet 5.5 (High)　New"；点 Claude 后底部回显 "Claude Sonnet 5.5 (High)"、下拉关闭、过 bootstrap 自检、不卡死 → 证明主路径=dut/mUc 认 modelAlias。
- **启动器红线（再确认）**：workbench 注入必须用「表达式内 .concat(内联字面量)」，**不可**在逗号连接的声明链里插以分号结尾的独立语句（`globalThis.x=...` 会截断 let/const 绑定链，bootstrap `node --check` 报「workbench JavaScript 语法检查失败」blocked）。Test-Gemini37WorkbenchContent 只校验固定锚点存在性/计数，非锚点纯表达式注入在 ConvertFrom/ConvertTo 往返中存活且幂等。

**C. ★alias:7(AUTO) 证伪（信心 9.5）：不能用作模型外壳**
- 选中 Claude(modelAlias:7) 发消息 → UI "Working" **持续 6 分钟以上不出字、不报错、不回弹**；zk compat 录制点 `_agcap\h2orig.log` **始终不生成**；H2 tee 无新 streamGenerateContent rid（最新仍 rid472/490）；`_fam-matrix.log` 只有周期性 fetchAvailableModels。
- 结论：**ModelAlias.AUTO(7) 使 LS 走级联自动路由的非标准路径，不发 v1internal streamGenerateContent 主对话（在 LS 内部挂起）**。CASCADE_BASE/VISTA/SHAMU/SWE_1/SWE_1_LITE(1/3/4/5/6) 同为具名功能别名，大概率同样不适合作模型外壳（未逐个测，性价比低且语义脏）。
- **唯一已验证能正常发 v1internal 主对话的是 alias:8(RECOMMENDED)**（3.8 用它，rid332/rid472 同构、正常出字）。→ Claude 条目必须也借 **alias:8**（与 3.8 同 choice 外壳，LS 无法区分、行为=正常 streamGenerateContent），区分「当前选 3.8 还是 Claude」**只能靠带外旁路（B2-b）**。

**D. B2-b 旁路的关键修正：在 renderer(workbench)，不是 main.js**
- 下拉/setSelectedModel 在 **workbench renderer（sandboxed，无 Node fs）**，原计划「main.js Node 环境 fs.writeFileSync 写 _ag-selected.json」**不适用**。
- Claude option 改 `modelAlias:8` + 自定义字段携带 uid（如 `__agUid:"claude-sonnet-5-5-high"`）；在 dut setSelectedModelConfig（mUc）选中合成项分支触发带外上报。
- 候选带外通道（下一步先探针选型，勿直接硬改）：
  1. **workbench 内 VSCode DI 拿 IFileService 写盘（首选，绕开 CSP/无 fs）**：注入模块作用域取 IFileService，选中即写 zk 目录 `_ag-selected.json`={uid,label,sessionId,ts}；compat 主对话按 body.request.sessionId 查盘覆盖 model，查不到回退 DEFAULT。先 CDP 运行时验证注入代码能拿到 fileService 并写盘。
  2. renderer `fetch('http://127.0.0.1:8937/__agtarget')` + zk source.js 加 CORS 路由：风险=Electron CSP connect-src 可能拦（先 CDP 实测）。
  3. 主进程/preload IPC：成本最高，最后选。
- compat 读盘热更有先例（_origin_canon）；按 sessionId 绑定防多会话串话，单活跃会话可先「全局最近选择」。
- **回显歧义**：3.8 与 Claude 都 alias:8 时 Kun(currentModelConfig 按 modelAlias find) 命中第一个（3.8）→ 选中 Claude 高亮可能跳 3.8；需在 Kun 匹配加按 __agUid/label 二次匹配，或由旁路状态校正（列入补丁）。

**E. 环境现场（本轮结束，已回滚安全基线）**
- 生产 workbench=**`evidence\prod-wb-pre-claude.js`（23825890，干净 Gemini37 补丁态，无 Claude 注入）**；main=**8378330 标准 Gemini37 补丁态**；经 cu 双击 vbs 启动正常、认证自动恢复、**3.8 实测发消息流式回复正常（回 "OK"）**、不卡死、无 Claude 卡死入口。
- 回滚：`Copy-Item evidence\prod-wb-pre-claude.js D:\Antigravity\resources\app\out\vs\workbench\workbench.desktop.main.js -Force`。
- 重现 Claude UI 原型：`node evidence\patch-wb-claude4.mjs`（**注意 modelAlias:7 版仅供 UI 原型，选中会卡 Working；正式版须按 D 改 alias:8 + 旁路**）。
- zk 部署 529：compat `_ag-gemini37-compat.cjs` 仍含本轮加的 fs/path + h2orig 录制（无害，仅 append 日志，DEFAULT 仍 gemini-3.8-flash-high）；source.js 含 FAM 钩子/H2 tee（只录制/改 FAM，不影响对话）——B3 统一清理。
- CDP（cu 双击 vbs 实例）：`http://127.0.0.1:9000/json`，主窗口 page id `CF43067EF6CCDFF132F367E5FE30D79A`。
- 逆向脚本：inspect-nio/inspect-gkc/inspect-ikc/inspect-store/inspect-hooks*.mjs（渲染链）、check-bundle.mjs（定位 UI 在 workbench）。

**F. 下一步（B2-b 最小闭环，建议上下文充裕时做）**
1. CDP 探针：workbench 注入代码能否拿 IFileService 写盘（或本地 fetch 是否被 CSP 拦）→ 定带外通道。
2. patch5：OPT 改 modelAlias:8 + __agUid；nKc/dutE/vKc 注入六档；dut mUc 选中合成项→带外上报；Kun 回显校正。
3. compat：读 `_ag-selected.json`（按 sessionId）覆盖 body.model；六档 uid：sonnet=`claude-sonnet-5-5-{high,med,low}`、opus=`claude-opus-5-5-{high,med,low}`（rid472 已证 high 200；med/low 抽测，thinkingLevel 暂沿用 thinkingBudget=-1）。
4. 抽测 Sonnet low/high、Opus high 真实出字且自报身份正确；3.8/老模型并存正常；再复制 Gemini 未来档表 + 外置 JSON + SOP；进 B3 固化 / B4 审计。

---

### ★★ B2-b 六档端到端闭环 + B3 后端固化完成（2026-10-04 06:4x）

**带外通道选定 = renderer 本地 HTTP fetch（非 IFileService）**：CDP 取证 workbench CSP meta `connect-src` 含 `http://127.0.0.1:*`；renderer 沙箱无 Node fs（window.process 无 mainModule/require），但 fetch 可达 zk（普通 GET 挂起=TCP 通，只需专用路由）。

**最终前端补丁 = `evidence\patch-wb-claude6.mjs`（生产 workbench 23831768，5 处注入，幂等从 prod-wb-pre-claude.js 还原再打 + node --check）**：
- 六档 OPT 全借 `modelAlias:8` + `__agUid:<真实uid>`；nKc 无条件 concat（下拉显示）、**dutE 条件 concat（仅 `(o?.cascadeModelConfigData?.clientModelConfigs||[]).length>0` 才追加，修启动早期 E=[Claude] 被当默认选中的 bug，启动默认回 3.8）**、vKc `a.concat(a.length?六档:[])`、Kun 按 globalThis.__agSelLabel 的 label 精确匹配（修 alias:8 共用回显串台）、I=setSelectedModelConfig 选中即无阻塞 `fetch 127.0.0.1:8937/__agtarget?uid=__agUid||gemini-3.8-flash-high&label=...`。
- 校验 `evidence\verify-patch6.mjs`（六 uid 各×3、SIX-TIERS OK）。

**zk 两段（部署 529 已验证）**：source.js `_mainHandler` try 开头插 `/__agtarget`（CORS+读改写 `_agcap/_ag-selected.json` {last,bySid}）；compat 加 `_agReadSelected`（bySid→last、120 分钟新鲜窗口），目标解析 `URL模型 || 旁路 || DEFAULT 3.8`，thinkingBudget=-1 lift 在改 model 前。

**★uid 关键修正（404 教训）**：后缀是 **`-medium` 全称，不是 `-med`**（-med 官方 404，rid1590；改 -medium 200）。真实 uid 取自 `evidence/fetchAvailableModels-full.json`：claude-{sonnet,opus}-5-5-{high,medium,low}。

**验收铁证（信心 10）**：六档后端 status=200、每帧 `modelVersion=<uid>`、responseId=`req_vrtx_`（`evidence\tier-summary.mjs` 汇总；zk `_agcap/h2probe-resp-*.txt`）；h2route.log 六档 target 齐全；GUI 实测 Sonnet High/Opus High/Sonnet Medium 选中→`_ag-selected.json` 上报正确 uid→流式出字不卡死；切回 3.8 正常；启动默认 3.8。模型 UI 自报"Antigravity 助手"是系统提示匿名约束，以网络层 modelVersion 为准。

**B3 后端固化（已完成，落源码项目，无实验探针）**：
- `Antigravity-Injection/plugins/zk-proxy-pro/vendor/bundled-origin/source.js` 312067→314109（仅加自包含 `/__agtarget`，**未带** FAM 钩子/H2 tee）；`_ag-gemini37-compat.cjs` 3773→6012（加 `_agReadSelected`/SELECTED_FRESH_MS，**去掉** h2orig/h2route 录制）。
- 测试：`test/gemini-compat.test.js` 新增 6 个旁路用例（新鲜 last/bySid 优先/sid 回退/过期/损坏/URL 优先），compat 17 项全过、三测试文件合计 30 pass 0 fail。
- 构建：`node scripts/build-vsix.mjs` 成功出 `dist/zk-proxy-pro-9.9.529.vsix`（58 files）；`node tools/checks/antigravity-target-check.js` 通过（dist 与源码一致）。扩展更新时装此 vsix 即保留后端旁路。

**前端自愈现状 + 交付物**：
- 一键入口 `放行Claude六档.ps1`（UTF-8 BOM，-ForceKill 关进程→node patch6→校验，幂等；PS 语法已校验）。
- `SOP-新模型放行.md`：三段原理、唯一映射表（patch6 顶部 MODELS）、加新模型 6 步（取 uid→改一行→关 IDE→跑脚本→启动→网络层核验）、IDE 更新恢复、vsix 后端、回滚、边界。
- **未做（列为可选增强，需用户决策，避免擅改 109KB 启动自愈核心引入回归）**：把 patch6 五处注入做进 `scripts/StableMode.Core.psm1` 的 workbench ConvertFrom/ConvertTo/Test 成套生成器，实现 IDE 更新后启动自动恢复（当前为手动跑一键脚本 + SOP）。
- 部署 529 副本仍含实验 FAM/H2 tee/录制（无害，运行态依赖其 /__agtarget + 旁路）；正式干净逻辑已在源码 vsix，下次装新 vsix 即去探针，暂不在运行态冒险替换。

**B4**：子 agent 七项 checklist 独立审计（前端 patch6 / 后端 source.js+compat / 测试 / 文档）。
