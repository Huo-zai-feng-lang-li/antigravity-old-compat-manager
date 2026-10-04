/**
 * 从官方 fetchAvailableModels 快照（fetchAvailableModels.json）列出全部
 * Claude / Gemini 模型 uid。放行新模型前先更新该快照，再用本脚本拿到真实 uid，
 * 填入 patch-workbench.mjs 顶部 MODELS。详见 SOP-新模型放行.md 第三节。
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const t = fs.readFileSync(path.join(__dirname, 'fetchAvailableModels.json'), 'utf8');
const claude = [...new Set(t.match(/claude-[a-z0-9.\-]+/g) || [])].sort();
const gemini = [...new Set(t.match(/gemini-[0-9][a-z0-9.\-]*/g) || [])].sort();
console.log('=== CLAUDE uid ===');
claude.forEach((u) => console.log('  ' + u));
console.log('=== GEMINI uid ===');
gemini.forEach((u) => console.log('  ' + u));
