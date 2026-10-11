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
  if (IMAGE_TYPES.has(type)) return {body: "📷 Photo", image: msg.photoUrl};
  if (VIDEO_TYPES.has(type)) return {body: "🎥 Video", image: msg.thumbnailUrl};
  if (type === "pdf") return {body: `📄 ${msg.pdfName || msg.fileName || "PDF"}`};
  return {body: `📎 ${msg.fileName || "File"}`};
}

function isHttpUrl(value) {
  return typeof value === "string" && value.startsWith("https://");
}

// Sends one notification to a user's saved device token. Returns true if sent.
async function sendToUser({db, messaging, logger = console}, uid, {title, body, image, channelId, data}) {
  const userSnap = await db.collection("Users").doc(uid).get();
  const token = userSnap.get("notification_token");
  if (!token) return false;

  const notification = {title, body};
  if (isHttpUrl(image)) notification.imageUrl = image;

  try {
    await messaging.send({
      token,
      notification,
      data,
      android: {priority: "high", notification: {channelId}},
      apns: {payload: {aps: {sound: "default"}}},
    });
    return true;
  } catch (err) {
    if (!DEAD_TOKEN_CODES.has(err.code)) throw err;
    // Only clear the token if the user hasn't saved a new one since we read it.
    await userSnap.ref
        .update({notification_token: ""}, {lastUpdateTime: userSnap.updateTime})
        .catch((e) => logger.info(`Token for ${uid} changed meanwhile, kept it: ${e.message}`));
    return false;
  }
}

module.exports = {describeMessage, sendToUser};
