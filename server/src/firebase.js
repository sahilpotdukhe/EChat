// Firebase Admin setup shared by the Vercel function (api/index.js) and the
// local server (index.js). Runs once per instance; warm Vercel invocations
// reuse it.
//
// FIREBASE_SERVICE_ACCOUNT: the service-account key JSON (as a string), from
// Firebase console > Project settings > Service accounts. Without it (local
// emulators / tests) the app runs against GCLOUD_PROJECT or "demo-echat".

const {initializeApp, cert, getApps} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {initializeFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

let deps;

function firebaseDeps() {
  if (deps) return deps;
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
  const app = getApps()[0] || initializeApp(raw ?
    {credential: cert(JSON.parse(raw))} :
    {projectId: process.env.GCLOUD_PROJECT || "demo-echat"});
  deps = {
    // REST instead of gRPC: much faster cold starts for short-lived functions.
    // Only with real credentials: the emulator doesn't support REST mode.
    db: initializeFirestore(app, raw ? {preferRest: true} : {}),
    auth: getAuth(app),
    messaging: getMessaging(app),
  };
  return deps;
}

module.exports = {firebaseDeps};
