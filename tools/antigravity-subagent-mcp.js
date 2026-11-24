#!/usr/bin/env node
/**
 * antigravity-subagent-mcp.js
 * 反重力 IDE 独立 API 驱动代码审查与子代理引擎（stdio MCP 模式）
 *
 * 核心架构特性：
 * 1. 原生 API 直连：彻底消除外部 CLI 依赖与跨平台进程残留
 * 2. 顶级深度推理 (Reasoning)：默认锁定 max 顶级思维链推导，全面捕获死锁、时序竞态、圈复杂度与边界隐患
 * 3. 智能模型双轨容灾：优先 3.0 (agnes-3.0-flash)，超时或网关异常自动无缝平滑降级 2.5 (agnes-2.5-flash) 继续以 max 推理完成审查
 * 4. 并发派出支持 (Parallel Subagents)：
 *    - 协议级非阻塞异步并发：支持 IDE / 客户端并发调用多次 invoke_subagent，底层 HTTP 并行发出互不阻塞
 *    - 批量并发派出工具：invoke_subagents_parallel / invoke_subagent 支持传入 tasks 数组一次性并发派出多个子代理
 *    - 多 Key 负载均衡：多任务并发时轮询分配独立 API Key，杜绝单 Key 瞬时并发限流 (429)
 * 5. 真实代码物理装配：自动读取源文件打上行号，提供无偏差的自包含执行上下文
 * 6. 健壮的 Socket 资源清理与主动销毁机制
 */

const fs = require('fs');
const path = require('path');
const http = require('http');
const https = require('https');
const urlMod = require('url');

const DEFAULT_BASE_URL = (process.env.SUBAGENT_BASE_URL || 'https://apihub.agnes-ai.cn/v1').replace('apihhub.', 'apihub.');
const DEFAULT_MODEL = process.env.SUBAGENT_MODEL || 'agnes-3.0-flash';
const FALLBACK_MODEL = process.env.SUBAGENT_FALLBACK_MODEL || 'agnes-2.5-flash';
const DEFAULT_REASONING_EFFORT = 'max';
const PROXY_URL = process.env.SUBAGENT_PROXY || null;

// 安全加载 API Key：严禁在公开代码中硬编码任何真实密钥
// 优先级：1. 本地 keys.json -> 2. 环境变量 SUBAGENT_API_KEYS (逗号分隔) -> 3. 环境变量 SUBAGENT_API_KEY
function loadApiKeys() {
  const keys = [];
  const localKeysPath = path.join(__dirname, 'keys.json');
  if (fs.existsSync(localKeysPath)) {
    try {
      const parsed = JSON.parse(fs.readFileSync(localKeysPath, 'utf8'));
      if (Array.isArray(parsed)) keys.push(...parsed);
      else if (parsed.keys && Array.isArray(parsed.keys)) keys.push(...parsed.keys);
    } catch (e) {}
  }
  if (process.env.SUBAGENT_API_KEYS) {
    keys.push(...process.env.SUBAGENT_API_KEYS.split(',').map(k => k.trim()));
  }
  if (process.env.SUBAGENT_API_KEY) {
    keys.push(process.env.SUBAGENT_API_KEY.trim());
  }
  return Array.from(new Set(keys.filter(Boolean)));
}

const API_KEYS = loadApiKeys();

let currentKeyIndex = 0;
function getActiveKey() {
  if (API_KEYS.length === 0) return '';
  return API_KEYS[currentKeyIndex % API_KEYS.length];
}
function rotateKey() {
  if (API_KEYS.length === 0) return '';
  currentKeyIndex = (currentKeyIndex + 1) % API_KEYS.length;
  return API_KEYS[currentKeyIndex % API_KEYS.length];
}
function getNextKeyForTask() {
  if (API_KEYS.length === 0) return '';
  const key = API_KEYS[currentKeyIndex % API_KEYS.length];
  currentKeyIndex = (currentKeyIndex + 1) % API_KEYS.length;
  return key;
}

/**
 * 健壮的 HTTPS / HTTP 隧道请求封装
 * 具备精确超时中断与 Socket 资源强制销毁
 */
