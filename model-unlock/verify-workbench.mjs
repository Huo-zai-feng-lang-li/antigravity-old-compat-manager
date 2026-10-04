/**
 * 只读校验：当前运行态 workbench.desktop.main.js 是否完整包含六档注入。
 * 不写任何文件，IDE 开着也能跑。每个放行 uid 应恰好出现 3 次
 * （nKc 下拉 + dutE 可见列表 + vKc store），并核对旁路路由/回显/条件 concat 守卫。
 */
import fs from 'node:fs';
const wb = 'D:\\Antigravity\\resources\\app\\out\\vs\\workbench\\workbench.desktop.main.js';
const s = fs.readFileSync(wb, 'utf8');
const uids = ['claude-opus-5-5-high', 'claude-opus-5-5-medium', 'claude-opus-5-5-low',
              'claude-sonnet-5-5-high', 'claude-sonnet-5-5-medium', 'claude-sonnet-5-5-low'];
let allOk = true;
for (const u of uids) {
  let n = 0, i = 0; const k = '__agUid:"' + u + '"';
  while ((i = s.indexOf(k, i)) >= 0) { n++; i += k.length; }
  console.log(u.padEnd(28), n);
  if (n !== 3) allOk = false;
}
console.log('__agtarget route refs =', (s.match(/__agtarget/g) || []).length);
console.log('__agSelLabel refs =', (s.match(/__agSelLabel/g) || []).length);
console.log('conditional concat (clientModelConfigs||[]).length =', (s.match(/clientModelConfigs\|\|\[\]\)\.length>0/g) || []).length);
console.log(allOk ? 'SIX-TIERS OK (each uid x3)' : 'MISMATCH');
