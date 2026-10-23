# 最新接续状态 (2026-10-24 00:15)

## 核心进展
- **Gemini 3.8 Medium/Low 两档已放出并通过真机验证**。用户确认在 IDE 里选 Gemini 3.8 Flash (Medium) 能正常对话。thinkingBudget 由后端按 uid 动态设置（high `-1` / medium `4000` / low `1000` / Claude 及其他 `-1`），不再无条件抹平为 `-1`。
- **代码已过 code-reviewer 子代理审查，3 个中危问题全部修复并实测验证**。
- **zk 已发版 9.9.532**（含测试隔离 + 导出查表函数 + 5 个补测），43 tests pass，已推送。

## 核心动机与背景
- 用户要求放出 Gemini 3.8 中低档，并强调"不能页面显示高、实际用低"。
- 原 `_agLiftThinking` 对主对话无条件把 thinkingBudget 改成 `-1`（High 满载），选 Medium/Low 也会被抬成 High。
- 官方元信息实测值：`gemini-3.8-flash-{high:-1, medium:4000, low:1000, tiered:-1}`。

## 关键设计与实现

### 后端（zk 9.9.531 + 9.9.532）
`_ag-gemini37-compat.cjs`：
- 删 `_agLiftThinking`，新增 `THINKING_BUDGET_BY_MODEL` 冻结表 + `_agApplyThinkingBudget(request, targetModel)`。
- `rewriteRequestBody` 先解析 targetModel（URL > 旁路 > 默认），再按其设 thinkingBudget；非占位符请求直接原样返回。
- 导出 `THINKING_BUDGET_BY_MODEL` / `_agApplyThinkingBudget` 供直接单测。
- **新增 `AG_SELECTED_FILE` 环境变量隔离点**：单测把落盘重定向到临时目录，不再污染运行态 `_agcap/_ag-selected.json`（审查发现的真问题）。
- 表定义上方加维护警告：官方发新档位必须同步加表，否则回落 `-1` 抹平。

### 前端
`model-unlock/patch-workbench.mjs`：
- `MODELS` 增至 8 项（Claude 5.5 六档 + Gemini 3.8 Medium/Low）。
- **失败路径加固**（审查中危 #1）：原顺序「写 wb → 同步 product.json checksum → node --check → 失败只回滚 wb」会留下 checksum 与已回滚基线不匹配的半成品。改为「**先在内存校验语法 → 通过才写 wb → 再同步 checksum**」，失败时任何文件都不动。已实测验证。
- **product.json 改原子写**（中危 #2）：写 `.tmp` 再 `renameSync`，防断电损坏导致 IDE 起不来。

### 启动链路（最关键的根因修复，2026-10-23 已完成）
`StableBootstrap.ps1` 原会用 wb SHA256 匹配 profiles，model-unlock 改过 wb 后不匹配 → 触发重打 → **覆盖注入**。已加叠加层识别：wb 同时含 `_agGemini37` + `__agUid` 即视为健康态跳过重打。铁证日志 `logs/bootstrap-blocked-20261023T153647Z.json`。本次顺手删掉了 361-365 行的死代码。

## 待办事项 (Next Steps)
- [ ] **commit `3a2e946` 的 message 有误**（写着「Gemini 4 官方未发布无法放行」）。实际 Argon 已于 2026-10-13 发布，但官方限定仅 App/CLI/IDE 扩展可用，独立 IDE 被排除。已推送 origin/main，需 amend + force push 或追加更正 commit。
- [ ] 若要用 **Gemini 4 Argon**：独立 IDE 拿不到，只能换 Antigravity App (2.24.0+) / CLI / VS Code 扩展。
- [ ] 低危待办（未做）：`verify-workbench.mjs` 的 uids 是 patch MODELS 的手工镜像，可抽 `models.mjs` 共用；`StableBootstrap` 可加 `-ForceRepair` 开关绕过叠加层判断。

## 关键上下文
- 目录: `D:\Desktop\Super-File\AI-IDE\AI\反重力\antigravity-old-compat-manager`
- 前端映射表: `model-unlock/patch-workbench.mjs` 顶部 `MODELS`（8 项）
- 启动引导: `StableBootstrap.ps1`（含叠加层识别，**改动勿回退**）
- zk 动态档位: `plugins/zk-proxy-pro/vendor/bundled-origin/_ag-gemini37-compat.cjs`
- 运行态扩展: `C:\Users\Administrator\.antigravity\extensions\zk-agent.zk-proxy-pro-9.9.532\`
- 当前 HEAD: compat-manager `cf1a128`；zk `b48ec5c`（均为已推送状态）

## 验证证据（全部实测）
- **档位直测**（532 隔离模式，5/5 match）：high→`-1`、medium→`4000`、low→`1000`、claude-opus-5-5-low→`-1`、claude-sonnet-5-5-high→`-1`；测试后运行态 `_ag-selected.json` 未被污染。
- **回滚路径实测**：人为注入语法错误 → wb 与 product.json 均保持原状（exit 2）。
- **checksum 实测**：wb sha256 的 base64 == product.json 记录值，无 `.tmp` 残留。
- **zk 全量**：43 tests pass / 0 fail。
- **verify-workbench**：8 个 uid 各 ×3，`ALL-MODELS OK`。
- **启动后 wb 保持 23833583 字节**（叠加层识别生效，Gemini Medium/Low 各 3 处仍在）。
- **GUI 下拉 9 项**；点选 Gemini Medium → 落盘 `gemini-3.8-flash-medium`。
- **用户真机确认**：选 Gemini 3.8 Flash (Medium) 能正常对话。
