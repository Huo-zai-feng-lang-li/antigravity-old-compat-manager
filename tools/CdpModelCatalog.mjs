const endpoint = process.argv[2] || "http://127.0.0.1:9000/json/list";
const targets = await (await fetch(endpoint)).json();
const pages = targets.filter((target) => target.type === "page");
const target = pages.find((page) => !/Launchpad/i.test(page.title) && /workbench/i.test(page.url)) || pages[0];
if (!target) throw new Error("未找到 Antigravity workbench 页面。");

const socket = new WebSocket(target.webSocketDebuggerUrl);
await new Promise((resolve, reject) => {
  socket.addEventListener("open", resolve, { once: true });
  socket.addEventListener("error", reject, { once: true });
});

let sequence = 0;
const pending = new Map();
socket.addEventListener("message", (event) => {
  const message = JSON.parse(String(event.data));
  const request = pending.get(message.id);
  if (!request) return;
  pending.delete(message.id);
  if (message.error) request.reject(new Error(JSON.stringify(message.error)));
  else request.resolve(message.result);
});

function cdp(method, params = {}) {
  return new Promise((resolve, reject) => {
    const id = ++sequence;
    pending.set(id, { resolve, reject });
    socket.send(JSON.stringify({ id, method, params }));
  });
}

async function evaluate(expression) {
  const result = await cdp("Runtime.evaluate", { expression, returnByValue: true, awaitPromise: true });
  if (result.exceptionDetails) throw new Error(result.exceptionDetails.exception?.description || "页面执行失败。");
  return result.result.value;
}

const knownAllowed = [
  "Claude Sonnet 4.6 (Thinking)",
  "Claude Opus 4.6 (Thinking)",
  "Claude Sonnet 4.6 (thinking)",
  "Claude Opus 4.6 (thinking)",
  "Gemini 3.7 Flash",
  "Gemini 3.7 Flash (High)",
  "Gemini 3.7 Flash (Medium)",
  "Gemini 3.6 Flash (High)",
  "Gemini 3.6 Flash (Medium)",
];
const modelPattern = /^(?:Claude .+ \((?:thinking)\)|Gemini .+ \((?:High|Medium|Low)\))$/i;

try {
  await cdp("Runtime.enable");
  const labels = JSON.stringify(knownAllowed);
  const opened = await evaluate(`(() => {
    const labels = new Set(${labels});
    const visible = element => {
      const rect = element.getBoundingClientRect();
      const style = getComputedStyle(element);
      return rect.width > 0 && rect.height > 0 && style.display !== "none" && style.visibility !== "hidden";
    };
    const leaf = [...document.querySelectorAll("*")]
      .filter(element => visible(element) && labels.has((element.innerText || "").trim()))
      .sort((left, right) => left.children.length - right.children.length)[0];
    const trigger = leaf?.closest("button,[role=button],.cursor-pointer") || leaf;
    if (!trigger) return false;
    trigger.click();
    return true;
  })()`);
  if (!opened) throw new Error("未找到当前模型选择器。");
  await new Promise((resolve) => setTimeout(resolve, 500));

  const present = await evaluate(`(() => {
    const visible = element => {
      const rect = element.getBoundingClientRect();
      const style = getComputedStyle(element);
      return rect.width > 0 && rect.height > 0 && style.display !== "none" && style.visibility !== "hidden";
    };
    const labels = [...new Set([...document.querySelectorAll("*")]
      .filter(element => visible(element) && ${modelPattern}.test((element.innerText || "").trim()))
      .map(element => (element.innerText || "").trim()))];
    return labels;
  })()`);
  const low = present.filter((label) => /\(Low\)$/.test(label));
  const nonLow = present.filter((label) => !low.includes(label));
  const known = nonLow.filter((label) => knownAllowed.includes(label));
  const newNonLow = nonLow.filter((label) => !knownAllowed.includes(label));
  const hasClaude = present.some((label) => /^Claude /.test(label));
  const hasGemini37 = present.some((label) => /^Gemini 3\.7(?: |$)/.test(label));
  const hasGemini36 = present.some((label) => /^Gemini 3\.6(?: |$)/.test(label));
  const result = { ok: low.length === 0 && hasClaude && hasGemini37 && hasGemini36, present, known, newNonLow, low, hasClaude, hasGemini37, hasGemini36 };
  console.log(JSON.stringify(result, null, 2));
  if (!result.ok) process.exitCode = 1;
} finally {
  socket.close();
}
