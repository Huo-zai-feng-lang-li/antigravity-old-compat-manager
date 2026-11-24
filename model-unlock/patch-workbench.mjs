/**
 * Antigravity 旧版 workbench 新模型放行补丁（正式工具，随仓库入库）。
 *
 * 作用：在渲染进程 workbench.desktop.main.js 的模型下拉/可见列表/store/回显/选择回调
 *       5 个锚点注入放行模型（2026-11-24：4 项 = Gemini 4 Hydrogen / 3.8 Tiered / Claude 4.6 两档）。
 *       空表时直接把 wb 还原为干净基线，下拉与官方原生一致。幂等：每次都从干净 Gemini37
 *       基线 assets/prod-wb-pre-claude.js 还原后再注入；注入后先在内存校验语法，
 *       通过才落盘并同步 product.json checksum，失败则任何文件都不写，绝不留半成品。
 *       同名去重：官方 Recommended 组若已含同名项（含 disabled），先按 label 剔除再追加合成项，
 *       避免同一模型在下拉出现两项（2026-11-13 修复，见 verify-workbench 的 agDedup 计数）。
 *       僵尸屏蔽：旧客户端硬编码、服务端已下线的项（3.8 三档等）按 label 剔除，
 *       名单由 probe-models.py 实测产出的 model-health.json 驱动（见 agBlock 计数）。
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
  // 【历史，已被 2026-10-23 更新取代】2026-10-18 曾全部清空（当时账号 free-tier 无权限
  //   + gemini-4-argon 为臆造 uid）：
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
  // 2026-10-23：账号官方目录（fetchAvailableModels 实时抓取，103433B / 26 models）已下发 Claude 5.5 六档。
  // 2026-11-24 大改：服务端按 tier 收窄了可用集，下列 uid 经直连网关实测（真实 UA + 有效 OAuth）：
  //   ✅ 200：gemini-4-hydrogen-sonar / gemini-3.8-flash-tiered / claude-sonnet-4-6 / claude-opus-4-6-thinking
  //   ❌ 404：gemini-3.8-flash-{high,medium,low}（三档已下线，仅 tiered 存活）、claude-{opus,sonnet}-5-5-*
  //          （需 paid AI Pro，本账号 currentTier=standard-tier）、gemini-4-{neon,carbon,argon}、
  //          gemini-4-hydrogen-{high,medium,low}、orchestrator-*
  // Gemini 4 Hydrogen 是 standard-tier 唯一开放档（官方文档：Hydrogen 全档位可用，Neon/Carbon/Argon 需 paid Pro）。
  // 3.8 全系与 Claude 4.6 于 2026-11-30 下线（官方 Leaving Soon），届时需再次换表。
  // Claude 5.5 六档待验证（直连 404，但旧客户端头可能走兼容路由），验证通过再补回。
  // 2026-11-24 第四轮：Gemini 4 不返回明文 thought（只有 thoughtSignature），
  // 思考期客户端零输出，budget 越大越像"卡住"（-1/16384 实测 TTFT 16~18s，4000 约 6.7s）。
  // 因此 Fast 档固定 4000，High Effort 档保留 16384 供长任务使用。
  // 两项 uid 都是合成别名，由 _ag-gemini37-compat.cjs 的 UID_ALIAS 解析回真实 uid 并强制写 budget。
  { label: 'Gemini 4 Hydrogen (Fast)',        uid: 'gemini-4-hydrogen-sonar' },
  { label: 'Gemini 4 Hydrogen (High Effort)', uid: 'gemini-4-hydrogen-sonar-high' },
];
if (MODELS.length === 0) {
  fs.copyFileSync(prePath, wbPath);
  console.log('MODELS 为空 → 已还原干净基线（无合成项，下拉仅显示官方原生模型）');
  console.log('wb size =', fs.statSync(wbPath).size);
  process.exit(0);
}

// ===== 僵尸项屏蔽 =====
// 旧版 IDE 客户端把一部分模型硬编码在下拉里，服务端下线后这些项仍然显示、选中必然失败。
// 名单不手写，由 `python model-unlock/probe-models.py` 实测（真实 token 打 streamGenerateContent）
// 产出 model-health.json 的 dead 列表驱动；这里只映射「客户端下拉里真实存在」的 label，
// 未命中映射的 uid 不进黑名单，避免误杀。
const HEALTH_PATH = path.join(__dirname, 'model-health.json');
// 用户明确不要、即使服务端仍可用也不放进下拉的模型（GPT-OSS 120B 实测 200，但不需要）。
// 与 health.json 的 dead 列表合并，health 读不到时也照常生效。
const ALWAYS_BLOCKED_UID = [
  'gpt-oss-120b-medium',
  // 用户要求只保留 Gemini 4：下列虽然现在还能返回 200，但都在 11-30 下线名单内，提前移除
  'gemini-3.8-flash-tiered',
  'claude-sonnet-4-6',
  'claude-opus-4-6-thinking',
];
// uid → 下拉里可能出现的全部 label 写法（服务端 displayName 与客户端硬编码可能不同，全部覆盖防漏）
const UID_TO_LABEL = {
  'gemini-3.8-flash-high': ['Gemini 3.8 Flash (High)'],
  'gemini-3.8-flash-medium': ['Gemini 3.8 Flash (Medium)'],
  'gemini-3.8-flash-low': ['Gemini 3.8 Flash (Low)'],
  'gemini-3.8-flash-tiered': ['Gemini 3.8 Flash (Tiered)'],
  'claude-sonnet-4-6': ['Claude Sonnet 4.6 (Thinking)'],
  'claude-opus-4-6-thinking': ['Claude Opus 4.6 (Thinking)'],
  'gpt-oss-120b-medium': ['GPT-OSS 120B (Medium)', 'GPT-OSS 120B'],
};
const labelsOf = (uids) => [...new Set(uids.flatMap((u) => UID_TO_LABEL[u] || []))];
let BLOCKED = [];
try {
  const health = JSON.parse(fs.readFileSync(HEALTH_PATH, 'utf8'));
  BLOCKED = labelsOf([...(health.dead || []).map((d) => d.uid), ...ALWAYS_BLOCKED_UID]);
  console.log('探测时间:', health.probedAt || '?', '| 屏蔽项:', BLOCKED.length ? BLOCKED.join(' / ') : '(无)');
} catch {
  BLOCKED = labelsOf(ALWAYS_BLOCKED_UID);
  console.log('WARN: 未读取 model-health.json，仅屏蔽常驻排除项:', BLOCKED.join(' / ') || '(无)');
}
const BLOCKED_LIT = '[' + BLOCKED.map((x) => JSON.stringify(x)).join(',') + ']';

const optLit = m => '{label:' + JSON.stringify(m.label) +
  ',value:0,modelAlias:8,__agUid:' + JSON.stringify(m.uid) +
  ',disabled:!1,supportsImages:!0,supportedMimeTypes:new Map(),betaWarningMessage:"",isBeta:!1,pricingType:0,description:"",quotaInfo:{remainingFraction:1,resetTime:{seconds:"0",nanos:0}},tagTitle:"New",tagDescription:""}';
const ARR = '[' + MODELS.map(optLit).join(',') + ']';
// 官方目录（fetchAvailableModels 的 Recommended 组）已把同名列进推荐，且每次刷新下发的内容会变；
// 直接 concat 会让同一 label 出现两项（"偶发下拉重复"根因）。三处注入统一先剔除官方同名牌，
// 再追加合成项：每个 label 只留一项，且留下的一定是带 __agUid 的合成项
//（官方同名项没有 __agUid，选中会被 /__agtarget 回退上报成默认 3.8）。
const LABELS = '[' + MODELS.map(m => JSON.stringify(m.label)).join(',') + ']';
// agDedup 是统一去重标记，verify-workbench.mjs 按它计数（必须恰好 3 处）
const noDup = v => '.filter(' + v + '=>!/*agDedup*/' + LABELS + '.includes(' + v + '.label))';
// agBlock 是僵尸项屏蔽标记（名单来自 model-health.json 的 dead），verify-workbench.mjs 按它计数（必须恰好 3 处）
const noBlock = v => '.filter(' + v + '=>!/*agBlock*/' + BLOCKED_LIT + '.includes(' + v + '.label))';

