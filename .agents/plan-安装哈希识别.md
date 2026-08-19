# 安装哈希识别

## 目标

- Core 仅表达安装快照、兼容档案和完整组合匹配，不执行文件 I/O。
- Windows Infrastructure 安全读取档案声明文件并生成确定性快照。
- 未知、缺失、漂移或多重匹配安装一律只读。

## 阶段状态

- [x] 取证现有域模型、项目引用和安全约束。
- [x] 新增 Core / Windows Infrastructure 行为测试。
- [x] RED：Core 与 Infrastructure 测试均因目标类型缺失而编译失败，退出码均为 1。
- [x] 最小实现 Core 档案匹配、Windows 探针和 JSON 仓库。
- [x] GREEN：Core 档案测试 27/27、Windows Infrastructure 测试 3/3；主线程 fresh Release 验证 Core 35/35、Infrastructure 3/3、build 退出码 0。
- [x] 字符级 SHA 自审回归：先以 `Assert.Throws() Failure: No exception was thrown` 复现 RED，再修复并单测 1/1 GREEN。
- [x] 完整组合不变量：FileState 路径集合一致、InstallationState 唯一、Models 非空；RED 3 项失败，GREEN 定向 31/31，全量 Release 42/42，构建 0 警告 0 错误。

## RED 证据

- Core：`CS0246`，缺少 `InstallationState`、`CompatibilityProfile`、`FileSignature`、`InstallationSnapshot`。
- Infrastructure：`CS0246`，缺少 `ProfileCatalog`。

## 影响边界

- 未读取或修改生产安装目录、状态库、Token。
- 未实现补丁事务或生产写入。
- 未知、缺文件、文件漂移和多重匹配均保持诊断只读。
