# 最新接续状态 (2026-09-05 12:53)

## 核心进展
- 与姊妹插件 **zk-agent.zk-proxy-pro@9.9.528** 完成命名统一与职责切分，最新 commit `d0a339c`，工作区干净、已 push。
- 关键文件：`runtime/OneLSAgentProxyBridge.cjs`（AGENT_PRO_ID）、`scripts/StableMode.Core.psm1`（$prefix 与兼容模式核心）、`Antigravity稳定模式.ps1`（入口）。

## 核心动机与背景 (Motivation & Background)
- 本项目是**兼容层**，专门处理「改 IDE app 目录 / LS 启动时序」类问题；姊妹插件 Antigravity-Injection 是**注入层**，处理请求体改写。两者功能零重叠、互不影响。
- 诞生背景：官方发布新 3.5 模型时，模型 id 导致 IDE 打开即卡死（死循环），故需要模型列表过滤；低版本 IDE 不能直接用，需要版本伪装。

## 关键设计与实现 (Implementation & Decisions)
- **Bridge 部署**：`runtime/OneLSAgentProxyBridge.cjs` 中 `AGENT_PRO_ID = "zk-agent.zk-proxy-pro"`，部署到 `D:\Antigravity\resources\app\dao-one-ls-agent-pro.cjs`，让 IDE 主进程的 Agent Pro bridge 能发现并指向本地插件代理。
- **扩展目录前缀**：`scripts/StableMode.Core.psm1` 中 `$prefix='zk-agent.zk-proxy-pro-'`，用于扫描最高 semver 扩展版本。
- **版本伪装**：改 `D:\Antigravity\resources\app\product.json` ideVersion=2.5.5，重装/初始化 IDE 后需重新应用。
- **模型列表过滤/白名单**：改 workbench.js，防止新模型 id 导致 IDE 卡死；当前白名单 Claude Sonnet/Opus 4.6 (Thinking)、Gemini 3.8 Flash (High)。
- **命令行 Apply**：`pwsh -File "Antigravity稳定模式.ps1" -Mode Apply -CompatibilityMode Gemini37 -InstallRoot "D:\Antigravity"`；也可用「一键安装稳定模式-反重力.cmd」。
- **职责边界（重要）**：本项目**不再负责模型改写/动态映射**（v9.9.524 起已移入插件），也不负责提示词注入、摘要剔除、标题汉化、模型解锁（插件侧 v9.9.528 已默认禁用解锁，因账号登录后官方本身返回全量模型）。
- 已清理 backups(2GB)/logs/.codegraph 等历史垃圾；.gitignore 已忽略 backups/logs/.codegraph。

## 待办事项 (Next Steps)
- [ ] 无必须修改项，当前与插件 9.9.528 匹配、工作正常。
- [ ] 重装/重新初始化 IDE 后：运行一次本项目「应用并启动」即可（部署 Bridge + 版本伪装 + 模型过滤），之后安装插件 VSIX，插件自动工作。

## 关键上下文
- 目录: D:\Desktop\Super-File\AI-IDE\AI\反重力\antigravity-old-compat-manager
- 姊妹插件: D:\Desktop\Super-File\AI-IDE\AI\反重力\Antigravity-Injection (zk-agent.zk-proxy-pro)
- IDE 安装根: D:\Antigravity
- GitHub: https://github.com/Huo-zai-feng-lang-li/antigravity-old-compat-manager ；外网代理 http://127.0.0.1:51081
- 命名必须与插件 publisher.name 严格一致（zk-agent.zk-proxy-pro），否则 Bridge 匹配不到插件、代理不生效