function sendRequestViaProxy(targetUrlStr, postBody, apiKey, timeoutMs = 120000) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify(postBody);
    const targetParsed = urlMod.parse(targetUrlStr);
    const targetHost = targetParsed.hostname;
    const targetPort = targetParsed.port || (targetParsed.protocol === 'https:' ? 443 : 80);
    const targetPath = targetParsed.path;

    let proxyParsed = null;
    if (PROXY_URL) {
      try {
        proxyParsed = urlMod.parse(PROXY_URL);
      } catch (e) {
        proxyParsed = null;
      }
    }

    let isCompleted = false;
    let activeReq = null;
    let activeSocket = null;

    const cleanup = () => {
      isCompleted = true;
      clearTimeout(timer);
      if (activeReq && !activeReq.destroyed) {
        try { activeReq.destroy(); } catch (e) {}
      }
      if (activeSocket && !activeSocket.destroyed) {
        try { activeSocket.destroy(); } catch (e) {}
      }
    };

    const timer = setTimeout(() => {
      cleanup();
      const err = new Error(`Request timeout after ${timeoutMs}ms`);
      err.code = 'ETIMEDOUT';
      reject(err);
    }, timeoutMs);

    // 直连 HTTPS
    if (!proxyParsed || !proxyParsed.hostname) {
      const directReq = https.request({
        host: targetHost,
        port: targetPort,
        path: targetPath,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`,
          'Content-Length': Buffer.byteLength(postData)
        },
        rejectUnauthorized: false
      }, (res) => {
        let respData = '';
        res.on('data', chunk => respData += chunk);
        res.on('end', () => {
          if (!isCompleted) {
            cleanup();
            resolve({ status: res.statusCode, text: respData });
          }
        });
      });

      activeReq = directReq;
      directReq.on('error', (err) => {
        if (!isCompleted) {
          cleanup();
          reject(err);
        }
      });
      directReq.write(postData);
      directReq.end();
      return;
    }

    // 走 HTTP CONNECT 隧道
    const connectReq = http.request({
      host: proxyParsed.hostname,
      port: proxyParsed.port || 80,
      method: 'CONNECT',
      path: `${targetHost}:${targetPort}`
    });

    activeReq = connectReq;

    connectReq.on('connect', (res, socket) => {
      if (isCompleted) {
        try { socket.destroy(); } catch (e) {}
        return;
      }
      activeSocket = socket;

      const tlsReq = https.request({
        host: targetHost,
        path: targetPath,
        method: 'POST',
        socket: socket,
        agent: false,
        rejectUnauthorized: false,
        headers: {
          'Host': targetHost,
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`,
          'Content-Length': Buffer.byteLength(postData)
        }
      }, (tlsRes) => {
        let respData = '';
        tlsRes.on('data', chunk => respData += chunk);
        tlsRes.on('end', () => {
          if (!isCompleted) {
            cleanup();
            resolve({ status: tlsRes.statusCode, text: respData });
          }
        });
      });

      activeReq = tlsReq;
      tlsReq.on('error', (err) => {
        if (!isCompleted) {
          cleanup();
          reject(err);
        }
      });
      tlsReq.write(postData);
      tlsReq.end();
    });

    connectReq.on('error', (err) => {
      if (!isCompleted) {
        cleanup();
        reject(err);
      }
    });
    connectReq.end();
  });
}

