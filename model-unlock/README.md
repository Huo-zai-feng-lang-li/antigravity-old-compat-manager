# model-unlock・旧版 Antigravity 新模型放行工具链（正式、随仓库入库）

旧版 Antigravity（锁死 1.20.6，装在 `D:\Antigravity`）的语言服务器模型表是 2026-03 冻结的，

官方新模型（Claude 5.5 六档、未来 Gemini 3.9/4.0）在下拉里不存在。本目录是**前端放行的正式工具链**，

与 zk 插件后端改道（`Antigravity-Injection` 项目里的 `__agtarget` 旁路）配合，把新模型放行出来。

> 后端原理、唯一映射表、加模型完整步骤见仓库根目录 
>
> `SOP-新模型放行.md`
>
> （权威操作手册）。
> 历史一次性取证脚本仍留在 
>
> `evidence/`
>
> （已被 .gitignore 忽略，不入库）；本目录是入库的权威版本。

## 文件清单



| 文件                             | 作用                                                                                                               |
| ------------------------------ | ---------------------------------------------------------------------------------------------------------------- |
| `patch-workbench.mjs`          | 前端补丁生成器。从干净基线还原 workbench 后注入放行模型；5 锚点计数校验、注入后 `node --check`、失败自动回滚。**以后加新模型只改它顶部的&#x20;**`MODELS`**&#x20;映射表** |
| `verify-workbench.mjs`         | 只读校验当前运行态 workbench：每个放行 uid 应出现 3 次（下拉 / 可见列表 /store），并核对旁路与启动守卫。IDE 开着也能跑                                      |
| `list-official-uids.mjs`       | 从 `fetchAvailableModels.json` 列出官方全部 Claude/Gemini uid，加模型前用来取真实 uid                                             |
| `capture-official-catalog.mjs` | **新模型发布后取真实 uid 的护栏脚本**：临时让 zk 落盘官方 `fetchAvailableModels` 响应；`check`/`install`/`restore` 三态，自动备份 + 锚点自检 + `node --check` 失败回滚。详见《说明书-以后加新模型看这里.md》 |
| `decode-official-models.mjs`   | 辅助：从 zk 诊断日志 `_ea_diag.log` 的 `OFFICIAL-BODY-HEX` 解出模型目录（一般用 capture 即可，此为备用）|
| `说明书-以后加新模型看这里.md` | **下次官方发新模型（Gemini 3.9/4.x、Claude 5.6+）的傻瓜操作清单**：6 步流程 + 报错对照 + 锚点失配处理 + 信心边界 |
| `fetchAvailableModels.json`    | 官方 `fetchAvailableModels` 响应快照（2026-10-04），新模型 uid 的权威来源；加模型前先更新它                                                |
| `assets/prod-wb-pre-claude.js` | 干净 Gemini37 态 workbench 基线（约 23.8 MB），补丁的幂等还原源；**勿删**，删了无法还原 / 重打                                                |
| `assets/prod-main-pre-tpe.js`  | 干净 main.js 基线（约 8.4 MB，tPe 补丁前），仅手动回滚 main.js 时用。注意：**不入公开 git**（含 IDE 官方内置 OAuth client_id/secret），仅存本机/私有备份，换机需自行复制                                                            |

## 一键使用（日常）

关闭 Antigravity 后，在仓库根目录运行：



```
# -ForceKill：自动关闭 D:\Antigravity 的 Antigravity / language_server 后再打补丁
.\放行Claude六档.ps1 -ForceKill
```

脚本会调用本目录的 `patch-workbench.mjs`，完成后双击桌面彩色 A（wscript 启动器）启动 IDE。

手动等价流程：



```
# 1) 彻底关 IDE（ag=0、ls=0）  2) 打补丁  3) 校验
node model-unlock/patch-workbench.mjs
node model-unlock/verify-workbench.mjs   # 期望 SIX-TIERS OK (each uid x3)
```

## 以后发布新模型（如 Gemini 3.9 Flash / 4.0 Pro、Claude 5.6）

> **完整傻瓜步骤、报错对照、锚点失配处理，一律看同目录《说明书-以后加新模型看这里.md》；下面只是速记。**



1. **取真实 uid**：`node model-unlock/capture-official-catalog.mjs check`→`install`，重启 IDE 抓到官方目录覆盖 `fetchAvailableModels.json`，`restore` 撤探针，再 `node model-unlock/list-official-uids.mjs` 列 uid（详见《说明书》）。

2. 编辑 `patch-workbench.mjs` 顶部 `MODELS`：加 / 改一行 `{ label, uid }`（uid 必须与官方逐字一致，注意 `medium` 不是 `med`）。

3. 关 IDE，跑 `.\放行Claude六档.ps1 -ForceKill`，重启。

4. 下拉选新档发一句话，网络层确认 200 且 `modelVersion` = 该 uid（SOP 第三节）。

* 后端**通常零改动**：zk 旁路对任何非白名单 uid 都按 body.model 透传，新 uid 自动随网关路由。

## 注意



* IDE 安装路径写死 `D:\Antigravity`（patch/verify 顶部常量）；换盘符需同步修改。

* 本地旁路端口 `8937` 按 Windows 用户名 FNV 派生（当前 Administrator=8937）；换用户需改 `patch-workbench.mjs`

  里 `fetch("http://127.0.0.1:8937/__agtarget...")` 的端口。

* 打补丁前必须彻底关 IDE（含 language\_server），否则 workbench 文件被占用、写入不完整。