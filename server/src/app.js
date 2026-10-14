// HTTP API the app calls after sending a message or starting a call. The app
// never holds Firebase's messaging credentials; this server does.
//
// Every request carries the user's Firebase ID token. The server only sends a
// notification for a message/call that exists, was created by that user, and
// hasn't been notified yet, so the endpoint can't be used to spam people.

const express = require("express");
const {RtcTokenBuilder, RtcRole} = require("agora-token");
const {describeMessage, sendToUser, unreadTotal} = require("./notifications");

// Agora project the app's calls use (lib/resources/agora_call_session.dart).
// The certificate is secret: set AGORA_APP_CERTIFICATE on Vercel.
const AGORA_APP_ID = "4e3d9239cb394c08beae2ed37754bf1d";
// A call pass is good for this long; ongoing calls aren't cut off when it
// runs out, it only stops new joins.
const AGORA_TOKEN_SECONDS = 2 * 60 * 60;

class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

function isId(value) {
  return typeof value === "string" && /^[A-Za-z0-9_-]{1,128}$/.test(value);
}

function createApp({db, auth, messaging, logger = console, agoraCertificate = process.env.AGORA_APP_CERTIFICATE}) {
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

    // Name comes from the sender's profile, not the request, so it can't be
    // faked. The three reads don't depend on each other: run them together.
    const [senderSnap, receiverSnap, badge] = await Promise.all([
      db.collection("Users").doc(uid).get(),
      db.collection("Users").doc(receiverId).get(),
      unreadTotal(db, receiverId),
    ]);
    const {body, image} = describeMessage(msg);
    const sent = await sendToUser(deps, receiverId, {
      title: senderSnap.get("name") || "New message",
      body,
      image,
      avatar: senderSnap.get("profile_photo"),
      channelId: "message_channel",
      // messageId lets the receiver's phone mark it delivered (two grey
      // ticks) even while the app is closed.
      data: {type: "message", senderId: uid, messageId},
      badge,
      userSnap: receiverSnap,
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

    const [callerSnap, receiverSnap] = await Promise.all([
      db.collection("Users").doc(uid).get(),
      db.collection("Users").doc(receiverId).get(),
    ]);
    const callerName = callerSnap.get("name") || "Someone";
    const video = call.callType === "videoCall";
    const sent = await sendToUser(deps, receiverId, {
      title: callerName,
      body: video ? "Incoming video call" : "Incoming voice call",
      avatar: callerSnap.get("profile_photo"),
      channelId: "call_channel",
      data: {type: "call", callType: String(call.callType || ""), callerId: uid, senderId: uid},
      userSnap: receiverSnap,
    });
    res.json({sent});
  });

  // Body: {channelId}. The pass to join a call's Agora channel. Only for
  // someone in that call: their own Call doc must name this channel (the
  // caller and the receiver each have one). Replaces the old token server on
  // Render, which was slow to wake up and gave a pass to anyone who asked.
  app.post("/agora/token", async (req, res) => {
    const uid = await signedInUid(req);
    const {channelId} = req.body || {};
    if (!isId(channelId)) throw new HttpError(400, "channelId is required");
    if (!agoraCertificate) throw new HttpError(503, "Calls aren't set up on the server");

    const call = await db.collection("Call").doc(uid).get();
    if (!call.exists || call.get("channel_id") !== channelId) throw new HttpError(403, "Not your call");

    const token = RtcTokenBuilder.buildTokenWithUid(
        AGORA_APP_ID, agoraCertificate, channelId, 0, RtcRole.PUBLISHER, AGORA_TOKEN_SECONDS, AGORA_TOKEN_SECONDS);
    res.json({token});
  });

  // Lets the signed-in user upload files to Supabase Storage, which trusts
  // Firebase sign-in tokens only when they carry role = "authenticated".
  // Adds that claim once (keeping any others); the app then refreshes its
  // token.
  app.post("/supabase/role", async (req, res) => {
    const uid = await signedInUid(req);
    const user = await auth.getUser(uid);
    const claims = user.customClaims || {};
    if (claims.role !== "authenticated") {
      await auth.setCustomUserClaims(uid, {...claims, role: "authenticated"});
    }
    res.json({ok: true});
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
