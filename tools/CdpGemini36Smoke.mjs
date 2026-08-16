const options = Object.fromEntries(
  process.argv.slice(2).map((argument) => {
    const separator = argument.indexOf("=");
    return separator < 0
      ? [argument.replace(/^--/, ""), true]
      : [argument.slice(2, separator), argument.slice(separator + 1)];
  }),
);

const model = options.model || "Gemini 3.6 Flash (High)";
const prompt = options.prompt || "计算 17+25，只回复数字结果。";
const expected = options.expected || "42";
const timeoutMs = Number(options.timeoutMs || 90000);
const cdpTimeoutMs = Number(options.cdpTimeoutMs || 10000);

const targets = await (await fetch("http://127.0.0.1:9000/json/list")).json();
const pages = targets.filter((target) => target.type === "page");
const target =
  pages.find(
    (page) => !/Launchpad/i.test(page.title) && /workbench\.html/.test(page.url),
  ) || pages[0];
if (!target) throw new Error("未找到 Antigravity workbench 页面。");

const socket = new WebSocket(target.webSocketDebuggerUrl);
await new Promise((resolve, reject) => {
  socket.addEventListener("open", resolve, { once: true });
  socket.addEventListener("error", reject, { once: true });
});

let sequence = 0;
const pending = new Map();
function failPending(error) {
  for (const request of pending.values()) {
    clearTimeout(request.timer);
    request.reject(error);
  }
  pending.clear();
}

socket.addEventListener("message", (event) => {
  const message = JSON.parse(String(event.data));
  const request = pending.get(message.id);
  if (!request) return;
  pending.delete(message.id);
  clearTimeout(request.timer);
  if (message.error) request.reject(new Error(JSON.stringify(message.error)));
  else request.resolve(message.result);
});
socket.addEventListener("close", () => failPending(new Error("CDP 连接已关闭。")));
socket.addEventListener("error", () => failPending(new Error("CDP 连接发生错误。")));

function cdp(method, params = {}) {
  return new Promise((resolve, reject) => {
    if (socket.readyState !== WebSocket.OPEN) {
      reject(new Error("CDP 连接未就绪。"));
      return;
    }
    const id = ++sequence;
    const timer = setTimeout(() => {
      pending.delete(id);
      reject(new Error(`CDP 请求超时：${method}`));
    }, cdpTimeoutMs);
    pending.set(id, { resolve, reject, timer });
    socket.send(JSON.stringify({ id, method, params }));
  });
}

async function evaluate(expression) {
  const result = await cdp("Runtime.evaluate", {
    expression,
    returnByValue: true,
    awaitPromise: true,
  });
  if (result.exceptionDetails) {
    throw new Error(result.exceptionDetails.exception?.description || "页面执行失败。");
  }
  return result.result.value;
}

async function chooseModel(label) {
  const value = JSON.stringify(label);
  const current = await evaluate(`(() => {
    const visible = element => {
      const rect = element.getBoundingClientRect();
      const style = getComputedStyle(element);
      return rect.width > 0 && rect.height > 0 && style.display !== "none" && style.visibility !== "hidden";
    };
    const buttons = [...document.querySelectorAll("button,[role=button]")].filter(visible);
    return (buttons.find(element => /^(Gemini|Claude)/.test((element.innerText || "").trim()))?.innerText || "").trim();
  })()`);
  if (current === label) return;
  let clicked = await evaluate(`(() => {
    const matches = [...document.querySelectorAll("*")].filter(element => (element.innerText || "").trim() === ${value});
    const option = matches.map(element => element.closest(".cursor-pointer")).find(element => element && element.tagName !== "BUTTON");
    if (!option) return false;
    option.click();
    return true;
  })()`);
  if (!clicked) {
    const opened = await evaluate(`(() => {
      const visible = element => element.getBoundingClientRect().width > 0 && element.getBoundingClientRect().height > 0;
      const current = [...document.querySelectorAll("button,[role=button]")]
        .filter(visible)
        .find(element => /^(Gemini|Claude)/.test((element.innerText || "").trim()));
      if (!current) return false;
      current.click();
      return true;
    })()`);
    if (!opened) throw new Error("当前模型按钮不可点击。");
    await new Promise((resolve) => setTimeout(resolve, 350));
    clicked = await evaluate(`(() => {
      const matches = [...document.querySelectorAll("*")].filter(element => (element.innerText || "").trim() === ${value});
      const target = matches.find(element => element.closest(".cursor-pointer,button,[role=button]"));
      const option = target?.closest(".cursor-pointer,button,[role=button]");
      if (!option) return false;
      option.click();
      return true;
    })()`);
    if (!clicked) throw new Error(`模型选项不可点击：${label}`);
  }
  await new Promise((resolve) => setTimeout(resolve, 350));
  const selected = await evaluate(`(() => {
    const visible = element => element.getBoundingClientRect().width > 0 && element.getBoundingClientRect().height > 0;
    return [...document.querySelectorAll("button,[role=button]")]
      .filter(visible)
      .map(element => (element.innerText || "").trim())
      .find(text => /^(Gemini|Claude)/.test(text)) || "";
  })()`);
  if (selected !== label) throw new Error(`模型选择未生效：${selected}`);
}

async function typePrompt(text) {
  const focused = await evaluate(`(() => {
    const visible = element => element.getBoundingClientRect().width > 0 && element.getBoundingClientRect().height > 0;
    const editor = [...document.querySelectorAll('[contenteditable="true"],[role="textbox"]')].find(visible);
    if (!editor) return false;
    editor.focus();
    editor.replaceChildren();
    editor.dispatchEvent(new InputEvent("input", { bubbles: true, inputType: "deleteContentBackward" }));
    return true;
  })()`);
  if (!focused) throw new Error("未找到聊天输入框。");
  await cdp("Input.insertText", { text });
  await new Promise((resolve) => setTimeout(resolve, 250));
}

async function clickSend() {
  const clicked = await evaluate(`(() => {
    const visible = element => element.getBoundingClientRect().width > 0 && element.getBoundingClientRect().height > 0;
    const send = [...document.querySelectorAll("button,[role=button]")]
      .filter(visible)
      .find(element => (element.innerText || "").trim() === "Send");
    if (!send || send.disabled) return false;
    send.click();
    return true;
  })()`);
  if (!clicked) throw new Error("发送按钮未启用。");
}

function countOccurrences(text, value) {
  if (!value) return 0;
  return text.split(value).length - 1;
}

async function waitForReply(value, baselineCount) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const state = await evaluate(`(() => ({
      text: document.body.innerText || "",
      sendDisabled: [...document.querySelectorAll("button,[role=button]")]
        .find(element => (element.innerText || "").trim() === "Send")?.disabled ?? true
    }))()`);
    const occurrences = countOccurrences(state.text, value);
    if (occurrences > baselineCount && state.sendDisabled) return state.text.slice(-2500);
    await new Promise((resolve) => setTimeout(resolve, 500));
  }
  throw new Error(`等待回复超时：${value}`);
}

try {
  await cdp("Runtime.enable");
  await chooseModel(model);
  await typePrompt(prompt);
  const baselineText = await evaluate(`document.body.innerText || ""`);
  const baselineCount = countOccurrences(baselineText, expected);
  await clickSend();
  const startedAt = Date.now();
  const bodyTail = await waitForReply(expected, baselineCount);
  console.log(
    JSON.stringify(
      {
        ok: true,
        model,
        expected,
        elapsedMs: Date.now() - startedAt,
        bodyTail,
      },
      null,
      2,
    ),
  );
} finally {
  socket.close();
}
