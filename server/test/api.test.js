// Loads the Vercel entry point and serves it the way Vercel does: a plain
// (req, res) handler, with every path routed to it.

const {test, before, after} = require("node:test");
const assert = require("node:assert/strict");
const http = require("node:http");

let server;
let baseUrl;

before(async () => {
  const handler = require("../api/index.js");
  server = http.createServer(handler).listen(0);
  await new Promise((resolve) => server.once("listening", resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(() => server.close());

test("exports a request handler", () => {
  assert.equal(typeof require("../api/index.js"), "function");
});

test("health check on / and /health", async () => {
  assert.equal((await fetch(`${baseUrl}/`)).status, 200);
  assert.deepEqual(await (await fetch(`${baseUrl}/health`)).json(), {ok: true});
});

test("notify routes are reachable and require sign-in", async () => {
  for (const path of ["/notify/message", "/notify/call"]) {
    const res = await fetch(baseUrl + path, {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: "{}",
    });
    assert.equal(res.status, 401, path);
  }
});

test("unknown path is 404, not a crash", async () => {
  assert.equal((await fetch(`${baseUrl}/nope`)).status, 404);
});
