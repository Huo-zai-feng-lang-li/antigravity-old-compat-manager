#!/usr/bin/env node
/**
 * antigravity-subagent-mcp.js
 * 反重力 IDE 独立 API 驱动代码审查与子代理引擎（stdio MCP 模式）
 *
 * 架构特性：
 * 1. 原生 API 直连（无外部 CLI 依赖，彻底消除跨平台进程泄露与命令行转义缺陷）
 * 2. 具备深度推理 (Reasoning) 与严格代码审查模式
 * 3. 自动文件读取与上下文装配（支持传入文件列表直接审查磁盘真实代码，自动附带行号）
 * 4. 健壮的 AbortController 超时中断机制
 */

const fs = require('fs');
const path = require('path');

const DEFAULT_BASE_URL = process.env.SUBAGENT_BASE_URL || 'https://apihub.agnes-ai.com/v1';
const DEFAULT_API_KEY = process.env.SUBAGENT_API_KEY || '';
const DEFAULT_MODEL = process.env.SUBAGENT_MODEL || 'agnes-2.5-pro-beta';

// 审查专家的系统 Prompt
const SYSTEM_AUDIT_PROMPT = `你是一个资深架构师兼严苛的安全与代码审计专家（Independent Review Subagent）。
你的职责是在独立且完全干净的上下文中，对主代理提交的代码、架构设计或修复方案进行客观、中立、不留情面的全方位技术审查。

审查维度包括且不限于：
1. 【业务与逻辑闭环】：是否存在逻辑漏洞、空指针/未定义解构异常、异步时序竞态、边界值遗漏？
2. 【并发与资源安全】：是否有内存泄露、事件未注销、定时器未清理、文件句柄未释放？
3. 【代码质量与架构】：函数圈复杂度是否过高、职责是否单一、有无过度设计或反模式？
4. 【安全与合规】：是否存在命令注入、XSS、未授权敏感信息泄露等漏洞？

输出规范：
- 如果没有发现问题，明确说明【审计通过】，并给出 1-2 句核心依据。
- 如果发现问题，必须以清晰的结构列出：
  - 【严重级别】：[严重 Critical / 高危 High / 中危 Medium / 建议 Low]
  - 【位置定位】：指出具体文件与关键代码行
  - 【根因分析】：为什么这是个问题，在什么极端场景下会爆发？
  - 【修复建议】：直接提供修正后的参考代码块（Drop-in replacement）
- 保持客观犀利，直指核心，拒绝一切虚浮的客套话。`;

const tools = [{
  name: "invoke_subagent",
  description: "派发任务给独立且完全干净的子代理执行（API 驱动）。专用于代码审查（Code Review）、安全审计、逻辑核验或复杂方案推演。可自动读取关联文件。",
  inputSchema: {
    type: "object",
    properties: {
      task: {
        type: "string",
        description: "具体的审查指令或任务要求（例如：'审查刚刚修改的登录权限验证逻辑'）"
      },
      files: {
        type: "array",
        items: { type: "string" },
        description: "需要子代理重点审查的文件绝对路径列表。工具会自动读取这些文件的最新内容附带行号供审查。"
      },
      model: {
        type: "string",
        description: "调用的审查模型（默认 agnes-2.5-pro-beta，支持深度思维链推导）",
        default: "agnes-2.5-pro-beta"
      },
      timeout: {
        type: "number",
        description: "请求超时秒数（默认 120 秒）",
        default: 120
      }
    },
    required: ["task"]
  }
}];

/**
 * 派发 API 执行子代理
 */
async function executeSubagent({ task, files = [], model = DEFAULT_MODEL, timeout = 120 }) {
  // 1. 组装文件上下文
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
    ? `${task}\n\n以下是待审查的相关文件源码：${fileContext}`
    : task;

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), Math.max(5, timeout) * 1000);

  try {
    const response = await fetch(`${DEFAULT_BASE_URL}/chat/completions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${DEFAULT_API_KEY}`
      },
      body: JSON.stringify({
        model: model || DEFAULT_MODEL,
        messages: [
          { role: 'system', content: SYSTEM_AUDIT_PROMPT },
          { role: 'user', content: promptContent }
        ],
        temperature: 0.2
      }),
      signal: controller.signal
    });

    clearTimeout(timer);

    if (!response.ok) {
      const errText = await response.text();
      return {
        content: [{
          type: "text",
          text: `[子代理 API 响应异常 (HTTP ${response.status})]:\n${errText}`
        }],
        isError: true
      };
    }

    const data = await response.json();
    const choice = data.choices?.[0];
    const message = choice?.message || {};
    const content = (message.content || '').trim();
    const reasoning = (message.reasoning_content || '').trim();

    let output = '';
    if (content) {
      output += `【子代理独立审查结论】\n${content}\n`;
    }
    if (reasoning) {
      output += (output ? '\n---\n\n' : '') + `【子代理深度思考推理过程】\n${reasoning}`;
    }
    if (!output) {
      output = '(模型未返回具体文本)';
    }

    return {
      content: [{ type: "text", text: output }],
      isError: false
    };
  } catch (error) {
    clearTimeout(timer);
    if (error.name === 'AbortError') {
      return {
        content: [{ type: "text", text: `[子代理审查超时]: 超过设定的 ${timeout} 秒上限。` }],
        isError: true
      };
    }
    return {
      content: [{ type: "text", text: `[子代理调用失败]: ${error.message}` }],
      isError: true
    };
  }
}

process.stdin.setEncoding('utf8');
let buffer = '';

process.stdin.on('data', async (chunk) => {
  buffer += chunk.toString();
  const lines = buffer.split('\n');
  buffer = lines.pop(); // 保留不完整末行

  for (const line of lines) {
    if (!line.trim()) continue;
    try {
      const msg = JSON.parse(line);

      // JSON-RPC Notification
      if (msg.id === undefined || msg.id === null) {
        continue;
      }

      let result = {};

      if (msg.method === 'initialize') {
        result = {
          protocolVersion: "2024-11-05",
          capabilities: { tools: {} },
          serverInfo: { name: "subagent-review-mcp", version: "2.0.0" }
        };
      } else if (msg.method === 'tools/list') {
        result = { tools };
      } else if (msg.method === 'tools/call') {
        if (msg.params.name === 'invoke_subagent') {
          const args = msg.params.arguments || {};
          result = await executeSubagent({
            task: args.task,
            files: args.files,
            model: args.model,
            timeout: args.timeout
          });
        } else {
          process.stdout.write(JSON.stringify({
            jsonrpc: "2.0",
            id: msg.id,
            error: { code: -32601, message: "Tool not found" }
          }) + '\n');
          continue;
        }
      } else if (msg.method === 'ping') {
        result = {};
      }

      process.stdout.write(JSON.stringify({ jsonrpc: "2.0", id: msg.id, result }) + '\n');
    } catch (e) {
      process.stderr.write('JSON-RPC Error: ' + e.message + '\n');
    }
  }
});

process.stderr.write('subagent-review-mcp v2.0.0 ready (API-Driven Code Review Subagent)\n');
