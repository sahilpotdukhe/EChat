// Builds and sends EChat push notifications with the Firebase Admin SDK.

const MAX_BODY_LENGTH = 200;

// Same groups as lib/utils/message_utils.dart.
const IMAGE_TYPES = new Set(["image", "jpg", "jpeg", "png", "gif", "webp", "heic", "heif", "bmp"]);
const VIDEO_TYPES = new Set(["mp4", "mov", "m4v", "3gp", "webm", "mkv", "avi"]);

// Tokens Firebase says are dead (app uninstalled, token expired, logged out).
const DEAD_TOKEN_CODES = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
]);

function truncate(text) {
  if (typeof text !== "string" || text.length === 0) return "New message";
  return text.length > MAX_BODY_LENGTH ? `${text.slice(0, MAX_BODY_LENGTH - 1)}…` : text;
}

// Turns a stored message into the notification body (and optional picture).
function describeMessage(msg) {
  const type = String(msg.type || "").toLowerCase();
  if (type === "text") return {body: truncate(msg.message)};
  if (type === "call") {
    const kind = msg.callType === "videoCall" ? "video" : "voice";
    return {body: msg.message === "answered" ? `📞 ${kind[0].toUpperCase()}${kind.slice(1)} call` : `📞 Missed ${kind} call`};
  }
  if (IMAGE_TYPES.has(type)) return {body: "📷 Photo", image: msg.photoUrl};
  if (VIDEO_TYPES.has(type)) return {body: "🎥 Video", image: msg.thumbnailUrl};
  if (type === "pdf") return {body: `📄 ${msg.pdfName || msg.fileName || "PDF"}`};
  return {body: `📎 ${msg.fileName || "File"}`};
}

function isHttpUrl(value) {
  return typeof value === "string" && value.startsWith("https://");
}

// Messages waiting to be read across all of a user's chats: the number on
// the app icon. 0 if it can't be worked out.
async function unreadTotal(db, uid) {
  try {
    const snap = await db.collection("Users").doc(uid).collection("Contacts").where("unread_count", ">", 0).get();
    return snap.docs.reduce((sum, d) => sum + (Number(d.get("unread_count")) || 0), 0);
  } catch (e) {
    return 0;
  }
}

// Sends one notification to a user's saved device token. Returns true if sent.
//
// Android gets the details as data only, and the app draws the notification
// itself (sender's photo, stacked messages, Reply / Mark as read, a ringing
// screen for calls), even when it is closed. iPhones need a visible alert in
// the push, so they get a normal notification. [userSnap] may be passed in
// when the caller has already read the receiver's profile.
async function sendToUser({db, messaging, logger = console}, uid, {title, body, image, avatar, channelId, data, badge, userSnap}) {
  const snap = userSnap || await db.collection("Users").doc(uid).get();
  const token = snap.get("notification_token");
  if (!token) return false;
  const isCall = channelId === "call_channel";

  const fields = {...data, title: String(title || ""), body: String(body || ""), badge: String(badge || 0)};
  if (isHttpUrl(image)) fields.image = image;
  if (isHttpUrl(avatar)) fields.avatar = avatar;

  try {
    await messaging.send({
      token,
      data: fields,
      // A call nobody answers within 45 s is over; don't ring later.
      android: {priority: "high", ...(isCall ? {ttl: 45 * 1000} : {})},
      apns: {
        headers: {"apns-priority": "10", ...(isCall ? {"apns-expiration": String(Math.floor(Date.now() / 1000) + 45)} : {})},
        payload: {aps: {alert: {title, body}, sound: "default", "mutable-content": 1, ...(badge ? {badge} : {})}},
        ...(isHttpUrl(image) ? {fcmOptions: {imageUrl: image}} : {}),
      },
    });
    return true;
  } catch (err) {
    if (!DEAD_TOKEN_CODES.has(err.code)) throw err;
    // Only clear the token if the user hasn't saved a new one since we read it.
    await snap.ref
        .update({notification_token: ""}, {lastUpdateTime: snap.updateTime})
        .catch((e) => logger.info(`Token for ${uid} changed meanwhile, kept it: ${e.message}`));
    return false;
  }
}

// Tells a phone to stop showing a ringing call from [callerId]. Silent (data
// only, no alert), so nothing pops up; the app takes the notification down.
// Returns true if sent.
async function sendCallEnded({db, messaging}, uid, callerId) {
  const token = (await db.collection("Users").doc(uid).get()).get("notification_token");
  if (!token) return false;
  try {
    await messaging.send({
      token,
      data: {type: "call_ended", callerId, senderId: callerId},
      // Pointless once the 45 s ring is over anyway.
      android: {priority: "high", ttl: 45 * 1000},
      apns: {headers: {"apns-priority": "5", "apns-push-type": "background"}, payload: {aps: {"content-available": 1}}},
    });
    return true;
  } catch (err) {
    if (DEAD_TOKEN_CODES.has(err.code)) return false;
    throw err;
  }
}

module.exports = {describeMessage, sendCallEnded, sendToUser, unreadTotal};
