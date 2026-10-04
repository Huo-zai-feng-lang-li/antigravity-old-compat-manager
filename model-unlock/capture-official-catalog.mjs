#!/usr/bin/env node
/**
 * capture-official-catalog.mjs · 临时抓取官方 fetchAvailableModels 模型目录（含真实 uid）
 *
 * 为什么需要它：
 *   旧版语言服务器（LS，2026-03 冻结）会把新模型降级成整数 enum（modelOrAlias.choice.value=0），
 *   真实 uid 字符串（如 claude-sonnet-5-5-high / gemini-3.8-flash-high）只存在于官方
 *   fetchAvailableModels 的原始响应里；前端 clientModelConfigs 与下拉 DOM 里都拿不到真实 uid。
 *   zk 转发时已经在内存里完整缓冲了非流式 RPC 响应（source.js 的 _modelBuf，上限 2MB；
 *   fetchAvailableModels 是非流式 RPC、约 200KB，本就被完整缓冲），本脚本只是临时让它在遇到
 *   fetchAvailableModels / loadCodeAssist 时把响应（gzip 则先 gunzip）落盘一份，用完即撤。
 *
 * 用法（在 compat-manager 仓库根目录）：
 *   node model-unlock/capture-official-catalog.mjs check     干跑：只校验锚点/现状，绝不写入
 *   node model-unlock/capture-official-catalog.mjs install   插入临时落盘探针（先自动备份 source.js）
 *   node model-unlock/capture-official-catalog.mjs restore   用备份还原 / 按标记精确移除探针
 *   （可选第二参数显式指定 source.js 路径，默认自动选版本号最高的已安装 zk 扩展）
 *
 * 操作时序：
 *   1) install  2) 彻底关闭 IDE（ag=0、ls=0）  3) 启动 IDE，等 10-30 秒让模型列表刷新
 *   4) 取 <扩展目录>\vendor\bundled-origin\_agcap\_ag-models-catalog.json
 *   5) 复制覆盖 model-unlock\fetchAvailableModels.json，跑 list-official-uids.mjs 拿真实 uid
 *   6) restore 撤销探针（或直接重装干净 vsix，等同清除）
 *
 * 安全护栏：
 *   - 锚点在文件中计数必须恰为 1，否则拒绝写入（IDE/插件版本变动导致锚点漂移时绝不硬改）；
 *   - install 幂等（探针已存在则跳过）；首次插入前自动备份 source.js.agcap.bak；
 *   - 写入后立即 node --check，失败自动回滚备份；
 *   - 只被动落盘一份响应到环回本机 _agcap 目录，不修改任何请求/响应/模型选择/默认值逻辑。
 */
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { execFileSync } from 'node:child_process';

const MARK_BEGIN = '/*__AG_CAP_CATALOG_BEGIN*/';
const MARK_END = '/*__AG_CAP_CATALOG_END*/';
const BAK_NAME = 'source.js.agcap.bak';
const EXT_ROOT = path.join(os.homedir(), '.antigravity', 'extensions');

function resolveSource(explicit) {
  if (explicit) {
    if (!fs.existsSync(explicit)) throw new Error('指定的 source.js 不存在: ' + explicit);
    return explicit;
  }
  if (!fs.existsSync(EXT_ROOT)) throw new Error('扩展目录不存在: ' + EXT_ROOT);
  const dirs = fs
    .readdirSync(EXT_ROOT)
    .filter((d) => /^zk-agent\.zk-proxy-pro-/.test(d))
    .map((d) => {
      const m = d.match(/zk-proxy-pro-(\d+)\.(\d+)\.(\d+)$/);
      return { d, ver: m ? m.slice(1).map(Number) : [0, 0, 0] };
    })
    .sort((a, b) => {
      for (let i = 0; i < 3; i++) if (a.ver[i] !== b.ver[i]) return b.ver[i] - a.ver[i];
      return 0;
    });
  if (!dirs.length) throw new Error('未找到 zk-agent.zk-proxy-pro-* 扩展目录');
  const sj = path.join(EXT_ROOT, dirs[0].d, 'vendor', 'bundled-origin', 'source.js');
  if (!fs.existsSync(sj)) throw new Error('扩展目录下未找到 source.js: ' + sj);
  return sj;
}

// 锚点：_extractModelsFromRPC 调用点（全文唯一）。探针紧随其后、位于同一 try 块内。
const ANCHOR =
  '                const fullBody = Buffer.concat(_modelBuf);\n' +
  '                _extractModelsFromRPC(fullBody, _rpcPath);\n' +
  '              } catch {}';