// 审查专家的系统 Prompt：定位为红队破坏性测试专家与极端边界猎犬（Adversarial Edge-Case Inspector）
// 核心原则：做其擅长的反常识推演与死锁排查；严禁代写代码，严禁盲目挑刺语法糖
const SYSTEM_AUDIT_PROMPT = `你是一个无状态的【红队破坏性测试专家与极端边界猎犬】（Adversarial Edge-Case & Defect Hunter）。
你的唯一使命是站在攻击者、弱网环境与并发混沌工程的视角，对主代理提交的方案进行冷酷的逻辑推演，寻找主代理未考虑到的【极端盲区与死锁破绽】。

【你必须做（你擅长的事）】：
1. 寻找【时序并发与状态机死锁】：乱序响应、并发重入缺少幂等锁、Promise 悬空不结束、事件监听器未注销导致的内存泄漏；
2. 寻找【极端异常边界】：null/undefined 未防护解构、空数组/空对象越界、跨 iframe/跨域沙箱环境差异、网络突然断开/重试雪崩；
3. 寻找【对抗性破绽与环境自相矛盾】：伪装属性暴露（未设不可枚举）、原型链污染、特征检测不一致导致的防风控失败；
4. 给出【最小破绽推演与复现场景】：明确指出在何种具体的调用顺序或极端输入下，代码会出现异常。

【你严禁做（你绝对不擅长的事，严禁添乱）】：
1. ❌【严禁提供所谓“直接替换的代码块 (Drop-in replacement)”】：你处于无本地编译器、无真机单测的纯文本沙箱，你编写的具体代码往往包含语法陷阱（如模板转义失真、未导入符号）。你只需指出【破绽根因】与【防御思路伪指引】，严禁代写落地代码！
2. ❌【严禁为了提建议而强行挑刺】：严禁将语义清晰的 if 条件强行改成复杂的正则表达式或花哨语法糖！严禁挑刺无实质风险的代码风格！
3. ❌【没有漏洞就坦诚通过】：若方案逻辑闭环、边界完备，必须明确输出【审计通过】，并给出 1-2 句核心依据，严禁无病呻吟！

输出规范格式：
- 如果没有实质漏洞：
  【审计通过】
  核心依据：[简练阐述逻辑为何已闭环]
- 如果发现破绽：
  【严重级别】：[严重 Critical / 高危 High / 中危 Medium / 疑点 Warning]
  【位置定位】：具体文件与关键代码行
  【破绽推演】：在何种极端边界或时序条件下会触发故障？（推演具体反例场景）
  【防御思路】：指出逻辑防御要点（仅提供思路与概念防线，严禁提供整段代码）
- 结尾必须包含：
  【复核要求】：提醒主代理必须在本地编译器与单元测试下亲自验证，严禁盲信。
保持客观犀利，直击核心，拒绝一切虚浮客套。`;

/**
 * 判断是否属于 3.0 超时或网关异常，需要自动平滑降级为 2.5
 */
function shouldDowngradeTo25(currentModel, errOrStatus) {
  if (!currentModel || !currentModel.includes('3.0')) return false;
  if (typeof errOrStatus === 'number') {
    // 408 Request Timeout, 502 Bad Gateway, 503 Service Unavailable, 504 Gateway Timeout, 520-524 Cloudflare / CDN Timeout
    return [408, 502, 503, 504, 520, 521, 522, 524].includes(errOrStatus);
  }
  const msg = String(errOrStatus?.message || errOrStatus || '').toLowerCase();
  return (
    msg.includes('timeout') ||
    msg.includes('timed out') ||
    msg.includes('econnreset') ||
    msg.includes('hang up') ||
    msg.includes('etimedout') ||
    msg.includes('esockettimedout') ||
    msg.includes('abort')
  );
}

/**
 * 单个子代理任务的核心执行逻辑
 */