fs.copyFileSync(prePath, wbPath);
let s = fs.readFileSync(wbPath, 'utf8');

const patches = [
  // 下拉分组(nKc)：无条件追加（仅影响下拉显示，不参与启动默认选择）
  { name: 'nKc recommended',
    old: 'return i?(i.groups[0].options||[]).filter(n=>!e.some(s=>s.label===n.label)):[]',
    neu: 'return (i?(i.groups[0].options||[]).filter(n=>!e.some(s=>s.label===n.label))' + noDup('n') + noBlock('n') + ':[]).concat(' + ARR + ')' },
  // visibleModelConfigs(dut E)：仅当官方配置已加载才追加，避免启动早期 E 仅含合成项被当默认选中
  { name: 'dut E modelOptions',
    old: '.filter(F=>!F.disabled),[o?.cascadeModelConfigData])',
    neu: '.filter(F=>!F.disabled)' + noDup('F') + noBlock('F') + '.concat(((o?.cascadeModelConfigData?.clientModelConfigs||[]).length>0)?' + ARR + ':[]),[o?.cascadeModelConfigData])' },
  // Xlt store modelOptions(vKc)：同理，官方非空才追加
  { name: 'vKc modelOptions',
    old: 'modelSorts:o,modelOptions:a,',
    neu: 'modelSorts:o,modelOptions:a' + noDup('n') + noBlock('n') + '.concat(a.length?' + ARR + ':[]),' },
  // 回显匹配：alias:8 被 3.8 与所有 Claude 档共用，优先按最近一次选择的 label 精确匹配
  { name: 'Kun echo match',
    old: 'function Kun(t,e){return e.find(i=>{let n=t?.choice;return n?.case==="model"&&i.value===n?.value||n?.case==="alias"&&i.modelAlias===n?.value})}',
    neu: 'function Kun(t,e){let m=i=>{let n=t?.choice;return n?.case==="model"&&i.value===n?.value||n?.case==="alias"&&i.modelAlias===n?.value};let g=globalThis.__agSelLabel;return(g&&e.find(i=>i.label===g&&m(i)))||e.find(m)}' },
  // 选择即旁路上报：合成项带 __agUid 才上报（官方项没有 __agUid，说明 LS 自己有真实 uid，
  // 绝不能回退成硬编码 uid，否则会把已 404 的 gemini-3.8-flash-high 写进旁路、顶掉用户真正的选择）
  { name: 'I select report',
    old: 'let I=Zt((F,D=!0)=>{r("selected_model_changed",ah({name:F.label},"model label from server-controlled set"));let N=',
    neu: 'let I=Zt((F,D=!0)=>{r("selected_model_changed",ah({name:F.label},"model label from server-controlled set"));try{globalThis.__agSelLabel=F.label;let u=F&&F.__agUid;if(u)fetch("http://127.0.0.1:8937/__agtarget?uid="+encodeURIComponent(u)+"&label="+encodeURIComponent((F&&F.label)||"")).catch(()=>{});}catch{}let N=' },
];

