# Low 模型残留修复计划

## 目标

- Gemini36 模式仅展示 Gemini 3.6 High/Medium；隐藏 Gemini 3.5 全档位和 Gemini 3.6 Low。
- 旧 Gemini36 补丁可被识别并原地迁移，不再显示 `Unknown`。
- GUI 完整显示 `Gemini 3.6 兼容模式（High/Medium）`。

## 阶段

- [x] 取证：生产安装仍是旧 Gemini36 v1（3.5 全档位、3.6 Low、ID 1266），核心旧结构校验通过，但模式识别未接入旧结构。
- [x] RED：补充旧结构识别/直接迁移与 GUI 防裁剪测试；分别因旧模式无法识别、RadioButton 未启用 AutoSize 按预期失败。
- [x] GREEN：接入严格配对的旧结构识别与直接迁移，RadioButton 启用 AutoSize；两项定向测试退出 `0`。
- [x] REVIEW：Candidate/Set 实际路径严格拒绝新旧混合代际；旧 Stable 名单可升级为仅 Claude；Current/Legacy 文件内混合名单均 fail-closed。
- [x] VERIFY：PowerShell `10/10`；.NET `42/42`；Release 构建 `0` 警告/`0` 错误；raw Stable 固定哈希迁移与 `D:\Antigravity` 旧 Gemini36 真实字节副本迁移通过；GUI 宽度 `272=272`；生产目录哈希未改。
- [x] 二次取证：生产 `main.js` 仍命中 Gemini 3.5 Low、Gemini 3.6 Low，workbench 仍是 `[1264,1265,1266]`；`StableBootstrap -CheckOnly` 把旧 `compatibility-v2` profile 判成 `KnownTarget=true`，因此直接跳过修复。
- [x] RED：旧策略 profile 的集成测试先因 schema/patch 仍是 v2 失败；GUI 契约先因缺少 `-StopRunningProcesses` 失败；重复 profile 测试先得到 3 份当前目标；非自适应未知哈希测试先被错误接受。
- [x] GREEN：引入 schema 3 / `compatibility-v3-no-low` 门禁；旧 profile 不再命中快速路径；GUI 确认后仅关闭所选安装根目录进程；单选切换立即刷新目标状态；当前目标 profile 自动去重。
- [x] REVIEW：真实旧 Stable 字节复验返回 `Stable`；非自适应来源/候选固定哈希门禁恢复，`AllowAdaptive` 仍为明确受控例外；独立目录同名进程测试证明不会误伤。
- [x] VERIFY：PowerShell `11/11`；.NET `42/42`；Release 构建 `0` 警告/`0` 错误。生产应用生成备份 `stable-20260806T032802533Z`，缓存键 `modelPreferences` 已删除，Bootstrap `KnownTarget=true`；CDP 实测 UI 仅列出 2 个 Claude 与 Gemini 3.6 High/Medium，禁止列表为空。

## 边界

- 只有用户在 GUI 应用确认框明确同意，或 CLI 显式传入关闭开关时，才结束所选安装根目录内的 Antigravity/语言服务器进程。
- 本轮目标明确要求真实生产闭环；完成前必须修改并验证 `D:\Antigravity`，不能再用副本测试代替生产结果。
- 未知或新旧混合结构继续 fail-closed。