async function executeSubagentSingle({
  user_goal,
  solution_summary,
  review_focus,
  task,
  files = [],
  model = DEFAULT_MODEL,
  reasoning_effort = DEFAULT_REASONING_EFFORT,
  timeout = 120,
  assignedKey = null,
  subagentName = ''
}) {
  // 1. 前置拦截：防空指令
  if (!user_goal && !task) {
    return {
      content: [{
        type: "text",
        text: `[子代理协议拦截${subagentName ? ` - ${subagentName}` : ''}]: 缺少审查目标！必须提供 user_goal + solution_summary，或自包含的 task 指令。`
      }],
      isError: true
    };
  }

  // 2. 前置拦截：防伪连续性口吻（无状态会话严禁假定有记忆）
  const combinedDirective = `${user_goal || ''} ${solution_summary || ''} ${task || ''}`;
  const pseudoContinuityRegex = /(上一轮|上一场|之前你提到|之前指出的|前面指出|如前所述|刚才说的|如上所示)/;
  if (pseudoContinuityRegex.test(combinedDirective) && (!user_goal || !solution_summary)) {
    return {
      content: [{
        type: "text",
        text: `[子代理协议拦截${subagentName ? ` - ${subagentName}` : ''}]: 子代理为完全无状态（Stateless）独立单次会话，没有记忆！检测到指令中包含'上一轮'/'如前所述'等伪连续代词，且未提供完整的结构化上下文。请必须拆开提供【user_goal】（用户原始诉求）与【solution_summary】（主代理修复方案）后重试。`
      }],
      isError: true
    };
  }

  // 3. 自动组装标准化三段式自包含 Prompt
  let finalDirective = '';
  if (user_goal && solution_summary) {
    finalDirective = `【独立代码与架构审计任务${subagentName ? ` - ${subagentName}` : ''}】\n\n### 一、用户原始业务目标与痛点背景\n${user_goal}\n\n### 二、主代理修复方案与实现逻辑\n${solution_summary}\n\n### 三、审查重点\n${review_focus || task || '全链路边界条件、并发竞态、状态机收敛及潜在破坏性回归'}`;
  } else {
    finalDirective = task;
  }

  // 4. 组装物理文件上下文
  let fileContext = '';
  if (Array.isArray(files) && files.length > 0) {
    for (const filePath of files) {
      try {
        if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
          const content = fs.readFileSync(filePath, 'utf-8');
          const lines = content.split('\n').map((line, idx) => `${idx + 1}: ${line}`).join('\n');
          fileContext += `\n\n=== 文件: ${filePath} ===\n${lines}\n=== 文件结束 ===\n`;
        } else {
          fileContext += `\n\n[提示: 文件未找到或不是普通文件: ${filePath}]`;
        }
      } catch (err) {
        fileContext += `\n\n[读取文件 ${filePath} 失败: ${err.message}]`;
      }
    }
  }

  const promptContent = fileContext
    ? `${finalDirective}\n\n以下是待审查的相关文件源码：${fileContext}`
    : finalDirective;

  // 核心硬约束：默认强制锁定 max 顶级思维链推理，杜绝浅层思考
  const targetEffort = 'max';

  let currentModel = model || DEFAULT_MODEL;
  let currentEffort = 'max';
  let downgraded = false;
  let downgradeReason = '';
  let successfulData = null;
  let lastErrorText = '';

  const totalTimeoutSec = Math.max(10, Number(timeout) || 120);
  const attempts = Math.max(3, API_KEYS.length || 1);
  let activeApiKey = assignedKey || getActiveKey();

  for (let attempt = 0; attempt < attempts; attempt++) {
    // 如果首选是 3.0 系列，为 3.0 分配专属的敏捷超时窗口（如 60s），避免因 3.0 卡死占满全部时间导致整体失败
    let requestTimeoutMs = totalTimeoutSec * 1000;
    if (currentModel.includes('3.0') && !downgraded) {
      requestTimeoutMs = Math.max(15000, Math.min(totalTimeoutSec * 1000 * 0.6, 65000));
    }

    try {
      const resp = await sendRequestViaProxy(
        `${DEFAULT_BASE_URL}/chat/completions`,
        {
          model: currentModel,
          messages: [
            { role: 'system', content: SYSTEM_AUDIT_PROMPT },
            { role: 'user', content: promptContent }
          ],
          reasoning_effort: currentEffort,
          temperature: 0.2
        },
        activeApiKey,
        requestTimeoutMs
      );

      if (resp.status === 200) {
        successfulData = JSON.parse(resp.text);
        break;
      }

      lastErrorText = `(HTTP ${resp.status}): ${resp.text}`;

      // 检查是否需要从 3.0 降级到 2.5
      if (!downgraded && shouldDowngradeTo25(currentModel, resp.status)) {
        downgraded = true;
        downgradeReason = `HTTP ${resp.status} 网关响应异常/超时`;
        process.stderr.write(`[subagent${subagentName ? `:${subagentName}` : ''}] ${currentModel} ${downgradeReason}，自动平滑降级为 ${FALLBACK_MODEL} (max 顶级推理) 重试...\n`);
        currentModel = FALLBACK_MODEL;
        currentEffort = 'max';
        activeApiKey = rotateKey();
        continue;
      }

      // 如果遇到限流 429 或认证 401/403，轮换 Key
      if (resp.status === 429 || resp.status === 401 || resp.status === 403) {
        activeApiKey = rotateKey();
        continue;
      } else {
        break;
      }
    } catch (reqErr) {
      lastErrorText = reqErr.message;

      // 检查网络底层超时或连接异常，触发 3.0 -> 2.5 降级
      if (!downgraded && shouldDowngradeTo25(currentModel, reqErr)) {
        downgraded = true;
        downgradeReason = `请求超时或连接中断 (${reqErr.message})`;
        process.stderr.write(`[subagent${subagentName ? `:${subagentName}` : ''}] ${currentModel} ${downgradeReason}，自动平滑降级为 ${FALLBACK_MODEL} (max 顶级推理) 重试...\n`);
        currentModel = FALLBACK_MODEL;
        currentEffort = 'max';
        activeApiKey = rotateKey();
        continue;
      }

      activeApiKey = rotateKey();
    }
  }

  if (!successfulData) {
    return {
      content: [{
        type: "text",
        text: `[子代理 API 响应异常${subagentName ? ` - ${subagentName}` : ''}]: ${lastErrorText}`
      }],
      isError: true
    };
  }

  try {
    const data = successfulData;
    const choice = data.choices?.[0];
    const message = choice?.message || {};
    const content = (message.content || '').trim();
    const reasoning = (message.reasoning_content || '').trim();

    let output = '';
    // 顶部强制打上不可篡改的【不得轻信与免责警示】
    output += `> 🛡️ **【子代理审查免责与不得轻信红线】**：\n`;
    output += `> 1. 本审查由独立静态沙箱通过思维链推演生成。子代理处于**无编译器环境、无运行时单测能力**的推演沙箱，其任何推论仅作为“反向排查盲点”的疑点线索。\n`;
    output += `> 2. **铁律：严禁直接采纳或照抄子代理的代码建议！** 子代理不擅长写落地代码，所有具体防御实现必须由主代理结合本地编译器（tsc/eslint）与真机单元测试（vitest）独立闭环！\n\n`;

    if (downgraded) {
      output += `> ⚠️ **[自动容灾降级提示]**: 首选 3.0 模型响应超时或异常 (${downgradeReason})，已自动无缝降级为 **${currentModel} (最高推理 max)** 顺利完成深度推演。\n\n`;
    }
    if (content) {
      output += `【子代理独立审查结论${subagentName ? ` - ${subagentName}` : ''}】\n${content}\n`;
    }
    if (reasoning) {
      output += (output ? '\n---\n\n' : '') + `【子代理深度思考推理过程 (max 顶级推导)】\n${reasoning}\n`;
    }

    const usage = data.usage || {};
    const reasoningTokens = usage.completion_tokens_details?.reasoning_tokens ?? usage.reasoning_tokens ?? null;
    const metaInfo = `\n---\n【服务端真实接收与执行证据】\n- 请求目标 URL: ${DEFAULT_BASE_URL}/chat/completions\n- 通信链路: ${PROXY_URL ? `代理 (${PROXY_URL})` : 'Direct (国内机房骨干直连)'}\n- 客户端传入: model=${model || DEFAULT_MODEL}, reasoning_effort=${targetEffort}\n- 服务端实际模型: ${data.model || currentModel}\n- 容灾与降级状态: ${downgraded ? `已平滑降级为 ${FALLBACK_MODEL} (max 推理)` : '优先 3.0 成功直出'}\n- 推理 Token (reasoning_tokens): ${reasoningTokens !== null ? reasoningTokens : '内置于 reasoning_content'}\n- 补全 Token 消耗: ${usage.completion_tokens || 0} / 总计: ${usage.total_tokens || 0}`;
    output += metaInfo;

    if (!output) {
      output = '(模型未返回具体文本)';
    }

    return {
      content: [{ type: "text", text: output }],
      isError: false
    };
  } catch (error) {
    return {
      content: [{ type: "text", text: `[子代理解析失败${subagentName ? ` - ${subagentName}` : ''}]: ${error.message}` }],
      isError: true
    };
  }
}