let ok = true;
for (const p of patches) {
  let n = 0, i = 0; while ((i = s.indexOf(p.old, i)) >= 0) { n++; i += p.old.length; }
  console.log(p.name.padEnd(20), 'anchor count =', n);
  if (n !== 1) ok = false;
}
if (!ok) { console.log('ANCHOR CHECK FAILED — 不写入'); process.exit(1); }
for (const p of patches) { s = s.split(p.old).join(p.neu); console.log('applied', p.name); }
// 先在内存里做语法校验，通过才落盘——避免"wb 已写坏 + checksum 已同步"的半成品状态
const tmp = path.join(__dirname, 'wb-syntax-check.mjs');
fs.writeFileSync(tmp, s, 'utf8');
let syntaxOk = true;
try { execFileSync('node', ['--check', tmp], { stdio: 'pipe' }); console.log('SYNTAX OK'); }
catch (e) { syntaxOk = false; console.log('SYNTAX FAIL:\n' + (e.stderr ? e.stderr.toString().slice(0, 1500) : e.message)); }
finally { try { fs.rmSync(tmp, { force: true }); } catch {} }
if (!syntaxOk) {
  // 语法校验失败：此时 wb 还没写入、checksum 还没同步，直接退出即可，磁盘保持原状
  console.log('注入内容语法校验失败，未写入任何文件（workbench 与 product.json 保持原状）');
  process.exit(2);
}

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
  // 原子写：先写 .tmp 再 rename，防断电/崩溃导致 product.json 损坏使 IDE 起不来
  const tmpProduct = productPath + '.tmp';
  fs.writeFileSync(tmpProduct, JSON.stringify(product, null, 2), 'utf8');
  fs.renameSync(tmpProduct, productPath);
  console.log('product.json checksum synced =', b64);
} catch (e) {
  console.log('WARN: product.json 同步失败（不影响 workbench 注入）:', e.message);
}
