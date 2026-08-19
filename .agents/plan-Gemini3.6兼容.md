# Gemini 3.6 Compatibility Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为旧版 Antigravity 增加可选、可持久、可回退的 Gemini 3.6 兼容模式，同时保持现有稳定模式和发送链路不变。

**Architecture:** 在已验证稳定文件上增加确定性的 3.6 模型目录与工作台偏好桥。偏好桥只分流真实 ID `1264/1265/1266`：写入 renderer 本地偏好并跳过旧 `uss-modelPreferences` sentinel；普通模型继续走原 USS。Bootstrap 持久化期望模式，事务在临时候选验证后才替换生产文件。

**Tech Stack:** PowerShell 7、Electron 压缩 JavaScript 确定性锚点、SHA-256、WinForms、Pester 风格脚本测试、.NET 9 xUnit。

---

## 文件职责

- `scripts/StableMode.Core.psm1`：稳定/3.6 双向转换、结构识别、模式事务和回退。
- `tests/Test-Gemini36Mode.ps1`：3.6 纯函数 RED/GREEN、真实 ID、幂等和双向转换。
- `tests/Test-CompatibilityInstallIntegration.ps1`：临时安装模式切换、备份和字节级恢复。
- `StableBootstrap.ps1`：读取/保存期望模式，按模式匹配本地档案并自愈。
- `tests/Test-StableBootstrap.ps1`、`tests/Test-AdaptiveBootstrapIntegration.ps1`：旧配置迁移和双模式档案回归。
- `Antigravity稳定模式.ps1`：当前实际使用的 PowerShell WinForms 模式选择界面。
- `tests/Test-OneClickInstaller.ps1`：UI 与启动脚本静态回归。
- `README-稳定模式.md`、`.agent/handoff.md`：使用说明与跨会话证据。

### Task 1: 3.6 模型目录与本地偏好桥

**Files:**
- Create: `tests/Test-Gemini36Mode.ps1`
- Modify: `scripts/StableMode.Core.psm1`
- Modify: `.agent/plan-Gemini3.6兼容.md`

- [x] **Step 1: 写 RED 纯函数测试**

测试夹具必须包含当前唯一原文锚点：

```js
qb(e){if(e.choice.case!=="model")return;const i=Jku(e.choice.value);this.db.pushUpdate(i)}
async Db(){const e=await this.db.subscribe("uss-modelPreferences");this.D(Ri(i=>{const n=e.read(i),s=Hku(n);this.setSelectedModel(hs(RGl,{choice:{case:"model",value:s}}),void 0,!1)}))}
```

断言转换后存在：

```js
const _agCompatibilityMode="gemini36-v1",_agGemini36Ids=new Set([1264,1265,1266]),_agGemini36PreferenceKey="antigravity.compat.gemini36.preference.v1";
```

并断言：3.6 三档标签存在；Gemini 3.1/GPT 不存在；`qb()` 只对三个 ID 跳过 USS；`Db()` 优先合法本地 ID；`mUc()`、`requestedModel:this.m` 不被修改；转换幂等；Stable→Gemini36→Stable 返回确定内容；缺失或重复锚点拒绝。

- [x] **Step 2: 运行 RED**

Run:

```powershell
pwsh -NoProfile -File .\tests\Test-Gemini36Mode.ps1
```

Expected: 退出码 `1`，原因是 `ConvertTo-Gemini36MainContent` 或 `ConvertTo-Gemini36WorkbenchContent` 尚不存在。

- [x] **Step 3: 最小实现双向转换**

在核心模块增加：

```powershell
Test-Gemini36MainContent
ConvertTo-Gemini36MainContent
Test-Gemini36WorkbenchContent
ConvertTo-Gemini36WorkbenchContent
Get-InstalledCompatibilityMode
```

桥接 JavaScript 使用 `try/catch` 访问 `localStorage`，只接受整数 `1264/1265/1266`。3.6 写入本地键并返回；非 3.6 删除本地键后继续 `Jku/db.pushUpdate`。USS 恢复使用 `_agReadGemini36() ?? Hku(n)`。Stable 转换必须精确移除标记、助手与两个替换，不能宽泛正则。

- [x] **Step 4: 运行 GREEN 和稳定回归**

Run:

```powershell
pwsh -NoProfile -File .\tests\Test-Gemini36Mode.ps1
pwsh -NoProfile -File .\tests\Test-StableMode.ps1
```

Expected: 两项均退出码 `0`；稳定模式仍排除 3.6。

### Task 2: 重启后登录状态竞态修复

- [x] 用最小夹具复现 `UserStatusUpdater` 早于 `LanguageServerClient` 初始化启动。
- [x] 新增确定性、幂等、未知结构拒绝修改的 extension.js 转换与校验函数。
- [x] 稳定模式与 Gemini 3.6 模式共用该修复；备份、恢复和状态检查覆盖 extension.js。
- [x] 验证模型缓存清理不删除 `oauthToken` 与 `userStatus`。
- [x] 在临时安装副本完成应用、重复应用、失败回滚和字节级恢复。

