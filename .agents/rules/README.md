# 项目架构契约与演进规则

> **核心目标**：保障反重力旧版 IDE 能稳定调用官方最新旗舰高推理模型（High / Thinking），改动必须一次性闭环。

---

## 1. 架构三层解耦与改动清单

系统由三个严格隔离的边界组成，**模型升级必须三层同步修改，缺一不可**：

| 层级 | 关键文件 | 改动要点 | 注意事项与陷阱 |
| :--- | :--- | :--- | :--- |
| **展示层 (UI)** | `scripts/StableMode.Core.psm1`<br>`Antigravity稳定模式.ps1` | 1. `$script:Gemini37Allowlist` 放行目标标签。<br>2. GUI 单选框与 `Format-Status` 显示名映射。 | **防去重冲突**：同选择载体只放 High 档位；UI 文本必须同步升级，严禁底层改了 UI 仍显示旧版本。 |
| **选择层 (IDE)** | `scripts/StableMode.Core.psm1` (Workbench) | 维持静态注入，使用 `RECOMMENDED` (Alias 8) 作为载体。 | **防卡死禁令**：严禁在 Workbench 动态修改状态机或排序，否则导致 `CodeWindow` 渲染死循环崩溃。 |
| **路由层 (Agent)** | `runtime/Gemini37AgentProxyCompat.cjs` | 更新 `TARGET_MODEL = "目标 slug"`。 | **特征靶子契约**：仅将旧协议生成的占位符 `gemini-2.5-pro` 改写为目标模型；Claude 及其他请求原样透传。 |

---

## 2. 选型战略与边界（用户核心偏好）

- **高推理唯一主力**：仅维护官方最新 **High / Thinking** 档位。
- **旧代彻底淘汰**：全面废弃 3.5 / 3.6 / 3.7，不为其做任何新增兼容与特化支持。
- **IDE 列表极简纯净**：界面下拉框仅保留：
  - `Claude Sonnet 4.6 (Thinking)`
  - `Claude Opus 4.6 (Thinking)`
  - `Gemini 3.8 Flash (High)`（后续随官方版本单点顺延）

---

## 3. 改动闭环操作检查清单 (Checklist)

修改完毕后，按顺序执行以下步骤取证，无硬证据严禁声称“已解决”：

1. **语法与静态校验**：
   - 检查 CRLF / LF 兼容性，确保正则与字符串匹配支持多换行。
2. **集成测试验证**：
   - 运行 `pwsh -NoProfile -File tests/Test-CompatibilityInstallIntegration.ps1`（验证安装、幂等、回滚事务）。
   - 运行 `node tests/Test-Gemini37AgentProxyCompat.cjs`（验证仅目标靶子改写，Claude 原样放行）。
3. **真实端到端验证**：
   - 运行诊断确认状态文本所见即所得：`pwsh -NoProfile -File Antigravity稳定模式.ps1 -Mode Diagnose -CompatibilityMode Gemini37`。
   - 启动 IDE 发送真实请求，确认代理日志收到目标 `gemini-3.x-flash-high` 且响应成功。
   - 确认启动 180 秒内无 `CodeWindow unresponsive` 事件。
