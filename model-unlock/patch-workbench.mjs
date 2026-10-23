/**
 * Antigravity 旧版 workbench 新模型放行补丁（正式工具，随仓库入库）。
 *
 * 作用：在渲染进程 workbench.desktop.main.js 的模型下拉/可见列表/store/回显/选择回调
 *       5 个锚点注入放行模型。当前 MODELS 为空（2026-10-18：清空全部合成项，见下方注释），
 *       空表时直接把 wb 还原为干净基线，下拉与官方原生一致。幂等：每次都从干净 Gemini37
 *       基线 assets/prod-wb-pre-claude.js 还原后再注入；注入后 node --check 校验，
 *       失败自动回滚到干净基线，绝不留半成品导致 IDE 卡死。
 *
 * 用法：先彻底关闭 Antigravity（ag=0、ls=0），再 `node model-unlock/patch-workbench.mjs`，
 *       或直接运行仓库根目录的 `放行Claude六档.ps1 -ForceKill`（会先关进程再调本脚本）。
 *
 * 以后放行新模型：只改下方 MODELS 映射表（label / uid），uid 必须与官方
 *       fetchAvailableModels.json（官方 fetchAvailableModels 快照）完全一致；详见 SOP-新模型放行.md。
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
// IDE 安装目录固定（锁死 1.20.6，装在 D:\Antigravity）。若改安装盘符，只改这里。
const wbPath = 'D:\\Antigravity\\resources\\app\\out\\vs\\workbench\\workbench.desktop.main.js';
const prePath = path.join(__dirname, 'assets', 'prod-wb-pre-claude.js');

// ===== 唯一映射表：以后放行新模型只改这里（label 显示名 / uid 官方模型 id）=====
// uid 必须与官方 fetchAvailableModels / streamGenerateContent 接受的 model 字符串完全一致。
// 所有合成项共用 modelAlias:8(RECOMMENDED) 外壳过 LS，真实 uid 经选择旁路上报 zk 改道。
const MODELS = [
  // 2026-10-18 全部清空（当前账号 free-tier 无权限 + gemini-4-argon 为臆造 uid）：
  //   - gemini-4-argon*  ：官方 fetchAvailableModels 里不存在，后端必 404（臆造命名）
  //   - claude-{opus,sonnet}-5-5-* ：官方元信息写明 "available on paid Pro and Ultra plans"，
  //     当前账号 currentTier=free-tier 无权限；免费档目录里 Claude 仅 claude-opus-4-6-thinking
  //     / claude-sonnet-4-6（官方原生即可用，无需 patch 注入）
  //
  // 以后放行新模型的正确流程（见 SOP-新模型放行.md）：
  //   1) node model-unlock/capture-official-catalog.mjs check / install → 关 IDE → 开 IDE
  //   2) 从 _agcap\_ag-models-catalog.json 取官方真实 uid（**必须**能在目录里搜到）
  //   3) 在下方加行 { label: '官方显示名', uid: '目录里的真实 uid' }
  //   4) 重跑本脚本（关 IDE）→ GUI 发消息验证 modelVersion
  //
  //   { label: 'Gemini X.Y Flash (High)', uid: 'gemini-x.y-flash-high' },
  //
  // 2026-10-23：账号官方目录（fetchAvailableModels 实时抓取，103433B / 26 models）已下发 Claude 5.5 六档，
  //   放行以下六项。Gemini 4 Argon / gemini-4 / gemini5 / gemini-3.9 在官方目录中均为 0 命中，不存在，不放。
  { label: 'Claude Opus 5.5 (High)',   uid: 'claude-opus-5-5-high' },
  { label: 'Claude Opus 5.5 (Medium)', uid: 'claude-opus-5-5-medium' },
  { label: 'Claude Opus 5.5 (Low)',    uid: 'claude-opus-5-5-low' },
  { label: 'Claude Sonnet 5.5 (High)',   uid: 'claude-sonnet-5-5-high' },
  { label: 'Claude Sonnet 5.5 (Medium)', uid: 'claude-sonnet-5-5-medium' },
  { label: 'Claude Sonnet 5.5 (Low)',    uid: 'claude-sonnet-5-5-low' },
  //
  // 2026-10-23：放出 Gemini 3.8 Medium / Low 两档（官方原生下拉只给了 High）。
  //   thinkingBudget 由后端 _agApplyThinkingBudget 按 uid 动态设置：
  //   high=-1 / medium=4000 / low=1000，不再无条件抹平为 -1。
  { label: 'Gemini 3.8 Flash (Medium)', uid: 'gemini-3.8-flash-medium' },
  { label: 'Gemini 3.8 Flash (Low)',    uid: 'gemini-3.8-flash-low' },
];
if (MODELS.length === 0) {
  fs.copyFileSync(prePath, wbPath);
  console.log('MODELS 为空 → 已还原干净基线（无合成项，下拉仅显示官方原生模型）');
  console.log('wb size =', fs.statSync(wbPath).size);
  process.exit(0);
}

const optLit = m => '{label:' + JSON.stringify(m.label) +
  ',value:0,modelAlias:8,__agUid:' + JSON.stringify(m.uid) +
  ',disabled:!1,supportsImages:!0,supportedMimeTypes:new Map(),betaWarningMessage:"",isBeta:!1,pricingType:0,description:"",quotaInfo:{remainingFraction:1,resetTime:{seconds:"0",nanos:0}},tagTitle:"New",tagDescription:""}';
const ARR = '[' + MODELS.map(optLit).join(',') + ']';

fs.copyFileSync(prePath, wbPath);
let s = fs.readFileSync(wbPath, 'utf8');

const patches = [
  // 下拉分组(nKc)：无条件追加（仅影响下拉显示，不参与启动默认选择）
  { name: 'nKc recommended',
    old: 'return i?(i.groups[0].options||[]).filter(n=>!e.some(s=>s.label===n.label)):[]',
    neu: 'return (i?(i.groups[0].options||[]).filter(n=>!e.some(s=>s.label===n.label)):[]).concat(' + ARR + ')' },
  // visibleModelConfigs(dut E)：仅当官方配置已加载才追加，避免启动早期 E 仅含合成项被当默认选中
  { name: 'dut E modelOptions',
    old: '.filter(F=>!F.disabled),[o?.cascadeModelConfigData])',
    neu: '.filter(F=>!F.disabled).concat(((o?.cascadeModelConfigData?.clientModelConfigs||[]).length>0)?' + ARR + ':[]),[o?.cascadeModelConfigData])' },
  // Xlt store modelOptions(vKc)：同理，官方非空才追加
  { name: 'vKc modelOptions',
    old: 'modelSorts:o,modelOptions:a,',
    neu: 'modelSorts:o,modelOptions:a.concat(a.length?' + ARR + ':[]),' },
  // 回显匹配：alias:8 被 3.8 与所有 Claude 档共用，优先按最近一次选择的 label 精确匹配
  { name: 'Kun echo match',
    old: 'function Kun(t,e){return e.find(i=>{let n=t?.choice;return n?.case==="model"&&i.value===n?.value||n?.case==="alias"&&i.modelAlias===n?.value})}',
    neu: 'function Kun(t,e){let m=i=>{let n=t?.choice;return n?.case==="model"&&i.value===n?.value||n?.case==="alias"&&i.modelAlias===n?.value};let g=globalThis.__agSelLabel;return(g&&e.find(i=>i.label===g&&m(i)))||e.find(m)}' },
  // 选择即旁路上报：合成项带 __agUid，官方项无 __agUid 回退 3.8 默认
  { name: 'I select report',
    old: 'let I=Zt((F,D=!0)=>{r("selected_model_changed",ah({name:F.label},"model label from server-controlled set"));let N=',
    neu: 'let I=Zt((F,D=!0)=>{r("selected_model_changed",ah({name:F.label},"model label from server-controlled set"));try{globalThis.__agSelLabel=F.label;fetch("http://127.0.0.1:8937/__agtarget?uid="+encodeURIComponent((F&&F.__agUid)||"gemini-3.8-flash-high")+"&label="+encodeURIComponent((F&&F.label)||"")).catch(()=>{});}catch{}let N=' },
];

let ok = true;
for (const p of patches) {
  let n = 0, i = 0; while ((i = s.indexOf(p.old, i)) >= 0) { n++; i += p.old.length; }
  console.log(p.name.padEnd(20), 'anchor count =', n);
  if (n !== 1) ok = false;
}
if (!ok) { console.log('ANCHOR CHECK FAILED — 不写入'); process.exit(1); }
for (const p of patches) { s = s.split(p.old).join(p.neu); console.log('applied', p.name); }
fs.writeFileSync(wbPath, s, 'utf8');
console.log('new wb size =', s.length);

// 同步 product.json 的 workbench checksum，否则 IDE 启动校验会失败；
// 同时让 StableBootstrap 的 Test-BootstrapProductState 一致，避免触发重打补丁覆盖注入。
// wbPath: <root>\resources\app\out\vs\workbench\workbench.desktop.main.js
// product.json: <root>\resources\app\product.json → 从 wb 目录往上 3 级
const productPath = path.join(path.dirname(wbPath), '..', '..', '..', 'product.json');
try {
  const { createHash } = await import('node:crypto');
  const h = createHash('sha256').update(Buffer.from(s, 'utf8')).digest();
  const b64 = h.toString('base64').replace(/=+$/, '');
  const product = JSON.parse(fs.readFileSync(productPath, 'utf8'));
  if (!product.checksums) product.checksums = {};
  product.checksums['vs/workbench/workbench.desktop.main.js'] = b64;
  fs.writeFileSync(productPath, JSON.stringify(product, null, 2), 'utf8');
  console.log('product.json checksum synced =', b64);
} catch (e) {
  console.log('WARN: product.json 同步失败（不影响 workbench 注入）:', e.message);
}

const tmp = path.join(__dirname, 'wb-syntax-check.mjs');
fs.writeFileSync(tmp, s, 'utf8');
let syntaxOk = true;
try { execFileSync('node', ['--check', tmp], { stdio: 'pipe' }); console.log('SYNTAX OK'); }
catch (e) { syntaxOk = false; console.log('SYNTAX FAIL:\n' + (e.stderr ? e.stderr.toString().slice(0, 1500) : e.message)); }
finally { try { fs.rmSync(tmp, { force: true }); } catch {} }
if (!syntaxOk) {
  // 注入后语法校验失败：回滚 workbench 到干净 Gemini37 基线，绝不留半成品导致 IDE 卡死
  try { fs.copyFileSync(prePath, wbPath); console.log('已回滚 workbench 到干净基线 assets/prod-wb-pre-claude.js'); }
  catch (rb) { console.log('回滚失败，请手动还原 assets/prod-wb-pre-claude.js：' + rb.message); }
  process.exit(2);
}