### Task 3: 双模式事务、状态与回退

**Files:**
- Create: `tests/Test-CompatibilityInstallIntegration.ps1`
- Modify: `scripts/StableMode.Core.psm1`
- Modify: `Install-StableMode.ps1`
- Modify: `tests/Test-StableInstallIntegration.ps1`

- [x] **Step 1: 写 RED 集成测试**

临时安装副本覆盖以下顺序：Stable→Gemini36、Gemini36 重复应用、Gemini36→Stable、恢复原始备份。断言健康同模式 `Changed=false` 且不新增备份；任一候选校验失败时 main/workbench/product 字节级恢复。

- [x] **Step 2: 运行 RED**

Run:

```powershell
pwsh -NoProfile -File .\tests\Test-CompatibilityInstallIntegration.ps1
```

Expected: 退出码 `1`，缺少 `Set-CompatibilityMode` 或 `Get-CompatibilityInstallStatus`。

- [x] **Step 3: 最小实现统一模式 API**

新增公开接口：

```powershell
Get-CompatibilityInstallStatus -InstallRoot <path> -Mode Stable|Gemini36
Set-CompatibilityMode -InstallRoot <path> -BackupRoot <path> -Mode Stable|Gemini36 -AllowAdaptive
```

旧 `Get-StableInstallStatus` 与 `Set-StableMode` 保留为 `Stable` wrapper。返回对象包含 `Mode`、`PreviousMode`、`Changed`、`Backup`、`Adapter`、源/目标哈希。事务顺序固定为：进程门禁→内存候选→JavaScript/结构验证→备份→原子写入→product checksum→静态复验；catch 恢复本次精确备份。

- [x] **Step 4: 运行 GREEN 与字节级恢复回归**

Run:

```powershell
pwsh -NoProfile -File .\tests\Test-CompatibilityInstallIntegration.ps1
pwsh -NoProfile -File .\tests\Test-StableInstallIntegration.ps1
```

Expected: 两项退出码 `0`。

### Task 4: Bootstrap 模式持久化与档案迁移

**Files:**
- Modify: `StableBootstrap.ps1`
- Modify: `profiles/local-generated.json`（只通过脚本生成，不手工写生产哈希）
- Modify: `tests/Test-StableBootstrap.ps1`
- Modify: `tests/Test-AdaptiveBootstrapIntegration.ps1`

- [x] **Step 1: 写 RED 配置/档案测试**

覆盖：旧 `{installRoot}` 默认 `Stable`；显式 `Gemini36` 成功后保存；第二次无参数运行保持 `Gemini36`；显式 `Stable` 可回退；非法模式拒绝且零修改；Stable 与 Gemini36 档案并存且互不覆盖。

- [x] **Step 2: 运行 RED**

Run:

```powershell
pwsh -NoProfile -File .\tests\Test-StableBootstrap.ps1
pwsh -NoProfile -File .\tests\Test-AdaptiveBootstrapIntegration.ps1
```

Expected: 至少一项退出码 `1`，因为当前 settings/profile 没有模式维度。

- [x] **Step 3: 实现模式持久化**

`StableBootstrap.ps1` 增加可选参数：

```powershell
[ValidateSet('Stable', 'Gemini36')]
[string]$Mode
```

settings 合并保存 `installRoot`、`selectedMode`、`lastSuccessfulMode`；缺少模式迁移为 `Stable`，非法值 fail-closed。档案增加 `schemaVersion:2`、`mode`、`patchVersion`；旧档案解释为 Stable。`Find-TargetProfile` 必须同时匹配 target 哈希与 mode；跨模式注册必须新增而非改写旧档案。快捷方式不写死 `-Mode`，每次读取保存模式。

- [x] **Step 4: 运行 GREEN**

Run:

```powershell
pwsh -NoProfile -File .\tests\Test-StableBootstrap.ps1
pwsh -NoProfile -File .\tests\Test-AdaptiveBootstrapIntegration.ps1
```

Expected: 两项退出码 `0`。

### Task 5: 现有可视界面接入

**Files:**
- Modify: `Antigravity稳定模式.ps1`
- Modify: `tests/Test-OneClickInstaller.ps1`
- Modify: `README-稳定模式.md`

- [x] **Step 1: 写 RED UI 静态测试**

断言唯一存在两个 RadioButton：“稳定模式（Gemini 3.5 + Claude）”“Gemini 3.6 兼容模式（实验）”；唯一修改入口“应用并启动”；检测纯只读；恢复按钮重置为 Stable；UI 不直接替换 IDE 文件。

- [x] **Step 2: 运行 RED**

Run:

```powershell
pwsh -NoProfile -File .\tests\Test-OneClickInstaller.ps1
```

Expected: 退出码 `1`，缺少模式控件。

