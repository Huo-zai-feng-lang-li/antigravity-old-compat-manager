/**
 * 只读校验：当前运行态 workbench.desktop.main.js 的注入状态。
 * 不写任何文件，IDE 开着也能跑。
 * - MODELS 为空（CLEAN 模式）：断言 __agUid / __agtarget / __agSelLabel 三项引用均为 0，
 *   即 wb 与官方干净基线等价，下拉仅显示官方原生模型。
 * - MODELS 非空（PATCHED 模式）：每个放行 uid 应恰好出现 3 次
 *   （nKc 下拉 + dutE 可见列表 + vKc store），并核对旁路路由/回显/条件 concat 守卫。
 */
import fs from 'node:fs';
const wb = 'D:\\Antigravity\\resources\\app\\out\\vs\\workbench\\workbench.desktop.main.js';
const s = fs.readFileSync(wb, 'utf8');
const uids = [
  // 与 patch-workbench.mjs 的 MODELS 保持同步（8 项：Claude 5.5 六档 + Gemini 3.8 Medium/Low）
  'claude-opus-5-5-high',
  'claude-opus-5-5-medium',
  'claude-opus-5-5-low',
  'claude-sonnet-5-5-high',
  'claude-sonnet-5-5-medium',
  'claude-sonnet-5-5-low',
  'gemini-3.8-flash-medium',
  'gemini-3.8-flash-low',
];
const totalSynthetic = (s.match(/__agUid:/g) || []).length;
if (uids.length === 0) {
  const agTargetRefs = (s.match(/__agtarget/g) || []).length;
  const agSelLabelRefs = (s.match(/__agSelLabel/g) || []).length;
  console.log('MODE = CLEAN (MODELS 为空，期望 0 个合成 uid)');
  console.log('total __agUid refs =', totalSynthetic);
  console.log('__agtarget route refs =', agTargetRefs);
  console.log('__agSelLabel refs =', agSelLabelRefs);
  // 完整断言：三项都必须为 0，防止"残留旁路路由但无 __agUid"的中间态被误报 CLEAN
  const ok = totalSynthetic === 0 && agTargetRefs === 0 && agSelLabelRefs === 0;
  console.log(ok ? 'CLEAN OK (无合成 uid / 无旁路残留，下拉仅官方原生)' : 'MISMATCH (残留 __agUid=' + totalSynthetic + ' __agtarget=' + agTargetRefs + ' __agSelLabel=' + agSelLabelRefs + '，请重跑 patch 还原)');
  process.exit(ok ? 0 : 1);
}
let allOk = true;
for (const u of uids) {
  let n = 0, i = 0; const k = '__agUid:"' + u + '"';
  while ((i = s.indexOf(k, i)) >= 0) { n++; i += k.length; }
  console.log(u.padEnd(28), n);
  if (n !== 3) allOk = false;
}
const agTargetRefs = (s.match(/__agtarget/g) || []).length;
const agSelLabelRefs = (s.match(/__agSelLabel/g) || []).length;
const guardCount = (s.match(/clientModelConfigs\|\|\[\]\)\.length>0/g) || []).length;
console.log('MODE = PATCHED');
console.log('__agtarget route refs =', agTargetRefs);
console.log('__agSelLabel refs =', agSelLabelRefs);
console.log('conditional concat guard count =', guardCount);
// 断言：旁路路由至少 1、回显至少 1、条件守卫恰为 1、总合成引用 = uids.length * 3
if (agTargetRefs < 1) { console.log('FAIL: __agtarget route missing'); allOk = false; }
if (agSelLabelRefs < 1) { console.log('FAIL: __agSelLabel echo missing'); allOk = false; }
if (guardCount !== 1) { console.log('FAIL: conditional concat guard count = ' + guardCount + ' (expect 1)'); allOk = false; }
if (totalSynthetic !== uids.length * 3) { console.log('FAIL: total __agUid refs = ' + totalSynthetic + ' (expect ' + uids.length * 3 + ')'); allOk = false; }
console.log(allOk ? 'ALL-MODELS OK (each uid x3, routes/echo/guard verified)' : 'MISMATCH');
if (!allOk) process.exit(1);
