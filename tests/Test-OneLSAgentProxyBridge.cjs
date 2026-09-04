"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const http = require("node:http");
const os = require("node:os");
const path = require("node:path");

const {
  findLatestAgentPro,
  getCandidatePorts,
  waitForAgentProxy,
} = require("../runtime/OneLSAgentProxyBridge.cjs");

const EXTENSION_ID = "zk-agent.dao-proxy-pro";

function createFixture() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "one-ls-bridge-"));
  const extensionsRoot = path.join(root, ".antigravity", "extensions");
  const homeDir = path.join(root, "home");
  fs.mkdirSync(extensionsRoot, { recursive: true });
  fs.mkdirSync(homeDir, { recursive: true });
  return {
    extensionsRoot,
    homeDir,
    cleanup: () => fs.rmSync(root, { recursive: true, force: true }),
  };
}

function installAgentPro(extensionsRoot, version) {
  const extensionDir = path.join(extensionsRoot, `${EXTENSION_ID}-${version}`);
  const sourceFile = path.join(
    extensionDir,
    "vendor",
    "bundled-origin",
    "source.js",
  );
  fs.mkdirSync(path.dirname(sourceFile), { recursive: true });
  fs.writeFileSync(sourceFile, "throw new Error('source.js must not be loaded');\n");
  return { extensionDir, sourceFile };
}

function markObsolete(extensionsRoot, names) {
  const obsolete = Object.fromEntries(names.map((name) => [name, true]));
  fs.writeFileSync(
    path.join(extensionsRoot, ".obsolete"),
    JSON.stringify(obsolete),
  );
}

function publishPort(homeDir, port) {
  const daoDir = path.join(homeDir, ".dao");
  fs.mkdirSync(daoDir, { recursive: true });
  fs.writeFileSync(
    path.join(daoDir, "origin-port.json"),
    JSON.stringify({ port }),
  );
}

async function startPingServer(selfFile) {
  const server = http.createServer((request, response) => {
    if (request.url !== "/origin/ping") {
      response.writeHead(404).end();
      return;
    }
    response.setHeader("content-type", "application/json");
    response.end(JSON.stringify({ ok: true, self_file: selfFile }));
  });
  await new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(0, "127.0.0.1", resolve);
  });
  return {
    port: server.address().port,
    close: () => new Promise((resolve) => server.close(resolve)),
  };
}

const tests = [];
function test(name, run) {
  tests.push({ name, run });
}

test("选择最高可用 Agent Pro 语义版本", () => {
  const fixture = createFixture();
  try {
    installAgentPro(fixture.extensionsRoot, "9.9.999");
    const expected = installAgentPro(fixture.extensionsRoot, "9.10.0");

    const actual = findLatestAgentPro({
      extensionsRoot: fixture.extensionsRoot,
    });

    assert.equal(actual.version, "9.10.0");
    assert.equal(actual.extensionDir, expected.extensionDir);
    assert.equal(actual.sourceFile, expected.sourceFile);
  } finally {
    fixture.cleanup();
  }
});

test("仅旧版本 obsolete 不影响当前版本", () => {
  const fixture = createFixture();
  try {
    installAgentPro(fixture.extensionsRoot, "9.9.334");
    const current = installAgentPro(fixture.extensionsRoot, "9.9.335");
    markObsolete(fixture.extensionsRoot, [`${EXTENSION_ID}-9.9.334`]);

    const actual = findLatestAgentPro({
      extensionsRoot: fixture.extensionsRoot,
    });

    assert.equal(actual.extensionDir, current.extensionDir);
  } finally {
    fixture.cleanup();
  }
});

test("当前版本 obsolete 后从候选中精确排除", () => {
  const fixture = createFixture();
  try {
    const previous = installAgentPro(fixture.extensionsRoot, "9.9.334");
    installAgentPro(fixture.extensionsRoot, "9.9.335");
    markObsolete(fixture.extensionsRoot, [`${EXTENSION_ID}-9.9.335`]);

    const actual = findLatestAgentPro({
      extensionsRoot: fixture.extensionsRoot,
    });

    assert.equal(actual.extensionDir, previous.extensionDir);
  } finally {
    fixture.cleanup();
  }
});

test("origin-port.json 动态端口优先于备用端口", () => {
  const fixture = createFixture();
  try {
    publishPort(fixture.homeDir, 43123);
    assert.deepEqual(
      getCandidatePorts({ homeDir: fixture.homeDir, username: "alice" }),
      [43123, 8901],
    );
  } finally {
    fixture.cleanup();
  }
});

