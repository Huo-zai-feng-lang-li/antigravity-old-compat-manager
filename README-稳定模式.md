# Antigravity 旧版兼容管理器

项目仓库：[antigravity-old-compat-manager](https://github.com/Huo-zai-feng-lang-li/antigravity-old-compat-manager)

## 用途

提供两种可回退模式：

- `Stable`：仅保留 Claude，隐藏 Gemini 3.5、Gemini 3.1、GPT 和未来未知模型。
- `Gemini37`：在同一稳定底座上保留 Claude、Gemini 3.6 Flash High/Medium 和 Gemini 3.7 Flash High，隐藏所有 Low 与未来未知模型。

Gemini 3.7 Medium 因旧协议暂时没有独立稳定的选择载体而未发布。两种模式都排除 Gemini 3.1、GPT 和未来未知模型。

## 使用

1. 完全关闭 Antigravity。
2. 双击 `一键安装稳定模式.cmd`，脚本会自动检测常见目录并显示可视界面。
3. 确认安装目录；若检测不正确，点击“选择目录”。
4. 选择“稳定模式（仅 Claude）”或“Gemini 3.7 兼容模式（保留 Claude）”，点击“应用并启动”。
5. 选择会被保存；以后直接打开 `Antigravity.exe`，或使用桌面 `Antigravity 稳定版.lnk` 自动检查并修复当前模式。

“检测模型目录”会在每次点击时读取 Google 官方 Models 页面并展示最新公开推理模型。新模型只用于查看；旧版 IDE 的下拉框仍只放行经过兼容验证的模型，避免未知模型重新触发旧版卡顿。若 IDE 以 `9000` 调试端口启动，报告还会附加当前旧版下拉框实际可见的模型。

新模型的放行标准和本次失败复盘见 `docs\Gemini新模型兼容指南.md`；项目强制门禁见 `.agent\rules\README.md`。

## 以后怎么用

### 第一次使用

1. 完全关闭 Antigravity。
2. 双击 `一键安装稳定模式.cmd`。
3. 选择模式并点击“应用并启动”。

这一步通常只需要执行一次。安装工具和黑色窗口都不需要常驻后台。

### 日常使用

安装成功后，可以直接打开原来的 IDE 程序：

`D:\Antigravity\Antigravity.exe`

也可以使用桌面的 `Antigravity 稳定版.lnk`。推荐使用这个快捷方式，它会先快速检查文件，正常时直接启动 IDE，不会常驻。

### 什么时候需要重新安装

只有以下情况需要再次运行 `一键安装稳定模式.cmd`：

- 更新、重装或更换了 Antigravity IDE 版本。
- IDE 安装目录发生变化。
- IDE 更新覆盖了 `resources\app` 中的稳定模式文件。
- 工具检测状态显示“未安装”“需要修复”或“未知版本”。

如果始终使用 `Antigravity 稳定版.lnk`，结构兼容的 IDE 更新会自动备份并重新适配；遇到未知结构时只提示诊断，不会盲目修改文件。

注意：“应用并启动”只对当前安装目录和当前 IDE 文件生效，并不代表未来所有新版本永久免安装。

启动器已使用 Windows 原生 CRLF 和纯 ASCII 编码，避免中文目录下被 `cmd.exe` 错误拆行。
安装过程不会常驻：黑色 CMD 和 PowerShell 自动退出。只有 IDE 文件被更新、覆盖或需要切换兼容模式时才需要重新运行管理器。

新安装版本如果显示“未知 main.js 哈希”，代表该版本尚未建立适配档案。工具只显示诊断信息并拒绝盲改，避免把 IDE 改坏。

## 推荐日常入口

桌面已经创建 `Antigravity 稳定版.lnk`。以后只点击这个快捷方式：

- 已稳定：约 2 秒完成检查并启动 IDE。
- IDE 更新但结构兼容：自动备份、临时验证、适配并启动。
- 结构不兼容：不修改文件，只显示一次错误和诊断路径。
- 启动器拉起 IDE 后立即退出，不常驻后台。

快捷方式现在由 Windows `wscript.exe` 调用 `Launch-StableHidden.vbs`，整个自检过程无 CMD/PowerShell 黑窗。健康状态实测约 `1.6` 秒完成检查并拉起 IDE；只有检测到 IDE 文件更新时才执行较慢的完整备份、语法检查和自愈。

Cockpit 账号重同步修复包也已归档到 `packages\antigravity-cockpit-2.1.55.vsix`，相关安装包、脚本、备份和说明均可从本管理器目录找到。

当前已适配源哈希 `4A91118C...`，稳定目标为 main `4559D1A3...`、workbench `EF1D5838...`。

## 发送被拦截的修复

旧实现把同一个客户端类全局改成 HTTP，但它同时承载两条链路：USS 单实例使用 HTTP 端口，扩展宿主直连仍提供 HTTPS 端口，因此直连链路会把 HTTP 请求误发到 HTTPS。当前双协议适配器按链路选择协议，并在每次语言服务器启动时清理 USS 旧本机端点。

旧版工作台还必须启用产品自带的单语言服务器模式：`"codeiumDev.useOneLS": true`。该模式让本地工作台读取主进程发布的 HTTP 端口，避免浏览器通过 HTTPS 访问自签名证书而反复 `Failed to fetch`。远程工作区会由 IDE 自动排除。

## 重启后登录状态不可用的修复

旧版扩展会在语言服务器初始化前立即刷新账号状态，首次刷新因此失败，表现为关闭 IDE 后重开无法发送或登录状态异常。稳定模式现在会把账号状态刷新移动到语言服务器初始化完成之后，并把 `extension.js` 纳入备份、语法检查、状态检测和失败回滚。

该修复不会删除或改写 `oauthToken`、`userStatus`。日常继续使用桌面的 `Antigravity 稳定版.lnk`；IDE 更新覆盖文件后，快捷方式会在结构兼容时自动重新应用修复。

## 道 Agent Pro 提示词注入

稳定模式保留 `codeiumDev.useOneLS=true`，并在主进程启动共享语言服务器前等待道 Agent Pro 本地代理健康。校验通过后只把 `--cloud_code_endpoint` 改为本机回环端点；插件缺失、未就绪或校验失败时保留官方端点，不会卡死启动。

真实验收已确认：关闭 IDE、重开且不切账号仍能发送；主聊天请求记录为 `GEMINI_REST_CHAT`，字段为 `request.systemInstruction.parts`，`transformed=true`。摘要子请求单独记录，可能显示 `transformed=false`，不能用摘要槽误判主聊天未注入。

提示词属于 Gemini 请求里的系统指令层，用于配置模型行为；它不是 Google 服务端安全策略或平台规则之上的绝对最高权限。

本次同时修复了 Agent Pro 的 `.obsolete` 误判：旧版本残留标记不再导致当前 `9.9.335` 被当成卸载。修复后的 VSIX 已安装到当前 Antigravity 用户扩展目录。

### 日常使用边界

- 当前 IDE 文件未被更新：可直接打开 `D:\Antigravity\Antigravity.exe`。
- IDE 更新或重装：优先点 `Antigravity 稳定版.lnk`，它会自动检查、备份和重新适配；直接 EXE 不会在启动前自愈被覆盖的文件。
- Agent Pro 更新：桥会自动选择未被 `.obsolete` 标记的最高语义版本，并校验 `/origin/ping` 的 `self_file` 后才接管。
- 黑窗、管理器和额外代理程序都不需要常驻；代理由 Agent Pro 随 IDE 生命周期启动和关闭。

若 PowerShell 拦截脚本，可在本目录打开 PowerShell 后执行：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File ".\Antigravity稳定模式.ps1"
```

## 安全边界

- `main.js`、`workbench` 与 `extension.js` 必须命中唯一结构锚点并通过语法检查；未知结构拒绝修改。
- 应用前备份安装文件与旧版状态库，失败自动恢复。
- 只删除 `modelPreferences`；保留 `userStatus` 与登录状态，模型目录由双边界过滤器净化。
- Gemini 3.6 High/Medium 可通过兼容模式启用；Gemini 3.6 Low 已隐藏。如遇环境差异，可在界面一键切回 `Stable`。

启动初期短暂显示“Authentication Required”不等于令牌丢失：旧工作台会在账号状态和模型目录尚未返回时先渲染未登录页面。模型列表不能在真实数据返回前立即生成；后续 UI 优化应显示“正在加载模型”，超过合理时间仍无账号状态时才显示登录提示。