/**
 * 并发派出多个独立子代理的核心调度器
 * 支持并发池限制与多 Key 负载均衡
 */
async function executeSubagentsParallel({
  tasks = [],
  concurrency = 5,
  model = DEFAULT_MODEL,
  reasoning_effort = DEFAULT_REASONING_EFFORT,
  timeout = 120
}) {
  if (!Array.isArray(tasks) || tasks.length === 0) {
    return {
      content: [{
        type: "text",
        text: "[并发子代理协议拦截]: 缺少 tasks 列表！必须传入包含至少一个子代理任务对象的 tasks 数组。"
      }],
      isError: true
    };
  }

  const startTime = Date.now();
  const limit = Math.max(1, Math.min(Number(concurrency) || 5, 10));
  const results = new Array(tasks.length);
  let currentIndex = 0;
  let activeWorkers = 0;

  return new Promise((resolve) => {
    function launchNext() {
      if (currentIndex >= tasks.length) {
        if (activeWorkers === 0) {
          const totalDuration = ((Date.now() - startTime) / 1000).toFixed(1);
          resolve(formatParallelResults(tasks, results, totalDuration));
        }
        return;
      }

      while (activeWorkers < limit && currentIndex < tasks.length) {
        const index = currentIndex++;
        const item = tasks[index];
        activeWorkers++;

        // 为每个并发任务轮流分配不同的 Key，分摊限流压力
        const taskKey = getNextKeyForTask();
        const taskName = item.name || `子代理-${index + 1}`;
        const taskModel = item.model || model || DEFAULT_MODEL;
        const taskEffort = item.reasoning_effort || reasoning_effort || DEFAULT_REASONING_EFFORT;
        const taskTimeout = item.timeout || timeout || 120;

        executeSubagentSingle({
          user_goal: item.user_goal,
          solution_summary: item.solution_summary,
          review_focus: item.review_focus,
          task: item.task,
          files: item.files,
          model: taskModel,
          reasoning_effort: taskEffort,
          timeout: taskTimeout,
          assignedKey: taskKey,
          subagentName: taskName
        }).then((res) => {
          results[index] = { name: taskName, success: !res.isError, data: res, error: null };
        }).catch((err) => {
          results[index] = { name: taskName, success: false, data: null, error: err?.message || String(err) };
        }).finally(() => {
          activeWorkers--;
          launchNext();
        });
      }
    }

    launchNext();
  });
}

