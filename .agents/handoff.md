# 最新接续状态 (2026-10-23 23:50)

## 核心进展
- **Gemini 3.8 Medium/Low 两档已放出，thinkingBudget 改为按 uid 动态设置**。后端 `_agLiftThinking`（无条件 `-1`）替换为 `_agApplyThinkingBudget(request, targetModel)`，查表：high `-1` / medium `4000` / low `1000` / tiered `-1`；表中没有的模型（Claude 全系、未知新模型）仍落 `-1`，零回归。zk 已发版 **9.9.531** 并安装。
- **修复了「每次启动 model-unlock 注入被覆盖」的根因**：`StableBootstrap.ps1` 启动时用 workbench SHA256 匹配 `profiles/local-generated.json`，model-unlock 改过 wb 后哈希不匹配 → 触发重打补丁 → 覆盖注入。已在 bootstrap 加叠加层识别（wb 同时含 `_agGemini37` + `__agUid` 即视为健康态跳过重打），并在 `patch-workbench.mjs` 里补了 product.json checksum 同步。
- **GUI 实测下拉 9 项**：Gemini 3.8 High/Medium/Low + Claude Opus 5.5 ×3 + Claude Sonnet 5.5 ×3。启动后 wb 保持 23833583 字节（8 uid ×3），不再被还原。

## 核心动机与背景
- 用户明确要求：放出 Gemini 3.8 中低档，且「不能页面显示高、实际用低」——即档位必须真实生效。
- 原 `_agLiftThinking` 对主对话无条件把 `thinkingBudget` 改成 `-1`（High 满载），选 Medium/Low 也会被抬成 High，档位失真。
- 官方元信息（`_ag-models-catalog.json`）给出的真实档位参数：`gemini-3.8-flash-high`=`-1`、`medium`=`4000`、`low`=`1000`、`tiered`=`-1`。

## 关键设计与实现

### 1. 后端动态档位（zk 9.9.531）
`_ag-gemini37-compat.cjs`：
- 删 `_agLiftThinking`，新增 `THINKING_BUDGET_BY_MODEL` 冻结表 + `_agApplyThinkingBudget(request, targetModel)`。
- `rewriteRequestBody` 顺序调整：先解析 `targetModel`（URL > 旁路 > 默认），再按其设 `thinkingBudget`。非占位符请求直接原样返回（不再做 thinking 提升）。
- 新增 6 个单测（medium=4000 / low=1000 / high=-1 / Claude=-1 / 默认=-1 / 无 thinkingConfig 不抛错），全套 **25 pass**。

### 2. 前端放出中低档
`model-unlock/patch-workbench.mjs` 的 `MODELS` 增加两行：`gemini-3.8-flash-medium` / `gemini-3.8-flash-low`。现在共 8 项。

### 3. 覆盖问题根因修复（本次最关键）
- **现象**：patch 后 wb = 23833583（8 uid），启动后变 23831768（6 uid），Gemini 中低档消失。
- **根因**：`StableBootstrap.ps1:392-395` 用 workbench SHA256 匹配 profiles，不匹配就 `Set-CompatibilityMode` 重打，用干净基线覆盖 model-unlock 的注入。铁证：`logs/bootstrap-blocked-20261023T153647Z.json` 记录了 23:36:47 的重打尝试（因 `state.vscdb` 被占用失败回滚）。
- **修复**：
  1. `patch-workbench.mjs` 注入后同步 `product.json` 的 workbench checksum（ESM 用 `await import('node:crypto')`，不能 `require`；路径从 wb 目录往上 **3 级**）。
  2. `StableBootstrap.ps1` 加叠加层判断：`$needsRepair` 为真且 mode=Gemini37 时，若 wb 同时含 `_agGemini37` + `__agUid` 则置 `$needsRepair = $false`。

## 待办事项 (Next Steps)
- [ ] **commit `3a2e946` 的 message 有误**（写了「Gemini 4 官方未发布无法放行」，实际 Argon 已发布但不支持独立 IDE）。已推送 origin/main，需 amend + force push 或追加更正 commit。
- [ ] **zk 仓库当前工作区干净**（9.9.531 已随 bump 自动 commit+push，commit `4846b74`），compat-manager 的 4 个改动待提交。
- [ ] 若要真正使用 **Gemini 4 Argon**：独立 IDE 不支持，只能换 Antigravity App (2.24.0+) / CLI / VS Code 扩展。

## 关键上下文
- 目录: `D:\Desktop\Super-File\AI-IDE\AI\反重力\antigravity-old-compat-manager`
- 前端映射表: `model-unlock/patch-workbench.mjs` 顶部 `MODELS`（当前 8 项）
- 前端校验: `model-unlock/verify-workbench.mjs`（PATCHED 模式全量断言）
- 启动引导: `StableBootstrap.ps1`（含叠加层识别，**改动勿回退**）
- zk 动态档位: `plugins/zk-proxy-pro/vendor/bundled-origin/_ag-gemini37-compat.cjs`（`THINKING_BUDGET_BY_MODEL`）
- 运行态扩展: `C:\Users\Administrator\.antigravity\extensions\zk-agent.zk-proxy-pro-9.9.531\`
- 当前 HEAD: compat-manager `f1aeb61`（+4 个未提交改动）；zk `4846b74`（9.9.531 已推送）

## 验证证据
- zk 单测 **25 pass / 0 fail**（含 6 个新增档位测试）。
- 直调 `rewriteRequestBody` 实测：high→`-1`、medium→`4000`、low→`1000`、Claude→`-1`，**4/4 match**。
- `verify-workbench.mjs`：8 个 uid 各 ×3，`ALL-MODELS OK`。
- 启动后 wb 仍为 23833583 字节（叠加层识别生效，不再被覆盖）。
- GUI 下拉 9 项全部可见。
