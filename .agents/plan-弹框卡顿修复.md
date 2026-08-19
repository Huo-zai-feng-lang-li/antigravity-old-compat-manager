# “应用并启动”弹框卡顿修复计划

## 目标

修复 `一键安装稳定模式.cmd` 打开的管理器在点击“应用并启动”后卡住的问题，同时保留关闭目标进程、应用兼容模式、启动 IDE 和错误诊断能力；“检测模型目录”每次点击实时读取 Google 官方公开目录，但不解除旧版 IDE 的稳定模型过滤。

## 根因证据

- `Antigravity稳定模式.ps1` 在子进程退出前不读取已重定向的标准输出和错误流，子进程输出超过管道缓冲区时会互相等待。
- `StableBootstrap.ps1` 失败后自行显示模态框；GUI 又在同步等待该子进程，错误框被遮挡时主窗口无法结束等待。
- 当前未提交改动正好引入了上述 `HasExited` 后再 `ReadToEnd()` 的等待顺序。

## 实施步骤

- [x] 在 `tests/Test-GuiBootstrapProcess.ps1` 中构造大错误输出的假 Bootstrap，验证 GUI 调用不会阻塞且会传递禁止子弹框参数。
- [x] 运行测试确认旧实现失败。
- [x] 修改 `Antigravity稳定模式.ps1`：用 `ArgumentList` 传参，启动后立即异步排空输出流，并传递 `-SuppressErrorDialog`。
- [x] 修改 `StableBootstrap.ps1`：GUI 调用时把诊断写入错误流，不再显示子进程模态框；其他入口保持原弹框行为。
- [x] 运行定向测试、现有 PowerShell 测试和 `.NET` 测试，检查语法、行为与回归。
- [x] 检查并清理测试产生的子进程。

## 官方目录扩展

- [x] 新增官方 Models 页面解析测试，覆盖完整 Reasoning Model 表格、去重和 Additional Models 隔离。
- [x] 新增 `tools/OfficialModelCatalog.mjs`，每次请求 `https://antigravity.google/docs/models`，不使用本地缓存。
- [x] 管理器优先展示官方公开模型；若本机启用了 CDP，再附加展示旧版 IDE 当前可见目录。
- [x] 保持 `scripts/StableMode.Core.psm1` 的 allowlist 不变，未知新模型只展示为未验证，不自动进入旧版下拉框。

## 完成标准

- 大于管道缓冲区的子进程错误可在限定时间内返回，不发生等待死锁。
- GUI 调用失败时只在主窗口展示错误，不出现隐藏的子进程模态框。
- 正常 Bootstrap 仍能应用模式并启动 `Antigravity.exe`。
- 点击“检测模型目录”无需 CDP 也能返回官方最新模型，并明确区分官方公开目录与旧版当前可见目录。
- 现有测试全部通过，测试结束后无本任务遗留进程。
