import { pathToFileURL } from "node:url";

const officialModelsUrl = "https://antigravity.google/docs/models";

function textContent(html) {
  return html
    .replace(/<[^>]+>/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&#39;|&apos;/g, "'")
    .replace(/&nbsp;/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

export function parseOfficialModels(html) {
  const sectionStart = html.search(/<h2[^>]*id=["']reasoning-model["'][^>]*>/i);
  const tableStart = sectionStart < 0 ? -1 : html.indexOf("<table", sectionStart);
  const tableEnd = tableStart < 0 ? -1 : html.indexOf("</table>", tableStart);
  if (tableStart < 0 || tableEnd < 0) throw new Error("未找到官方推理模型表格。");

  const table = html.slice(tableStart, tableEnd);
  const models = [...table.matchAll(/<tr[^>]*>[\s\S]*?<td[^>]*>([\s\S]*?)<\/td>[\s\S]*?<\/tr>/gi)]
    .map((match) => textContent(match[1]))
    .filter(Boolean);
  const uniqueModels = [...new Set(models)];
  if (uniqueModels.length === 0) throw new Error("官方推理模型表格为空。");
  return uniqueModels;
}

export async function fetchOfficialModels(url = officialModelsUrl) {
  const response = await fetch(url, {
    headers: { "cache-control": "no-cache", "user-agent": "AntigravityCompatManager/1.0" },
    signal: AbortSignal.timeout(10000),
  });
  if (!response.ok) throw new Error(`官方模型目录请求失败：HTTP ${response.status}`);
  return {
    source: url,
    fetchedAt: new Date().toISOString(),
    models: parseOfficialModels(await response.text()),
  };
}

const isMain = process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href;
if (isMain) {
  console.log(JSON.stringify(await fetchOfficialModels(), null, 2));
}
