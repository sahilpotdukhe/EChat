// Sends push notifications from the server, so the app never holds the
// Firebase Cloud Messaging credentials. Runs on Firebase Cloud Functions.

const {onDocumentCreated, onDocumentWritten} = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();

const MAX_BODY_LENGTH = 200;

// Tokens Firebase says are dead (app uninstalled, token expired).
const DEAD_TOKEN_CODES = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
]);

function isHttpUrl(value) {
  return typeof value === "string" && value.startsWith("https://");
}

function truncate(text) {
  if (typeof text !== "string" || text.length === 0) return "New message";
  return text.length > MAX_BODY_LENGTH ? `${text.slice(0, MAX_BODY_LENGTH - 1)}…` : text;
}

// Same groups as lib/Utils/MessageUtils.dart.
const IMAGE_TYPES = new Set(["image", "jpg", "jpeg", "png", "gif", "webp", "heic", "heif", "bmp"]);
const VIDEO_TYPES = new Set(["mp4", "mov", "m4v", "3gp", "webm", "mkv", "avi"]);

// Turns a stored message into the notification body (and optional picture).
function describeMessage(msg) {
  const type = String(msg.type || "").toLowerCase();
  if (type === "text") return {body: truncate(msg.message)};
  if (IMAGE_TYPES.has(type)) return {body: "📷 Photo", image: msg.photoUrl};
  if (VIDEO_TYPES.has(type)) return {body: "🎥 Video", image: msg.thumbnailUrl};
  if (type === "pdf") return {body: `📄 ${msg.pdfName || msg.fileName || "PDF"}`};
  return {body: `📎 ${msg.fileName || "File"}`};
}

async function sendToUser(uid, {title, body, image, channelId, data}) {
  const userSnap = await db.collection("Users").doc(uid).get();
  const token = userSnap.get("notification_token");
  if (!token) return;

  const notification = {title, body};
  if (isHttpUrl(image)) notification.imageUrl = image;

  try {
    await getMessaging().send({
      token,
      notification,
      data,
      android: {priority: "high", notification: {channelId}},
      apns: {payload: {aps: {sound: "default"}}},
    });
  } catch (err) {
    if (!DEAD_TOKEN_CODES.has(err.code)) throw err;
    // Only clear the token if the user hasn't saved a new one since we read it.
    await userSnap.ref
        .update({notification_token: ""}, {lastUpdateTime: userSnap.updateTime})
        .catch((e) => logger.info(`Token for ${uid} changed meanwhile, kept it`, e.message));
  }
}

// Every message is saved twice: messages/{sender}/{receiver}/... and
// messages/{receiver}/{sender}/... Only the receiver's copy sends a notification.
exports.notifyNewMessage = onDocumentCreated("messages/{ownerId}/{peerId}/{messageId}", async (event) => {
  const msg = event.data?.data();
  if (!msg || event.params.ownerId !== msg.receiverId) return;

  // Name comes from the sender's profile, not the message, so it can't be faked.
  const senderSnap = await db.collection("Users").doc(msg.senderId).get();
  const {body, image} = describeMessage(msg);

  await sendToUser(msg.receiverId, {
    title: senderSnap.get("name") || "New message",
    body,
    image,
    channelId: "message_channel",
    data: {type: "message", senderId: String(msg.senderId)},
  });
});

// The receiver's call doc has has_dialled == false. Ring once per new call;
// ignore deletes (hang-ups) and rewrites of the same call.
exports.notifyIncomingCall = onDocumentWritten("Call/{uid}", async (event) => {
  const after = event.data?.after?.data();
  if (!after || after.has_dialled !== false) return;

  const before = event.data.before?.data();
  if (before && before.channel_id === after.channel_id) return;

  const callerSnap = await db.collection("Users").doc(after.caller_id).get();

  // The app's background handler shows the call screen when the title is "Incoming Call".
  await sendToUser(event.params.uid, {
    title: "Incoming Call",
    body: callerSnap.get("name") || "Someone is calling",
    image: callerSnap.get("profile_photo"),
    channelId: "call_channel",
    data: {type: "call", callType: String(after.callType || ""), callerId: String(after.caller_id)},
  });
});
