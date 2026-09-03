"use strict";

const SOURCE_MODEL = "gemini-2.5-pro";
const TARGET_MODEL = "gemini-3.8-flash-high";

function rewriteRequestBody(body) {
  if (!Buffer.isBuffer(body)) return body;
  try {
    const request = JSON.parse(body.toString("utf8"));
    if (!request || request.model !== SOURCE_MODEL) return body;
    request.model = TARGET_MODEL;
    return Buffer.from(JSON.stringify(request), "utf8");
  } catch {
    return body;
  }
}

module.exports = { SOURCE_MODEL, TARGET_MODEL, rewriteRequestBody };
