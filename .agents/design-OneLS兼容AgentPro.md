# OneLS 兼容 Agent Pro 设计

## 目标
- 保留 `codeiumDev.useOneLS=true`，不回退已经稳定的共享 HTTP LS 发送链。
- 让主进程共享 LS 在启动前等待 Agent Pro 本地代理就绪，随后把 `--cloud_code_endpoint` 指向已验证的本地端点。
- Agent Pro 未安装、被禁用或代理启动失败时，限时后自动使用官方端点，不能阻断 IDE。
- 修复旧版 `.obsolete` 记录把当前 Agent Pro 误判为卸载的问题。

## 方案对比
1. **共享 LS 启动等待桥（采用）**：在 `resources/app` 部署一个无副作用的桥接模块。它只发现 Agent Pro、读取动态端口并轮询 `/origin/ping`；不加载代理源码。主进程在 spawn LS 前调用桥，成功才改写端点，失败走官方链路。
2. **独立代理 sidecar（拒绝）**：能保证启动顺序，但需要常驻进程、生命周期监督和孤儿清理，不符合无感与最少人工干预。
3. **关闭 OneLS（拒绝）**：可以恢复旧注入链，但会重新暴露本地 HTTPS/TLS 与重启发送问题。

## 架构
- `runtime/OneLSAgentProxyBridge.cjs`：纯 Node 模块，扫描 `~/.antigravity/extensions/zk-agent.dao-proxy-pro-*`，排除精确 `.obsolete` 版本，选最高语义版本；从 `~/.dao/origin-port.json` 和用户名 FNV 端口发现候选代理；验证 `/origin/ping` 的 `self_file` 必须指向选中的安装目录。
- `scripts/StableMode.Core.psm1`：为当前与已知历史 `main.js` 提供严格一次锚点转换，在共享 LS `spawn` 前等待桥接结果；结果有效才替换 `--cloud_code_endpoint`。未知结构 fail-closed。
- `StableBootstrap.ps1` / 安装事务：把桥接模块原子部署到 `resources/app/dao-one-ls-agent-pro.cjs`，纳入状态检查、备份与恢复。
- `windsurf-assistant/plugins/dao-proxy-pro/extension.js`：卸载侦测只接受 `.obsolete[current selfDir]===true`；旧版本记录不得触发当前版本清锚。

## 数据流
1. Antigravity 主进程准备启动共享 LS。
2. 桥接模块确认 Agent Pro 当前安装版本，并等待其 extension-host 代理发布动态端口。
3. `/origin/ping` 校验通过后返回 `http://127.0.0.1:<port>`。
4. 主进程仅替换 LS 参数中的 `--cloud_code_endpoint`，然后启动共享 LS。
5. OneLS 工作台继续连接主进程发布的 HTTP 端口；模型请求进入 Agent Pro，提示词转换后再上游。

## 失败安全
- 未安装 Agent Pro：立即官方直通，不等待。
- 已安装但未激活：最多等待 10 秒，随后官方直通。
- 端口文件损坏、端口被占用、`self_file` 不匹配：拒绝接管并官方直通。
- 不修改 OAuth、用户状态、模型目录或默认 HTTPS 客户端。
- 不新增常驻 UI、PowerShell、Node sidecar 或黑窗口。

## 验收
- 单元测试覆盖桥接发现、旧版 obsolete 排除、动态端口、伪代理拒绝、超时回退。
- main 转换红绿测试覆盖唯一锚点、幂等、回退、未知输入拒绝。
- Agent Pro 红绿测试覆盖当前版本卸载、旧版本卸载、正常注册、注册缺失。
- 冷启动两轮：不切账号均可发送并收到回复；LS Args 指向本地代理；`/origin/tape` 出现 `GEMINI_REST_CHAT transformed=true`；关闭后无新增孤儿进程。