test("用户名 FNV 端口作为无动态端口时的备用", () => {
  const fixture = createFixture();
  try {
    assert.deepEqual(
      getCandidatePorts({ homeDir: fixture.homeDir, username: "alice" }),
      [8901],
    );
  } finally {
    fixture.cleanup();
  }
});

test("/origin/ping self_file 精确匹配时返回本地端点", async () => {
  const fixture = createFixture();
  let server;
  try {
    const current = installAgentPro(fixture.extensionsRoot, "9.9.335");
    server = await startPingServer(current.sourceFile);
    publishPort(fixture.homeDir, server.port);

    const endpoint = await waitForAgentProxy({
      extensionsRoot: fixture.extensionsRoot,
      homeDir: fixture.homeDir,
      username: "alice",
      timeoutMs: 200,
      intervalMs: 10,
      requestTimeoutMs: 50,
    });

    assert.equal(endpoint, `http://127.0.0.1:${server.port}`);
  } finally {
    if (server) await server.close();
    fixture.cleanup();
  }
});

test("/origin/ping self_file 不匹配时拒绝接管", async () => {
  const fixture = createFixture();
  let server;
  try {
    installAgentPro(fixture.extensionsRoot, "9.9.335");
    server = await startPingServer(path.join(fixture.homeDir, "fake", "source.js"));
    publishPort(fixture.homeDir, server.port);

    const endpoint = await waitForAgentProxy({
      extensionsRoot: fixture.extensionsRoot,
      homeDir: fixture.homeDir,
      username: "alice",
      timeoutMs: 60,
      intervalMs: 10,
      requestTimeoutMs: 20,
    });

    assert.equal(endpoint, null);
  } finally {
    if (server) await server.close();
    fixture.cleanup();
  }
});

test("非 200 响应立即释放 socket，不遗留请求超时器", async () => {
  const fixture = createFixture();
  const sockets = new Set();
  let maxSockets = 0;
  const server = http.createServer((_request, response) => {
    response.writeHead(404);
    response.write("not-agent-pro");
  });
  server.on("connection", (socket) => {
    sockets.add(socket);
    maxSockets = Math.max(maxSockets, sockets.size);
    socket.on("close", () => sockets.delete(socket));
  });

  try {
    installAgentPro(fixture.extensionsRoot, "9.9.335");
    await new Promise((resolve, reject) => {
      server.once("error", reject);
      server.listen(0, "127.0.0.1", resolve);
    });
    publishPort(fixture.homeDir, server.address().port);

    const endpoint = await waitForAgentProxy({
      extensionsRoot: fixture.extensionsRoot,
      homeDir: fixture.homeDir,
      username: "alice",
      timeoutMs: 40,
      intervalMs: 5,
      requestTimeoutMs: 1000,
    });
    const closedBeforeDeadline = await new Promise((resolve) => {
      const deadline = Date.now() + 100;
      const check = () => {
        if (sockets.size === 0) resolve(true);
        else if (Date.now() >= deadline) resolve(false);
        else setTimeout(check, 5);
      };
      check();
    });

    assert.equal(endpoint, null);
    assert.ok(maxSockets <= 1, `peak open sockets: ${maxSockets}`);
    assert.equal(closedBeforeDeadline, true, `${sockets.size} socket(s) remained`);
  } finally {
    for (const socket of sockets) socket.destroy();
    await new Promise((resolve) => server.close(resolve));
    fixture.cleanup();
  }
});

test("无 Agent Pro 安装时立即返回 null", async () => {
  const fixture = createFixture();
  try {
    const startedAt = Date.now();
    const endpoint = await waitForAgentProxy({
      extensionsRoot: fixture.extensionsRoot,
      homeDir: fixture.homeDir,
      timeoutMs: 1000,
    });

    assert.equal(endpoint, null);
    assert.ok(Date.now() - startedAt < 250, "无安装不应进入等待循环");
  } finally {
    fixture.cleanup();
  }
});

test("已安装但代理未就绪时超时返回 null", async () => {
  const fixture = createFixture();
  try {
    installAgentPro(fixture.extensionsRoot, "9.9.335");
    publishPort(fixture.homeDir, 65534);

    const endpoint = await waitForAgentProxy({
      extensionsRoot: fixture.extensionsRoot,
      homeDir: fixture.homeDir,
      username: "alice",
      timeoutMs: 60,
      intervalMs: 10,
      requestTimeoutMs: 20,
    });

    assert.equal(endpoint, null);
  } finally {
    fixture.cleanup();
  }
});

(async () => {
  for (const { name, run } of tests) {
    await run();
    console.log(`PASS ${name}`);
  }
  console.log(`PASS ${tests.length}/${tests.length}`);
})().catch((error) => {
  console.error(error.stack || error);
  process.exitCode = 1;
});
