const targets = await (await fetch('http://127.0.0.1:9000/json/list')).json();
const pages = targets.filter(target => target.type === 'page');
const target = pages.find(page => !/Launchpad/i.test(page.title) && /workbench/i.test(page.url)) ?? pages[0];
if (!target) throw new Error('未找到 Antigravity workbench 页面。');

const socket = new WebSocket(target.webSocketDebuggerUrl);
await new Promise((resolve, reject) => {
    socket.addEventListener('open', resolve, { once: true });
    socket.addEventListener('error', reject, { once: true });
});

let sequence = 0;
const pending = new Map();
socket.addEventListener('message', event => {
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

const expression = `(() => {
    const visible = element => {
        const rect = element.getBoundingClientRect();
        const style = getComputedStyle(element);
        return rect.width > 0 && rect.height > 0 && style.visibility !== 'hidden' && style.display !== 'none';
    };
    const editables = [...document.querySelectorAll('textarea,input,[contenteditable="true"]')]
        .filter(visible)
        .map((element, index) => ({
            index,
            tag: element.tagName,
            type: element.type || '',
            aria: element.getAttribute('aria-label') || '',
            placeholder: element.getAttribute('placeholder') || '',
            role: element.getAttribute('role') || '',
            className: String(element.className).slice(0, 180)
        }));
    const buttons = [...document.querySelectorAll('button,[role="button"]')]
        .filter(visible)
        .map((element, index) => ({
            index,
            text: (element.innerText || '').trim().slice(0, 100),
            aria: element.getAttribute('aria-label') || '',
            title: element.getAttribute('title') || '',
            disabled: Boolean(element.disabled),
            className: String(element.className).slice(0, 160)
        }))
        .filter(item => /send|submit|发送|停止|模型|model|agent/i.test(Object.values(item).join(' ')))
        .slice(0, 50);
    return {
        title: document.title,
        readyState: document.readyState,
        editables,
        buttons,
        bodyTail: (document.body.innerText || '').slice(-2200)
    };
})()`;

await cdp('Runtime.enable');
const result = await cdp('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
console.log(JSON.stringify({ target: { id: target.id, title: target.title, url: target.url }, page: result.result.value }, null, 2));
socket.close();