- [x] **Step 3: 实现统一操作界面**

新增 `Get-SelectedCompatibilityMode`、`Update-CompatibilityStatus`、`Invoke-ApplySelectedMode`。单选框只改选择不写生产；“应用并启动”调用 Bootstrap 显式模式；状态显示当前模式、3.6 隔离/启用、main/workbench 哈希和下次启动模式。保留恢复功能，删除绕过检查的独立“启动旧版”入口。

- [x] **Step 4: 运行 GREEN**

Run:

```powershell
pwsh -NoProfile -File .\tests\Test-OneClickInstaller.ps1
pwsh -NoProfile -File .\tests\Test-StableMode.ps1
```

Expected: 两项退出码 `0`。

### Task 6: 临时副本、生产安装与真实验收

**Files:**
- Modify: `.agent/plan-Gemini3.6兼容.md`
- Modify: `.agent/handoff.md`
- Modify: `notes.md`

- [x] **Step 1: 全量自动验证**

Run:

```powershell
pwsh -NoProfile -File .\tests\Test-OneClickInstaller.ps1
pwsh -NoProfile -File .\tests\Test-StableMode.ps1
pwsh -NoProfile -File .\tests\Test-Gemini36Mode.ps1
pwsh -NoProfile -File .\tests\Test-StableBootstrap.ps1
pwsh -NoProfile -File .\tests\Test-StableInstallIntegration.ps1
pwsh -NoProfile -File .\tests\Test-CompatibilityInstallIntegration.ps1
pwsh -NoProfile -File .\tests\Test-AdaptiveBootstrapIntegration.ps1
dotnet test .\AntigravityCompat.sln -c Release --no-restore --nologo
```

Expected: 全部退出码 `0`，.NET 失败 `0`。

- [x] **Step 2: 生产前门禁**

确认 `D:\Antigravity` 进程数为 0；记录当前 main/workbench/product 哈希；创建带清单的精确备份。若用户 IDE 正在运行则停止，不强制关闭用户进程。

- [x] **Step 3: 应用 Gemini36 并静态复验**

通过公开 Bootstrap/核心 API 应用，不直接编辑生产文件。确认 detected mode=`Gemini36`、结构锚点唯一、product checksum 正确、TLS 双协议补丁仍存在。

- [x] **Step 4: 真实发送验收**

High、Medium、Low 各发送一次；日志中 requestedModel ID 分别为 `1264/1265/1266`；HTTP→HTTPS、未知证书、`Failed to fetch` 均为 0；保持窗口 90 秒无卡死或扩展宿主无响应。

- [x] **Step 5: 重启与回退验收**

关闭 IDE 后再次点击现有桌面快捷方式，确认仍为 Gemini36；随后切回 Stable，确认 3.6 被隔离且 Gemini 3.5/Claude 可发送。清理所有测试启动的进程和临时目录。

## 当前状态

- [x] 用户批准方案 A 和书面设计。
- [x] 完成工作台唯一锚点、事务和 UI 接入点只读取证。
- [x] 实施计划完成。
- [x] Task 1 完成：RED 因缺少转换函数退出 `1`；Gemini 3.6 纯函数与稳定回归均退出 `0`。
- [x] Task 2 完成：生产 extension.js 已事务应用；新会话启动顺序错误 0、账号令牌读取成功。
- [x] 用户已确认稳定模式重启发送与提示词注入；Gemini36 三档另完成自动真实发送验收。
- [x] 排除登录根因：Cockpit 2.1.55 宿主令牌重灌成功，仍因工作台 HTTPS 自签名失败而无法发送。
- [x] 启用产品自带 `codeiumDev.useOneLS`，切换到已验证的共享 HTTP 语言服务器链路。
- [x] 完全重启后最新日志 TLS/Failed to fetch/无响应均为 0，出现 2 次真实 `streamGenerateContent`。
- [x] Gemini 3.6 High/Medium/Low 分别返回 `42/43/44`；重启后 Low 返回 `45`，无需切号。
- [x] 90 秒观察 18 个样本：最大单进程私有内存 `355.2 MB`，主窗口持续 `Responding=true`，无旧版 700MB–1GB 暴涨。
- [x] Agent Pro 重启后仍在 `request.systemInstruction.parts` 执行系统提示词变换：`transformed=true`，`25661 -> 1384` 字符。
- [x] 生产当前保留 `Gemini36`；`Gemini36 -> Stable` 的精确回退已由临时安装事务测试覆盖，未为验收破坏用户当前选择。
- [x] 独立复审后补强三项门禁：Gemini36 同时校验底层 OneLS 传输、CDP 只认发送后的新增回复、请求超时/断连清空 pending；修正后 Low 新回复为 `46`。
- [x] 最终 13 组回归全部退出 `0`，.NET `39+3` 失败 `0`，新增函数最大圈复杂度 `7`（`<9`），复审无剩余问题。