/**
 * 格式化输出并发子代理群的汇总报告
 */
function formatParallelResults(tasks, results, totalDuration) {
  const totalCount = results.length;
  const successCount = results.filter(r => r && r.success).length;
  const hasErrors = successCount < totalCount;

  let report = `# 🚀 【并发子代理群】独立审查综合报告\n\n`;
  report += `> 🛡️ **【子代理审查免责与不得轻信红线】**：\n`;
  report += `> 1. 本审查由并发静态沙箱通过思维链推演生成。子代理处于**无编译器环境、无运行时单测能力**的推演沙箱，其任何推论仅作为“反向排查盲点”的疑点线索。\n`;
  report += `> 2. **铁律：严禁直接采纳或照抄子代理的代码建议！** 子代理不擅长写落地代码，所有具体防御实现必须由主代理结合本地编译器（tsc/eslint）与真机单元测试（vitest）独立闭环！\n\n`;
  report += `> 📊 **并发调度总览**：共并发派出 **${totalCount}** 位无状态子代理 | 成功完成 **${successCount}** 个 | 总耗时 **${totalDuration}s**\n`;
  report += `> 🧠 **推理与模型策略**：强制锁定 **max 顶级思维链推理** | 优先 **agnes-3.0-flash**（超时自动无缝降级 **agnes-2.5-flash**）\n\n`;
  report += `---\n\n`;

  results.forEach((item, idx) => {
    const taskName = item?.name || `子代理-${idx + 1}`;
    report += `## 📋 子代理 ${idx + 1}：【${taskName}】\n\n`;
    if (item?.success && item.data?.content?.[0]?.text) {
      report += `${item.data.content[0].text}\n\n`;
    } else {
      report += `❌ **执行异常**: ${item?.error || item?.data?.content?.[0]?.text || '未知错误'}\n\n`;
    }
    report += `---\n\n`;
  });

  return {
    content: [{ type: "text", text: report.trim() }],
    isError: hasErrors && successCount === 0
  };
}

