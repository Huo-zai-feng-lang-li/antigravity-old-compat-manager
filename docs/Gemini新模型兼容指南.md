# Gemini 新模型兼容指南与本次复盘

## 本次为什么反复失败

本次问题不是一个开关，而是三条独立链路叠加：模型目录、旧工作台选择状态、Agent Pro 上游路由。前几轮只证明了其中一部分，导致界面看似恢复但全链路仍失败。

1. 早期动态修改 Workbench 的选择状态机，引入 `sort/shift/render` 调度循环，IDE 在启动约两分钟后出现 `CodeWindow` 无响应。
2. 回退到原生 Workbench 后，曾把完整模型配置写入 `defaultOverrideModelConfig`，实际结果是模型下拉框为空。
3. 只放出 Gemini 3.7 标签时，旧协议仍用 `RECOMMENDED` alias 8 作为选择载体；Agent Pro 最终把请求发成 `gemini-2.5-pro`，服务端返回 `MODEL_CAPACITY_EXHAUSTED`。这证明“显示 3.7”不等于“调用 3.7”。
4. v13 才在 Agent Pro 边界把严格等于 `gemini-2.5-pro` 的兼容占位请求改写为 `gemini-3.7-flash-high`，并把代理文件纳入安装事务；Gemini 3.6、Claude 和非 JSON 请求保持不变。
5. Gemini 3.7 High 与 Medium 当前共享同一个 alias。为防重复项，UI 按 choice 去重，因此 Medium 不显示。这是已知限制，不是服务端响应故障。

核心教训：静态结构检查、模型显示、短时不卡死都不能单独证明兼容完成。必须发送真实请求并确认实际上游模型。

## 当前状态

- Claude、Gemini 3.6、Gemini 3.7 High：用户已实测可正常响应。
- Gemini 3.7 Medium：当前未显示，等待独立稳定选择载体。
- v13 静态状态：IDE 与 Agent Pro 哈希、结构、产品校验和均通过。
- 180 秒冷启动：最长无响应 0 秒，`CodeWindow unresponsive` 事件 0。

## 未来 3.8、3.9 的兼容流程

### 1. 官方取证

- 从 Google 官方模型目录确认显示名、档位和精确 model slug。
- 只加入候选报告，不自动进入旧版 allowlist。

### 2. 旧协议取证

- 在未修改生产文件的环境捕获模型目录对象，确认 model ID、alias 和请求体字段。
- 检查选择载体是否与现有模型冲突。冲突时不能同时放行。

### 3. 建立显式映射

每个档位都必须有唯一三元组：

```text
显示标签 -> 旧协议选择载体 -> 官方上游 model slug
```

不得从版本号推算 model ID，不得用 UI 标签反推上游模型。

### 4. 先写失败测试

- 目录：目标项存在一次，Claude/3.6/已发布 3.7 保持存在，Low 和未知模型不出现。
- 选择：切换与重启后保持正确，不触发动态渲染状态机。
- 路由：只改写目标请求，其他模型和异常输入保持原字节。
- 安装：重复执行幂等，切回 Stable 清理完整，故障时按清单恢复原字节。

### 5. 最小实现

- `main.js` 边界只负责目录 allowlist。
- Workbench 只使用已验证的静态选择载体；没有独立载体就暂缓该档位。
- Agent Pro 边界用精确映射表改写上游 model slug，不做模糊匹配。
- Bootstrap 升级 schema/patch，记录所有目标哈希并强制旧档案迁移。

### 6. 发布验收

- 全套 PowerShell、Node、.NET 回归通过。
- 在临时安装副本验证应用、幂等、跨模式切换和失败回滚。
- 部署后用 CDP 核对模型列表。
- 每个新增模型各发送一次唯一提示，记录实际上游 model slug 与成功响应。
- 至少观察 180 秒冷启动，窗口连续无响应小于 5 秒且日志事件为 0。
- 清理任务启动的所有 IDE、语言服务器和测试进程。

## Gemini 3.7 Medium 待办

只有满足以下任一条件才继续实现：

1. 官方/旧协议返回一个与 High 不同、可持久化的 model ID 或 alias；或
2. 设计出静态、可回滚、不会参与 Workbench 渲染循环的旁路标记，并能让 Agent Pro 可靠区分 High 与 Medium。

在此之前强行显示 Medium 会重新引入“标签可见但路由不可区分”或 IDE 卡死风险，因此保持未发布。
