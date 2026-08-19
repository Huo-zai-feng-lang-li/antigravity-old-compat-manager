# OneLS 兼容 Agent Pro 取证笔记

- 19:06:42：Agent Pro 9.9.335 `_lastinject.json` 记录 `GEMINI_REST_CHAT`、`transformed=true`、字段 `request.systemInstruction.parts`。
- 19:15：设置加入 `codeiumDev.useOneLS=true`；备份文件没有该键。
- 19:15 后新会话取证：`--cloud_code_endpoint` 官方地址 8 次，本地 8937 为 0；Agent Pro 捕获不再更新。
- workbench `Hts.z()` 在本地且 `useOneLS=true` 时走 `Hts.C()`，订阅主进程 `uss-lsClientMachineInfos` 的 HTTP 端口；默认 `Hts.F()` 才使用窗口侧 LS。
- 主进程 `Gde.t()` 先通过 `qZr()` 构造 `--cloud_code_endpoint`，随后直接 `child_process.spawn()` 共享 LS。
- 不能把 Agent Pro `source.js` 直接加载进 Electron main：模块顶层会注册 `uncaughtException` / `unhandledRejection`，会污染主进程错误语义。
- Agent Pro `_isSelfUninstalling()` 当前会把 `.obsolete` 中任一本族旧版本当成当前版本卸载；本机仅旧 9.9.331/9.9.332 为 true，当前 9.9.335 并未 obsolete。