/**
 * 统一分发入口：智能兼容单任务与批量并发任务
 */
async function executeSubagent(args) {
  if (Array.isArray(args.tasks) && args.tasks.length > 0) {
    return await executeSubagentsParallel(args);
  }
  return await executeSubagentSingle(args);
}

// 导出的 MCP 工具列表定义
const tools = [
  {
    name: "invoke_subagent",
    description: "派发任务给独立且完全干净的无状态子代理执行（API 驱动）。专用于【红队破坏性测试、时序竞态、死锁与极端边界推演】。做其擅长的反常识推演，严禁代写落地代码。默认强制锁定 max 顶级思维链推理，优先 3.0 (agnes-3.0-flash)，超时自动无缝降级 2.5 (agnes-2.5-flash)。支持单任务派出或传入 tasks 数组并发派出。结论仅供参考，不可盲信。",
    inputSchema: {
      type: "object",
      properties: {
        user_goal: {
          type: "string",
          description: "【强烈推荐必填】用户原始目标与核心业务痛点背景（明确交代要解决什么实际问题、防御什么场景）"
        },
        solution_summary: {
          type: "string",
          description: "【强烈推荐必填】主代理的修复逻辑与架构改动说明（采用了何种方案、处理了哪些根因）"
        },
        review_focus: {
          type: "string",
          description: "【选填】需要子代理重点突破的边界条件、极端场景、时序并发或疑虑点"
        },
        task: {
          type: "string",
          description: "【自包含综合指令】若未提供 user_goal 和 solution_summary 则必填此项。严禁使用'上一轮'、'如前所述'等伪连续代词，必须提供完整上下文。"
        },
        files: {
          type: "array",
          items: { type: "string" },
          description: "需要子代理重点审查的文件绝对路径列表。工具会自动读取这些文件的最新内容附带行号供审查。"
        },
        tasks: {
          type: "array",
          items: { type: "object" },
          description: "【并发批量模式】若需并发派出多个子代理，可在此传入子代理任务对象列表（每个对象包含 name, user_goal, solution_summary, review_focus, task, files 等），系统将自动并发并行执行并汇总返回。"
        },
        model: {
          type: "string",
          description: "调用的审查模型（默认优先 agnes-3.0-flash，超时自动降级 agnes-2.5-flash，支持 max 顶级思维链推导）",
          default: "agnes-3.0-flash"
        },
        reasoning_effort: {
          type: "string",
          description: "思维链深度推理强度（默认 'max'，可选 'low' | 'medium' | 'high' | 'xhigh' | 'max'）",
          enum: ["low", "medium", "high", "xhigh", "max"],
          default: "max"
        },
        timeout: {
          type: "number",
          description: "请求超时秒数（默认 120 秒）",
          default: 120
        }
      }
    }
  },
  {
    name: "invoke_subagents_parallel",
    description: "并发派发多个独立无状态子代理（API 驱动）并行执行。各子代理使用 max 顶级推理强度，在独立的大模型端点并发执行，互不阻塞。优先 3.0，超时自动无缝降级 2.5，自动汇总各子代理的审查结论与深度思考过程。",
    inputSchema: {
      type: "object",
      properties: {
        tasks: {
          type: "array",
          description: "需要并发派发的子代理任务列表",
          items: {
            type: "object",
            properties: {
              name: {
                type: "string",
                description: "子代理角色或任务名称（例如：'并发与竞态安全审计'、'架构与圈复杂度审查'）"
              },
              user_goal: {
                type: "string",
                description: "该子代理要核验的用户原始业务目标"
              },
              solution_summary: {
                type: "string",
                description: "该子代理要核验的主代理修复方案"
              },
              review_focus: {
                type: "string",
                description: "审查关注重点"
              },
              task: {
                type: "string",
                description: "自包含任务指令（若未提供 user_goal 和 solution_summary 则必填）"
              },
              files: {
                type: "array",
                items: { type: "string" },
                description: "该子代理需审查的文件绝对路径列表"
              },
              timeout: {
                type: "number",
                description: "该子代理专属超时秒数（可选，默认继承全局）"
              }
            }
          }
        },
        concurrency: {
          type: "number",
          description: "最大并发子代理数（默认 5）",
          default: 5
        },
        model: {
          type: "string",
          description: "审查模型（默认优先 agnes-3.0-flash，超时自动降级 agnes-2.5-flash）",
          default: "agnes-3.0-flash"
        },
        reasoning_effort: {
          type: "string",
          description: "思维链深度推理强度（默认 'max'）",
          enum: ["low", "medium", "high", "xhigh", "max"],
          default: "max"
        },
        timeout: {
          type: "number",
          description: "每个子代理的请求超时秒数（默认 120 秒）",
          default: 120
        }
      },
      required: ["tasks"]
    }
  }
];

