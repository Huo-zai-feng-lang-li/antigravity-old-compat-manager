# 最新接续状态 (2026-09-11 16:36)

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
