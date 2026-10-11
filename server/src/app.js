// HTTP API the app calls after sending a message or starting a call. The app
// never holds Firebase's messaging credentials; this server does.
//
// Every request carries the user's Firebase ID token. The server only sends a
// notification for a message/call that exists, was created by that user, and
// hasn't been notified yet, so the endpoint can't be used to spam people.

const express = require("express");
const {describeMessage, sendToUser} = require("./notifications");

class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

function isId(value) {
  return typeof value === "string" && /^[A-Za-z0-9_-]{1,128}$/.test(value);
}

function createApp({db, auth, messaging, logger = console}) {
  const deps = {db, messaging, logger};
  const app = express();
  app.use(express.json({limit: "10kb"}));

  app.get(["/", "/health"], (req, res) => res.json({ok: true}));

  async function signedInUid(req) {
    const header = req.get("authorization") || "";
    const match = header.match(/^Bearer (.+)$/);
    if (!match) throw new HttpError(401, "Missing sign-in token");
    try {
      return (await auth.verifyIdToken(match[1])).uid;
    } catch (e) {
      throw new HttpError(401, "Invalid sign-in token");
    }
  }

  // Marks a doc as notified exactly once; returns its data, or null if it was
  // already notified. `check` throws HttpError if the caller may not notify.
  async function claimOnce(ref, check) {
    return db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (!snap.exists) throw new HttpError(404, "Not found");
      const data = snap.data();
      check(data);
      if (data.notified === true) return null;
      tx.update(ref, {notified: true});
      return data;
    });
  }

  // Body: {messageId, receiverId}. Uses the receiver's copy, which has the
  // same id as the sender's (see ChatFirebaseMethods.addMessagetoDb).
  app.post("/notify/message", async (req, res) => {
    const uid = await signedInUid(req);
    const {messageId, receiverId} = req.body || {};
    if (!isId(messageId) || !isId(receiverId)) throw new HttpError(400, "messageId and receiverId are required");

    const ref = db.collection("messages").doc(receiverId).collection(uid).doc(messageId);
    const msg = await claimOnce(ref, (data) => {
      if (data.senderId !== uid || data.receiverId !== receiverId) throw new HttpError(403, "Not your message");
    });
    if (!msg) return res.json({sent: false, reason: "already notified"});

    // Name comes from the sender's profile, not the request, so it can't be faked.
    const senderSnap = await db.collection("Users").doc(uid).get();
    const {body, image} = describeMessage(msg);
    const sent = await sendToUser(deps, receiverId, {
      title: senderSnap.get("name") || "New message",
      body,
      image,
      channelId: "message_channel",
      data: {type: "message", senderId: uid},
    });
    res.json({sent});
  });

  // Body: {receiverId}. Rings the receiver for the call the signed-in user
  // just started (their Call doc, has_dialled == false).
  app.post("/notify/call", async (req, res) => {
    const uid = await signedInUid(req);
    const {receiverId} = req.body || {};
    if (!isId(receiverId)) throw new HttpError(400, "receiverId is required");

    const ref = db.collection("Call").doc(receiverId);
    const call = await claimOnce(ref, (data) => {
      if (data.caller_id !== uid || data.has_dialled !== false) throw new HttpError(403, "Not your call");
    });
    if (!call) return res.json({sent: false, reason: "already notified"});

    const callerSnap = await db.collection("Users").doc(uid).get();
    // The app's background handler shows the call screen when the title is "Incoming Call".
    const sent = await sendToUser(deps, receiverId, {
      title: "Incoming Call",
      body: callerSnap.get("name") || "Someone is calling",
      image: callerSnap.get("profile_photo"),
      channelId: "call_channel",
      data: {type: "call", callType: String(call.callType || ""), callerId: uid},
    });
    res.json({sent});
  });

  // eslint-disable-next-line no-unused-vars
  app.use((err, req, res, next) => {
    if (err instanceof HttpError) return res.status(err.status).json({error: err.message});
    logger.error(err);
    res.status(500).json({error: "Something went wrong"});
  });

  return app;
}

module.exports = {createApp};