/**
 * JSON-RPC 原子写回函数，杜绝并发写入时的字符串交错
 */
function sendJsonRpc(data) {
  process.stdout.write(JSON.stringify(data) + '\n');
}

/**
 * 异步非阻塞处理 JSON-RPC 消息
 */
async function handleJsonRpc(msg) {
  if (msg.method === 'initialize') {
    return {
      protocolVersion: "2024-11-05",
      capabilities: { tools: {} },
      serverInfo: { name: "subagent-review-mcp", version: "2.2.0" }
    };
  } else if (msg.method === 'tools/list') {
    return { tools };
  } else if (msg.method === 'tools/call') {
    const toolName = msg.params?.name;
    const args = msg.params?.arguments || {};

    if (toolName === 'invoke_subagent') {
      return await executeSubagent(args);
    } else if (toolName === 'invoke_subagents_parallel' || toolName === 'invoke_batch_subagents' || toolName === 'batch_subagents') {
      return await executeSubagentsParallel(args);
    } else {
      throw { code: -32601, message: `Tool not found: ${toolName}` };
    }
  } else if (msg.method === 'ping') {
    return {};
  }
  throw { code: -32601, message: `Method not supported: ${msg.method}` };
}

process.stdin.setEncoding('utf8');
let buffer = '';

process.stdin.on('data', (chunk) => {
  buffer += chunk.toString();
  const lines = buffer.split('\n');
  buffer = lines.pop(); // 保留不完整末行

  for (const line of lines) {
    if (!line.trim()) continue;
    try {
      const msg = JSON.parse(line);

      // 忽略没有 id 的通知消息
      if (msg.id === undefined || msg.id === null) {
        continue;
      }

      // 关键架构改进：异步即时派发，杜绝 await 阻塞后续请求处理，实现真正并发响应
      (async () => {
        try {
          const result = await handleJsonRpc(msg);
          sendJsonRpc({ jsonrpc: "2.0", id: msg.id, result });
        } catch (err) {
          if (err && err.code) {
            sendJsonRpc({ jsonrpc: "2.0", id: msg.id, error: err });
          } else {
            sendJsonRpc({ jsonrpc: "2.0", id: msg.id, error: { code: -32603, message: err?.message || String(err) } });
          }
        }
      })();
    } catch (e) {
      process.stderr.write('JSON-RPC parse error: ' + e.message + '\n');
    }
  }
});

process.stderr.write('subagent-review-mcp v2.2.0 ready (Max Reasoning, 3.0->2.5 Fallback, Non-blocking Parallel Dispatch Enabled)\n');
