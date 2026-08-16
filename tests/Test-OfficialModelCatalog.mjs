import assert from "node:assert/strict";
import { parseOfficialModels } from "../tools/OfficialModelCatalog.mjs";

const html = `
  <h2 id="reasoning-model">Reasoning Model</h2>
  <table>
    <thead><tr><th>Model</th><th>Free &amp; Google AI Plus</th></tr></thead>
    <tbody>
      <tr><td>Gemini 3.7 Flash</td><td>yes</td></tr>
      <tr><td>Claude Sonnet 4.6 (thinking)</td><td>yes</td></tr>
      <tr><td>Gemini 3.7 Flash</td><td>yes</td></tr>
    </tbody>
  </table>
  <h2 id="additional-models">Additional Models</h2>
  <ul><li>Nano Banana 2</li></ul>
`;

assert.deepEqual(parseOfficialModels(html), [
  "Gemini 3.7 Flash",
  "Claude Sonnet 4.6 (thinking)",
]);

assert.throws(
  () => parseOfficialModels("<h2 id='reasoning-model'>Reasoning Model</h2>"),
  /未找到官方推理模型表格/,
);

console.log("PASS: official reasoning model catalog parsing");
