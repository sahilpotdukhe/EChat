// Runs against the Firestore emulator (npm test starts it). Auth and
// messaging are fakes: "token-<uid>" signs in as <uid>, sends are recorded.

const {test, before, after, beforeEach} = require("node:test");
const assert = require("node:assert/strict");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, Timestamp} = require("firebase-admin/firestore");
const {createApp} = require("../src/app");

initializeApp({projectId: "demo-echat"});
const db = getFirestore();

const sent = [];
const claims = {};
const auth = {
  verifyIdToken: async (token) => {
    if (!token.startsWith("token-")) throw new Error("bad token");
    return {uid: token.slice("token-".length)};
  },
  getUser: async (uid) => ({uid, customClaims: claims[uid]}),
  setCustomUserClaims: async (uid, value) => {
    claims[uid] = value;
  },
};
const messaging = {
  send: async (message) => {
    if (message.token === "dead-token") {
      throw Object.assign(new Error("gone"), {code: "messaging/registration-token-not-registered"});
    }
    sent.push(message);
  },
};
const quietLogger = {info() {}, error() {}};

let server;
let baseUrl;

before(async () => {
  server = createApp({db, auth, messaging, logger: quietLogger, agoraCertificate: "0123456789abcdef0123456789abcdef"}).listen(0);
  await new Promise((resolve) => server.once("listening", resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(() => server.close());

beforeEach(async () => {
  sent.length = 0;
  await fetch("http://127.0.0.1:8080/emulator/v1/projects/demo-echat/databases/(default)/documents", {method: "DELETE"});
  await db.doc("Users/alice").set({uid: "alice", name: "Alice", notification_token: "tok-alice"});
  await db.doc("Users/bob").set({uid: "bob", name: "Bob", notification_token: "tok-bob", profile_photo: "https://x/b.jpg"});
});

function post(path, body, token) {
  return fetch(baseUrl + path, {
    method: "POST",
    headers: {"content-type": "application/json", ...(token ? {authorization: `Bearer ${token}`} : {})},
    body: JSON.stringify(body),
  });
}

// Saves a message the way the app does: both copies, same id.
async function saveMessage(from, to, extra = {}) {
  const msg = {senderId: from, receiverId: to, type: "text", message: "hi", timestamp: Timestamp.now(), ...extra};
  const id = db.collection("x").doc().id;
  await db.doc(`messages/${from}/${to}/${id}`).set(msg);
  await db.doc(`messages/${to}/${from}/${id}`).set(msg);
  return id;
}

async function startCall(from, to) {
  const call = {caller_id: from, receiver_id: to, channel_id: "room1", callType: "videoCall", accepted: false};
  await db.doc(`Call/${from}`).set({...call, has_dialled: true});
  await db.doc(`Call/${to}`).set({...call, has_dialled: false});
}

test("health check", async () => {
  const res = await fetch(`${baseUrl}/health`);
  assert.equal(res.status, 200);
});

test("message: notifies the receiver with the sender's real name", async () => {
  const id = await saveMessage("alice", "bob");
  const res = await post("/notify/message", {messageId: id, receiverId: "bob"}, "token-alice");
  assert.equal(res.status, 200);
  assert.deepEqual(await res.json(), {sent: true});
  assert.equal(sent.length, 1);
  assert.equal(sent[0].token, "tok-bob");
  // Android: data only, the app draws the notification.
  assert.equal(sent[0].notification, undefined);
  assert.equal(sent[0].android.priority, "high");
  assert.deepEqual(sent[0].data, {type: "message", senderId: "alice", messageId: id, title: "Alice", body: "hi", badge: "0"});
  // iPhone: a normal alert.
  assert.deepEqual(sent[0].apns.payload.aps.alert, {title: "Alice", body: "hi"});
});

test("message: sender's photo goes along for the notification", async () => {
  const id = await saveMessage("bob", "alice");
  await post("/notify/message", {messageId: id, receiverId: "alice"}, "token-bob");
  assert.equal(sent[0].data.avatar, "https://x/b.jpg");
});

test("message: badge shows bob's unread total across chats", async () => {
  await db.doc("Users/bob/Contacts/alice").set({contact_id: "alice", unread_count: 2});
  await db.doc("Users/bob/Contacts/carol").set({contact_id: "carol", unread_count: 3});
  const id = await saveMessage("alice", "bob");
  await post("/notify/message", {messageId: id, receiverId: "bob"}, "token-alice");
  assert.equal(sent[0].apns.payload.aps.badge, 5);
  assert.equal(sent[0].data.badge, "5");
});

test("message: a missed call reads like WhatsApp", async () => {
  const id = await saveMessage("alice", "bob", {type: "call", message: "missed", callType: "videoCall"});
  await post("/notify/message", {messageId: id, receiverId: "bob"}, "token-alice");
  assert.equal(sent[0].data.body, "📞 Missed video call");
});

test("supabase role: added once, other claims kept", async () => {
  claims.alice = {admin: true};
  const res = await post("/supabase/role", {}, "token-alice");
  assert.equal(res.status, 200);
  assert.deepEqual(claims.alice, {admin: true, role: "authenticated"});
  assert.equal((await post("/supabase/role", {}, "bad")).status, 401);
});

test("message: second request for the same message sends nothing", async () => {
  const id = await saveMessage("alice", "bob");
  await post("/notify/message", {messageId: id, receiverId: "bob"}, "token-alice");
  const res = await post("/notify/message", {messageId: id, receiverId: "bob"}, "token-alice");
  assert.deepEqual(await res.json(), {sent: false, reason: "already notified"});
  assert.equal(sent.length, 1);
});

test("message: file types get a readable body", async () => {
  const id = await saveMessage("alice", "bob", {type: "docx", fileName: "notes.docx"});
  await post("/notify/message", {messageId: id, receiverId: "bob"}, "token-alice");
  assert.equal(sent[0].data.body, "📎 notes.docx");
});

test("message: no sign-in token is refused", async () => {
  const id = await saveMessage("alice", "bob");
  const res = await post("/notify/message", {messageId: id, receiverId: "bob"});
  assert.equal(res.status, 401);
  assert.equal(sent.length, 0);
});

test("message: forged token is refused", async () => {
  const id = await saveMessage("alice", "bob");
  const res = await post("/notify/message", {messageId: id, receiverId: "bob"}, "forged");
  assert.equal(res.status, 401);
});

test("message: someone else can't trigger it", async () => {
  const id = await saveMessage("alice", "bob");
  // eve isn't the sender, and messages/bob/eve/<id> doesn't exist
  const res = await post("/notify/message", {messageId: id, receiverId: "bob"}, "token-eve");
  assert.equal(res.status, 404);
  assert.equal(sent.length, 0);
});

test("message: receiver can't notify themselves about a message they got", async () => {
  const id = await saveMessage("alice", "bob");
  const res = await post("/notify/message", {messageId: id, receiverId: "alice"}, "token-bob");
  assert.equal(res.status, 403);
  assert.equal(sent.length, 0);
});

test("message: unknown message is 404, bad input is 400", async () => {
  assert.equal((await post("/notify/message", {messageId: "nope", receiverId: "bob"}, "token-alice")).status, 404);
  assert.equal((await post("/notify/message", {messageId: "../x", receiverId: "bob"}, "token-alice")).status, 400);
  assert.equal((await post("/notify/message", {}, "token-alice")).status, 400);
});

test("message: receiver without a token is skipped quietly", async () => {
  await db.doc("Users/bob").update({notification_token: ""});
  const id = await saveMessage("alice", "bob");
  const res = await post("/notify/message", {messageId: id, receiverId: "bob"}, "token-alice");
  assert.deepEqual(await res.json(), {sent: false});
});

test("message: dead token is cleared from the profile", async () => {
  await db.doc("Users/bob").update({notification_token: "dead-token"});
  const id = await saveMessage("alice", "bob");
  const res = await post("/notify/message", {messageId: id, receiverId: "bob"}, "token-alice");
  assert.deepEqual(await res.json(), {sent: false});
  assert.equal((await db.doc("Users/bob").get()).get("notification_token"), "");
});

test("call: rings the receiver once", async () => {
  await startCall("alice", "bob");
  const res = await post("/notify/call", {receiverId: "bob"}, "token-alice");
  assert.deepEqual(await res.json(), {sent: true});
  assert.equal(sent[0].data.type, "call");
  assert.equal(sent[0].data.title, "Alice");
  assert.equal(sent[0].data.body, "Incoming video call");
  assert.equal(sent[0].data.callType, "videoCall");
  assert.equal(sent[0].data.callerId, "alice");
  // Rings for at most 45 s.
  assert.equal(sent[0].android.ttl, 45000);

  const again = await post("/notify/call", {receiverId: "bob"}, "token-alice");
  assert.deepEqual(await again.json(), {sent: false, reason: "already notified"});
  assert.equal(sent.length, 1);
});

test("call: can't ring someone for a call you didn't start", async () => {
  await startCall("alice", "bob");
  const res = await post("/notify/call", {receiverId: "bob"}, "token-eve");
  assert.equal(res.status, 403);
  assert.equal(sent.length, 0);
});

test("call: caller's own doc (has_dialled true) is refused", async () => {
  await startCall("alice", "bob");
  const res = await post("/notify/call", {receiverId: "alice"}, "token-alice");
  assert.equal(res.status, 403);
});

test("call: no call is 404", async () => {
  const res = await post("/notify/call", {receiverId: "bob"}, "token-alice");
  assert.equal(res.status, 404);
});

test("call ended: silently tells the receiver to stop ringing", async () => {
  const res = await post("/notify/call-ended", {receiverId: "bob"}, "token-alice");
  assert.deepEqual(await res.json(), {sent: true});
  assert.equal(sent[0].token, "tok-bob");
  assert.deepEqual(sent[0].data, {type: "call_ended", callerId: "alice", senderId: "alice"});
  // No visible alert on iPhones either.
  assert.equal(sent[0].apns.payload.aps.alert, undefined);
});

test("call ended: refused while the call is still on", async () => {
  await startCall("alice", "bob");
  const res = await post("/notify/call-ended", {receiverId: "bob"}, "token-alice");
  assert.equal(res.status, 409);
  assert.equal(sent.length, 0);
});

test("call ended: someone else's call to the receiver doesn't block it", async () => {
  await startCall("eve", "bob");
  const res = await post("/notify/call-ended", {receiverId: "bob"}, "token-alice");
  assert.deepEqual(await res.json(), {sent: true});
});

test("call ended: needs sign-in and a receiver", async () => {
  assert.equal((await post("/notify/call-ended", {receiverId: "bob"})).status, 401);
  assert.equal((await post("/notify/call-ended", {}, "token-alice")).status, 400);
});

test("agora: people in the call get a pass, others don't", async () => {
  await startCall("alice", "bob");
  for (const who of ["alice", "bob"]) {
    const res = await post("/agora/token", {channelId: "room1"}, `token-${who}`);
    assert.equal(res.status, 200, who);
    const {token} = await res.json();
    assert.match(token, /^007/, "Agora 007 token");
  }
  assert.equal((await post("/agora/token", {channelId: "room1"}, "token-eve")).status, 403);
  assert.equal((await post("/agora/token", {channelId: "other"}, "token-alice")).status, 403);
  assert.equal((await post("/agora/token", {channelId: "room1"})).status, 401);
  assert.equal((await post("/agora/token", {}, "token-alice")).status, 400);
});
