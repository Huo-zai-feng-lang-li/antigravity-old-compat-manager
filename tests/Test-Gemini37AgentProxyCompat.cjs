"use strict";

const assert = require("node:assert/strict");
const {
  SOURCE_MODEL,
  TARGET_MODEL,
  rewriteRequestBody,
} = require("../runtime/Gemini37AgentProxyCompat.cjs");

assert.equal(SOURCE_MODEL, "gemini-2.5-pro");
assert.equal(TARGET_MODEL, "gemini-3.8-flash-high");

const source = Buffer.from(
  JSON.stringify({
    model: SOURCE_MODEL,
    project: "test-project",
    request: { contents: [{ role: "user", parts: [{ text: "2+2" }] }] },
  }),
);
const rewritten = rewriteRequestBody(source);
assert.notStrictEqual(rewritten, source);
assert.deepEqual(JSON.parse(rewritten.toString("utf8")), {
  model: TARGET_MODEL,
  project: "test-project",
  request: { contents: [{ role: "user", parts: [{ text: "2+2" }] }] },
});

for (const model of [
  "gemini-3.6-flash-high",
  "gemini-3.6-flash-medium",
  "gemini-3.7-flash-high",
  "claude-sonnet-4-6-thinking",
  TARGET_MODEL,
]) {
  const body = Buffer.from(JSON.stringify({ model, request: {} }));
  assert.strictEqual(rewriteRequestBody(body), body, `${model} must pass through`);
}

const malformed = Buffer.from("not-json");
assert.strictEqual(rewriteRequestBody(malformed), malformed);
assert.strictEqual(rewriteRequestBody(null), null);

console.log("PASS: Gemini 3.7 proxy rewrite is exact and preserves 3.6/Claude");
