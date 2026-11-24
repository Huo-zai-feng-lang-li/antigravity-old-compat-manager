"""探测当前账号下所有模型的真实可用性，落盘 model-health.json。

数据源：
  1) v1internal:fetchAvailableModels —— 服务端下发的模型清单（uid 全量）
  2) 已知 legacy uid —— 客户端硬编码、服务端可能已删除的僵尸项
判定：
  streamGenerateContent 返回 200 且拿到 modelVersion → ok
  404 / 4xx / 5xx → dead（附状态码与错误信息）
输出：
  <repo>/model-unlock/model-health.json
"""

import json
import os
import sqlite3
import sys
import time
import urllib.error
import urllib.request

DB = os.path.expandvars(r"%APPDATA%\Antigravity\User\globalStorage\state.vscdb")
OUT = os.path.join(
    r"D:\Desktop\Super-File\AI-IDE\AI\反重力\antigravity-old-compat-manager",
    "model-unlock",
    "model-health.json",
)
HOST = "https://daily-cloudcode-pa.googleapis.com"
PROJECT = "aicode-consumers"
UA = "Antigravity/1.107.0 Chrome/142.0.7444.175 Electron/39.2.3 Safari/537.36"
PROXY = "http://127.0.0.1:51081"

LEGACY = [
    "claude-opus-5-5-high", "claude-opus-5-5-medium", "claude-opus-5-5-low",
    "claude-sonnet-5-5-high", "claude-sonnet-5-5-medium", "claude-sonnet-5-5-low",
    "gemini-3.8-flash-high", "gemini-3.8-flash-medium", "gemini-3.8-flash-low",
    "gemini-3.8-flash", "gemini-3.8-flash-n", "gemini-3.8-flash-t",
    "gemini-4-hydrogen-high", "gemini-4-hydrogen-medium", "gemini-4-hydrogen-low",
    "gemini-4-neon-high", "gemini-4-carbon-high", "gemini-4-argon-high",
    "orchestrator-argon", "orchestrator-carbon",
]


def read_token():
    con = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)
    cur = con.cursor()
    cur.execute("SELECT value FROM ItemTable WHERE key = 'antigravityAuthStatus'")
    row = cur.fetchone()
    con.close()
    if not row:
        raise SystemExit("state.vscdb 中没有 antigravityAuthStatus")
    return json.loads(row[0])["apiKey"]


def build_opener():
    return urllib.request.build_opener(
        urllib.request.ProxyHandler({"https": PROXY, "http": PROXY})
    )


def post(opener, path, token, body, timeout=40):
    req = urllib.request.Request(
        HOST + path,
        data=json.dumps(body).encode(),
        headers={
            "authorization": "Bearer " + token,
            "content-type": "application/json",
            "user-agent": UA,
            "accept": "text/event-stream",
        },
        method="POST",
    )
    return opener.open(req, timeout=timeout)


def probe(opener, token, uid):
    body = {
        "model": uid,
        "project": PROJECT,
        "request": {
            "contents": [{"role": "user", "parts": [{"text": "ok"}]}],
            "generationConfig": {"thinkingConfig": {"thinkingBudget": -1}},
            "sessionId": "",
        },
    }
    try:
        with post(opener, "/v1internal:streamGenerateContent?alt=sse", token, body) as r:
            raw = r.read(4000).decode("utf-8", "replace")
            status = r.status
    except urllib.error.HTTPError as e:
        raw = e.read(600).decode("utf-8", "replace")
        status = e.code
    except Exception as e:
        return {"uid": uid, "status": 0, "err": f"{type(e).__name__}: {e}"}

    ver = None
    err = None
    m = raw.find('"modelVersion"')
    if m >= 0:
        seg = raw[m:m + 80]
        parts = seg.split('"')
        if len(parts) >= 4:
            ver = parts[3]
    if status != 200:
        try:
            j = json.loads(raw)
            err = j.get("error", {}).get("message")
        except Exception:
            err = raw.strip().splitlines()[0][:120] if raw.strip() else None

    return {"uid": uid, "status": status, "ver": ver, "err": err}


def main():
    token = read_token()
    opener = build_opener()

    # 1) 服务端清单
    catalog = []
    try:
        with post(opener, "/v1internal:fetchAvailableModels", token, {"project": PROJECT}) as r:
            data = json.loads(r.read().decode("utf-8", "replace"))
        catalog = [k for k in (data.get("models") or {}) if not k.startswith("tab_")]
        sorts = data.get("agentModelSorts") or []
        print(f"fetchAvailableModels OK · {len(catalog)} 个模型")
        for s in sorts:
            print("  sort:", s.get("displayName"), [g.get("modelIds") for g in (s.get("groups") or [])])
    except Exception as e:
        print("fetchAvailableModels 失败:", e)
        print("（继续用 legacy 清单探测）")

    # 2) 去重后全量探测
    targets = []
    seen = set()
    for uid in catalog + LEGACY:
        if uid in seen:
            continue
        seen.add(uid)
        targets.append(uid)

    ok, dead = [], []
    for uid in targets:
        p = probe(opener, token, uid)
        if p["status"] == 200 and p.get("ver"):
            ok.append(p)
            print(f"  OK    {uid:34} ver={p['ver']}")
        else:
            dead.append(p)
            print(f"  DEAD  {uid:34} status={p['status']} err={p.get('err')}")
        time.sleep(0.3)

    payload = {
        "probedAt": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "project": PROJECT,
        "catalogCount": len(catalog),
        "catalog": catalog,
        "ok": ok,
        "dead": dead,
    }
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)

    print(f"\n可用 {len(ok)} 个 / 不可用 {len(dead)} 个")
    print("写入:", OUT)
    return 0 if ok else 2


if __name__ == "__main__":
    sys.exit(main())
