# Antigravity IDE 重装到启动使用流程

> 适用：IDE 版本 2.5.5，compat 管理器已含「证书绕过」+「自动接管图标」+「健康态跳过补丁」功能。
> 本流程目标：重装后从 0 到能正常发消息对话。
> 启动性能：桌面双击到 IDE 窗口出现约 **3.7 秒**（2026-09-11 优化后，最初 20.8 秒）。首次重装后打补丁需几秒，后续启动健康态自动跳过。

---

## 一、重装前确认（必做）

确认以下文件都在 `D:\Desktop\脚本\` 里，缺了先找回来：

| 文件 | 作用 | 备注 |
|---|---|---|
| `version.dll` | 劫持走 dotsvpn 代理出墙 | 必须放在 IDE 安装根目录，与 Antigravity.exe 同级 |
| `config.json` | version.dll 的配置（代理 127.0.0.1:51081） | 与 version.dll 同目录 |
| `extension.js.可用LF版-20260910` | 应急备份 | extension.js 被改坏换行符时用它覆盖 |

两个项目路径（不要动）：
- 兼容管理器：`D:\Desktop\Super-File\AI-IDE\AI\反重力\antigravity-old-compat-manager`
- 注入项目：`D:\Desktop\Super-File\AI-IDE\AI\反重力\Antigravity-Injection`

---

## 二、重装步骤

### 第 1 步：安装 IDE

正常运行安装包，装到目标盘（例如 `D:\Antigravity`）。装完**先不要启动**。

### 第 2 步：放入 version.dll 和 config.json

把 `D:\Desktop\脚本\` 里的这两个文件复制到 IDE 安装根目录（和 `Antigravity.exe` 同一个文件夹）：

```
D:\Antigravity\
├── Antigravity.exe
├── version.dll        ← 复制到这里
├── config.json        ← 复制到这里
└── ...
```

> 重要：version.dll 只在进程启动的瞬间被加载，IDE 运行中再放进去无效。所以必须先放好再启动。

### 第 3 步：确认 dotsvpn 代理在运行

dotsvpn 必须监听 `127.0.0.1:51081`，否则 IDE 连不上 Google。
打开 dotsvpn 客户端，确认已连接。

### 第 4 步：跑一键安装稳定模式

进入兼容管理器目录，双击运行：

```
D:\Desktop\Super-File\AI-IDE\AI\反重力\antigravity-old-compat-manager\一键安装稳定模式.cmd
```

它会自动完成：
1. 检测 IDE 安装目录（自动回退，不用手动指定路径）
2. 给 IDE 打兼容补丁（Gemini37 模式，首次重装后需几秒）
3. **自动把桌面和开始菜单的 Antigravity 图标改写成兼容启动**（原始图标自动备份到项目 `backups\shortcuts\` 下，可逆）
4. 启动 IDE

> 如果弹出 GUI 窗口，选「应用」即可。
> 补丁打完后，后续每次启动会自动检测文件哈希，已匹配当前版本则跳过补丁，1.2 秒内启动 IDE。只有重装/更新 IDE 后才会重新打补丁。

### 第 5 步：启动使用

直接点**桌面的 Antigravity 图标**（已被自动改写成兼容启动），或点开始菜单里的 Antigravity。

> 不要直接双击 `D:\Antigravity\Antigravity.exe`——直连 exe 不带证书绕过，会导致扩展宿主崩溃、点发送闪一下回弹。

### 第 6 步：验证

在对话框发一条消息，确认模型能正常出字。

---

## 三、启动后会看到的正常现象

- **启动时间**：桌面双击到 IDE 窗口出现约 3.7 秒（健康态跳过补丁）。首次重装后启动需几秒（打补丁），后续自动加速。
- **启动瞬间可能黑一下/崩一次**：这是旧版 version.dll 与 2.5.5 网络进程的已知兼容问题，Electron 会自动重启恢复，**不影响使用**。
- 任务管理器里 Antigravity 进程约 20 个，其中大部分加载了 version.dll。
- 本地语言服务器证书已于 2026-09-05 过期，启动器已自动双覆盖绕过（`NODE_TLS_REJECT_UNAUTHORIZED=0` + `--ignore-certificate-errors`），无需手动处理。

---

## 四、常见问题排查

### Q1：点发送，输入框闪一下回弹，消息发不出去

**99% 是没走兼容快捷方式。** 检查桌面图标：
- 右键桌面 Antigravity 图标 → 属性 → 目标
- 正常应为：`C:\Windows\System32\wscript.exe "D:\...\antigravity-old-compat-manager\Launch-StableHidden.vbs"`
- 如果目标是 `D:\Antigravity\Antigravity.exe`，说明图标没被接管，重新跑一次「一键安装稳定模式」即可自动接管。

### Q2：模型一直转圈不响应

按顺序检查：
1. dotsvpn 是否连接、`127.0.0.1:51081` 是否在监听
2. version.dll 和 config.json 是否在 IDE 安装根目录（不是子目录）
3. 任务管理器 → Antigravity 进程 → 详细信息/模块，确认加载了 version.dll
4. 如果是放 DLL 之前启动的 IDE，完全关闭后重启（DLL 只在启动时加载）

### Q3：补丁报错「请先关闭 Antigravity 和语言服务器」

IDE 正在运行时不能打补丁。完全关闭所有 Antigravity 进程后再跑一键安装。
（图标接管不受影响，即使补丁被拦，桌面图标也已经自动改好了。）

### Q4：extension.js 被改坏换行符（历史问题）

如果出现 `xoe depends on UNKNOWN service agentSessions` 或聊天功能异常，用备份覆盖：
```
复制 D:\Desktop\脚本\extension.js.可用LF版-20260910
到   D:\Antigravity\resources\app\extensions\antigravity\dist\extension.js
```
（compat 项目已加四层防护防止换行符再被改坏，正常不会遇到。）

### Q5：想还原成原始直连图标

兼容管理器项目下 `backups\shortcuts\<时间戳>\` 里有原始图标备份，复制回桌面/开始菜单覆盖即可。

---

## 五、关键路径速查

| 项目 | 路径 |
|---|---|
| IDE 安装目录 | `D:\Antigravity\`（示例，按实际安装盘） |
| 脚本/备份目录 | `D:\Desktop\脚本\` |
| 兼容管理器 | `D:\Desktop\Super-File\AI-IDE\AI\反重力\antigravity-old-compat-manager\` |
| 注入项目 | `D:\Desktop\Super-File\AI-IDE\AI\反重力\Antigravity-Injection\` |
| IDE 日志 | `%APPDATA%\Antigravity\logs\` |
| 崩溃 dump | `%APPDATA%\Antigravity\Crashpad\reports\` |
| 扩展目录 | `C:\Users\Administrator\.antigravity\extensions\` |
| dotsvpn 代理 | `127.0.0.1:51081` |

---

## 六、一句话总结

> 装 IDE → 把 version.dll + config.json 复制到 IDE 根目录 → 跑「一键安装稳定模式」（自动打补丁+自动接管图标）→ 点桌面图标用。
