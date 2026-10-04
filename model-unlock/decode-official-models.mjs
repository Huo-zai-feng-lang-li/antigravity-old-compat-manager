// 取证：从 zk-agent 代理诊断日志中解码官方 fetchAvailableModels / loadCodeAssist 响应
// 用法: node decode-official-models.mjs <_ea_diag.log 路径>
import fs from 'node:fs';
import zlib from 'node:zlib';

const logPath = process.argv[2];
const raw = fs.readFileSync(logPath, 'utf8');
const lines = raw.split('\n');

// 按时间顺序收集每条 OFFICIAL-BODY-HEX，关联其前面最近的 REQ 行 url
const entries = [];
let pendingUrl = new Map(); // rid -> url
for (const line of lines) {
  const ts = line.match(/^\[(.*?)\]/)?.[1];
  const req = line.match(/^.*?#(\d+) OFFICIAL-REQ: (.*)$/);
  if (req) {
    try { pendingUrl.set(req[1], JSON.parse(req[2]).url); } catch {}
    continue;
  }
  const body = line.match(/^.*?#(\d+) OFFICIAL-BODY-HEX: ([0-9a-fA-F]+)\s*$/);
  if (body) {
    const rid = body[1];
    const url = pendingUrl.get(rid) ?? '';
    entries.push({ ts, rid, url, hex: body[2] });
  }
}

console.log(`共找到 ${entries.length} 条响应体转储`);

const gunzip = (hex) => {
  const buf = Buffer.from(hex, 'hex');
  if (buf[0] !== 0x1f || buf[1] !== 0x8b) return null;
  return zlib.gunzipSync(buf).toString('utf8');
};

const targets = entries.filter(e =>
  e.url.includes('fetchAvailableModels') || e.url.includes('loadCodeAssist'));

console.log(`其中模型目录相关 ${targets.length} 条\n`);

for (const [idx, e] of targets.entries()) {
  console.log(`\n========== [#${e.rid}] ${e.url} @ ${e.ts} ==========`);
  try {
    const text = gunzip(e.hex);
    if (!text) { console.log('(非 gzip 体，跳过)'); continue; }
    const json = JSON.parse(text);
    // 通用提取：递归找所有含 label 的对象
    const labels = [];
    const walk = (v) => {
      if (Array.isArray(v)) return v.forEach(walk);
      if (v && typeof v === 'object') {
        if (typeof v.label === 'string') {
          labels.push({ label: v.label, modelId: v.modelId ?? v.id ?? '', keys: Object.keys(v).join(',') });
        }
        Object.values(v).forEach(walk);
      }
    };
    walk(json);
    if (labels.length) {
      console.log(`模型/标签项 ${labels.length} 个:`);
      for (const l of labels) console.log(`  - ${l.label}  | id=${l.modelId} | keys=${l.keys}`);
    } else {
      console.log('未找到 label 字段，原始 JSON（前 4000 字符）:');
      console.log(JSON.stringify(json, null, 2).slice(0, 4000));
    }
  } catch (err) {
    console.log('解码失败:', err.message);
  }
}