const PROBE =
  '                const fullBody = Buffer.concat(_modelBuf);\n' +
  '                _extractModelsFromRPC(fullBody, _rpcPath);\n' +
  '                ' + MARK_BEGIN + '\n' +
  '                if(/fetchAvailableModels|loadCodeAssist/i.test(_rpcPath)){\n' +
  "                  try{\n" +
  "                    const _cp=require('path').join(__dirname,'_agcap');\n" +
  "                    require('fs').mkdirSync(_cp,{recursive:true});\n" +
  '                    let _txt=fullBody;\n' +
  '                    if(fullBody[0]===0x1f&&fullBody[1]===0x8b){ try{_txt=require(\'zlib\').gunzipSync(fullBody);}catch{} }\n' +
  "                    const _name=/fetchAvailableModels/i.test(_rpcPath)?'_ag-models-catalog.json':'_ag-models-loadcodeassist.json';\n" +
  "                    require('fs').writeFileSync(require('path').join(_cp,_name),_txt);\n" +
  '                  }catch{}\n' +
  '                }\n' +
  '                ' + MARK_END + '\n' +
  '              } catch {}';

const countOf = (s, sub) => s.split(sub).length - 1;
function nodeCheck(file) {
  try {
    execFileSync('node', ['--check', file], { stdio: 'pipe' });
    return true;
  } catch (e) {
    return e.stderr ? e.stderr.toString() : e.message;
  }
}

const cmd = process.argv[2] || 'check';
const explicit = process.argv[3] && fs.existsSync(process.argv[3]) ? process.argv[3] : undefined;
const sj = resolveSource(explicit);
const bak = path.join(path.dirname(sj), BAK_NAME);
const s = fs.readFileSync(sj, 'utf8');
const already = s.includes(MARK_BEGIN);
const anchorCount = countOf(s, ANCHOR);
console.log('source.js =', sj);
console.log('字节 =', fs.statSync(sj).size, '| 锚点计数 =', anchorCount, '| 探针已存在 =', already, '| 备份存在 =', fs.existsSync(bak));

if (cmd === 'check') {
  if (already) console.log('状态: 探针已安装 → 重启 IDE 后到 _agcap\\_ag-models-catalog.json 取目录');
  else if (anchorCount === 1) console.log('状态: 锚点正常 → 可执行 install 安全插入探针');
  else console.log('状态: 锚点计数异常（期望 1，实际 ' + anchorCount + '），install 将拒绝写入；需按 SOP 重新定位锚点');
  process.exit(0);
}

if (cmd === 'install') {
  if (already) {
    console.log('探针已存在，跳过（幂等）');
    process.exit(0);
  }
  if (anchorCount !== 1) {
    console.error('ANCHOR COUNT = ' + anchorCount + '，期望 1，已拒绝写入（文件未改动）');
    process.exit(1);
  }
  if (!fs.existsSync(bak)) fs.copyFileSync(sj, bak); // 仅保留首个干净原版
  fs.writeFileSync(sj, s.split(ANCHOR).join(PROBE), 'utf8');
  const chk = nodeCheck(sj);
  if (chk !== true) {
    fs.copyFileSync(bak, sj);
    console.error('node --check 失败，已回滚备份:\n' + chk);
    process.exit(2);
  }
  console.log('探针已插入并通过 node --check；备份 =', bak);
  console.log('下一步: 彻底关闭 IDE(ag=0,ls=0) 再启动，等 10-30 秒模型列表刷新；');
  console.log('取文件: ...\\vendor\\bundled-origin\\_agcap\\_ag-models-catalog.json');
  process.exit(0);
}

if (cmd === 'restore') {
  if (fs.existsSync(bak)) {
    fs.copyFileSync(bak, sj);
    const chk = nodeCheck(sj);
    if (chk !== true) {
      console.error('还原后 node --check 失败，请重装干净 vsix:\n' + chk);
      process.exit(2);
    }
    console.log('已用备份还原 source.js 并通过 node --check');
  } else if (already) {
    fs.writeFileSync(sj, s.split(PROBE).join(ANCHOR), 'utf8');
    const chk = nodeCheck(sj);
    if (chk !== true) {
      console.error('移除探针后 node --check 失败，请重装干净 vsix:\n' + chk);
      process.exit(2);
    }
    console.log('无备份，已按标记精确移除探针并通过 node --check');
  } else {
    console.log('既无备份也无探针标记，无需还原');
  }
  process.exit(0);
}

console.error('未知命令: ' + cmd + '（支持 check / install / restore）');
process.exit(1);
