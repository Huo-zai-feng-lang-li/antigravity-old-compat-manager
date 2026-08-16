# 无感快速启动

- [x] 取证旧快捷方式直接启动 `pwsh.exe`，即使指定 Hidden 仍可能闪现控制台。
- [x] 使用 `wscript.exe -> Launch-StableHidden.vbs -> StableBootstrap.ps1`，隐藏且异步启动。
- [x] 档案加入 extension.js 目标哈希，避免健康状态每次重新解析大型 JavaScript。
- [x] 保留 product.json 版本、日期、workbench checksum 快速漂移检测。
- [x] 健康路径基准从约 20 秒降至约 1.6 秒。
- [x] 单元检查与临时安装自适应/漂移修复集成测试通过。
- [ ] 用户双击新版快捷方式，确认主观无黑窗并正常拉起 IDE。
