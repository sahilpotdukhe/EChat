import fs from "node:fs";
import {initializeTestEnvironment, assertSucceeds, assertFails} from "@firebase/rules-unit-testing";
import {doc, getDoc, setDoc, updateDoc, deleteDoc, addDoc, collection, getDocs, Timestamp, writeBatch, serverTimestamp, increment} from "firebase/firestore";
import {ref, uploadBytes, getBytes} from "firebase/storage";

const ROOT = new URL("..", import.meta.url).pathname;
const env = await initializeTestEnvironment({
  projectId: "demo-echat",
  firestore: {rules: fs.readFileSync(`${ROOT}/firestore.rules`, "utf8"), host: "127.0.0.1", port: 8080},
  storage: {rules: fs.readFileSync(`${ROOT}/storage.rules`, "utf8"), host: "127.0.0.1", port: 9199},
});

const alice = env.authenticatedContext("alice").firestore();
const bob = env.authenticatedContext("bob").firestore();
const eve = env.authenticatedContext("eve").firestore();
const anon = env.unauthenticatedContext().firestore();

let pass = 0, fail = 0;
async function t(name, p) {
  try { await p; pass++; console.log("  ok  ", name); }
  catch (e) { fail++; console.log("  FAIL", name, "-", e.message.split("\n")[0]); }
}

const msg = (from, to) => ({senderId: from, receiverId: to, type: "text", message: "hi", timestamp: Timestamp.now(),
  photoUrl: "", videoUrl: "", thumbnailUrl: "", pdfUrl: "", pdfName: ""});
const call = (from, to, dialled, extra = {}) => ({caller_id: from, caller_name: "A", caller_pic: "", receiver_id: to,
  receiver_name: "B", receiver_pic: "", channel_id: "x", has_dialled: dialled, callType: "audioCall", ...extra});
// Same as makeCall: both docs in one batch, created_at set by the server.
const dial = (db, from, to, channel) => {
  const b = writeBatch(db);
  const extra = {channel_id: channel, created_at: serverTimestamp(), accepted: false};
  b.set(doc(db, `Call/${from}`), call(from, to, true, extra));
  b.set(doc(db, `Call/${to}`), call(from, to, false, extra));
  return b.commit();
};
// Put docs in place directly, as if written earlier.
const seed = (docs) => env.withSecurityRulesDisabled(async (ctx) => {
  for (const [path, data] of Object.entries(docs)) await setDoc(doc(ctx.firestore(), path), data);
});
const clearCalls = () => env.withSecurityRulesDisabled(async (ctx) => {
  for (const u of ["alice", "bob", "eve"]) await deleteDoc(doc(ctx.firestore(), `Call/${u}`));
});
const ago = (ms) => Timestamp.fromMillis(Date.now() - ms);
const MIN = 60 * 1000, HOUR = 60 * MIN;

console.log("Users");
await t("alice creates own profile", assertSucceeds(setDoc(doc(alice, "Users/alice"), {uid: "alice", name: "A", email: "a@x"})));
await t("bob creates own profile", assertSucceeds(setDoc(doc(bob, "Users/bob"), {uid: "bob", name: "B"})));
await t("alice updates own token", assertSucceeds(updateDoc(doc(alice, "Users/alice"), {notification_token: "t"})));
await t("alice sets state (online)", assertSucceeds(updateDoc(doc(alice, "Users/alice"), {state: 1})));
await t("eve CANNOT edit alice", assertFails(updateDoc(doc(eve, "Users/alice"), {name: "hacked"})));
await t("alice CANNOT change her uid", assertFails(updateDoc(doc(alice, "Users/alice"), {uid: "bob"})));
await t("signed-in user lists users (search)", assertSucceeds(getDocs(collection(eve, "Users"))));
await t("signed-out CANNOT list users", assertFails(getDocs(collection(anon, "Users"))));

console.log("Messages (alice -> bob, same as addMessagetoDb)");
await t("alice writes her copy", assertSucceeds(addDoc(collection(alice, "messages/alice/bob"), msg("alice", "bob"))));
await t("alice writes bob's copy", assertSucceeds(addDoc(collection(alice, "messages/bob/alice"), msg("alice", "bob"))));
await t("bob reads his chat", assertSucceeds(getDocs(collection(bob, "messages/bob/alice"))));
await t("alice reads her chat", assertSucceeds(getDocs(collection(alice, "messages/alice/bob"))));
await t("eve CANNOT read bob's chat", assertFails(getDocs(collection(eve, "messages/bob/alice"))));
await t("eve CANNOT fake a message from alice", assertFails(addDoc(collection(eve, "messages/bob/alice"), msg("alice", "bob"))));
await t("eve CANNOT drop into a chat she isn't in", assertFails(addDoc(collection(eve, "messages/bob/alice"), msg("eve", "bob"))));
await t("eve CANNOT write to bob's chat with alice", assertFails(addDoc(collection(eve, "messages/bob/eve2"), msg("eve", "bob"))));
await t("eve CAN start her own chat with bob", assertSucceeds(addDoc(collection(eve, "messages/bob/eve"), msg("eve", "bob"))));
await t("signed-out CANNOT send", assertFails(addDoc(collection(anon, "messages/bob/alice"), msg("alice", "bob"))));

console.log("Contacts (same as addToContacts)");
await t("alice checks her contact doc", assertSucceeds(getDoc(doc(alice, "Users/alice/Contacts/bob"))));
await t("alice checks bob's contact doc for her", assertSucceeds(getDoc(doc(alice, "Users/bob/Contacts/alice"))));
await t("alice adds bob to her list", assertSucceeds(setDoc(doc(alice, "Users/alice/Contacts/bob"), {contact_id: "bob", added_on: Timestamp.now()})));
await t("alice adds herself to bob's list", assertSucceeds(setDoc(doc(alice, "Users/bob/Contacts/alice"), {contact_id: "alice", added_on: Timestamp.now()})));
await t("bob lists his contacts", assertSucceeds(getDocs(collection(bob, "Users/bob/Contacts"))));
await t("eve CANNOT list bob's contacts", assertFails(getDocs(collection(eve, "Users/bob/Contacts"))));
await t("eve CANNOT add alice into bob's list", assertFails(setDoc(doc(eve, "Users/bob/Contacts/alice"), {contact_id: "alice"})));

console.log("Calls (same as makeCall / endCall)");
await t("alice calls bob (batch, both docs)", assertSucceeds(dial(alice, "alice", "bob", "c1")));
await t("bob reads his call doc", assertSucceeds(getDoc(doc(bob, "Call/bob"))));
await t("eve CANNOT read bob's call (room id)", assertFails(getDoc(doc(eve, "Call/bob"))));
await t("eve CANNOT fake a call from alice", assertFails(setDoc(doc(eve, "Call/bob"), call("alice", "bob", false))));
await t("alice re-writes the same call", assertSucceeds(dial(alice, "alice", "bob", "c1")));
await t("eve CANNOT call bob while he's ringing (busy)", assertFails(dial(eve, "eve", "bob", "c2")));
await t("eve CANNOT mark alice's call accepted", assertFails(updateDoc(doc(eve, "Call/bob"), {accepted: true})));
await t("bob CANNOT change other fields while accepting", assertFails(updateDoc(doc(bob, "Call/bob"), {accepted: true, channel_id: "evil"})));
await t("bob marks his doc accepted", assertSucceeds(updateDoc(doc(bob, "Call/bob"), {accepted: true})));
await t("bob marks alice's doc accepted", assertSucceeds(updateDoc(doc(bob, "Call/alice"), {accepted: true})));
await t("eve CANNOT call bob during his call (busy)", assertFails(dial(eve, "eve", "bob", "c2")));
await t("eve CANNOT hang up alice's call", assertFails(deleteDoc(doc(eve, "Call/alice"))));
await t("bob (receiver) hangs up caller's doc", assertSucceeds(deleteDoc(doc(bob, "Call/alice"))));
await t("bob hangs up his own doc", assertSucceeds(deleteDoc(doc(bob, "Call/bob"))));
await t("deleting an already-gone doc is fine", assertSucceeds(deleteDoc(doc(alice, "Call/bob"))));

await clearCalls();
await t("eve calls bob", assertSucceeds(dial(eve, "eve", "bob", "c3")));
await t("alice CANNOT call bob, eve's call is fresh (busy)", assertFails(dial(alice, "alice", "bob", "c4")));
await t("bob CANNOT call alice while he's ringing (busy)", assertFails(dial(bob, "bob", "alice", "c5")));

await clearCalls();
await seed({"Call/bob": call("eve", "bob", false, {channel_id: "old", created_at: ago(2 * MIN), accepted: false})});
await t("unanswered call 2 min old can be overwritten", assertSucceeds(dial(alice, "alice", "bob", "c6")));

await clearCalls();
await seed({"Call/bob": call("eve", "bob", false, {channel_id: "old"})});
await t("old-app call doc (no created_at) can be overwritten", assertSucceeds(dial(alice, "alice", "bob", "c7")));

await clearCalls();
await seed({"Call/bob": call("eve", "bob", false, {channel_id: "old", created_at: ago(2 * MIN), accepted: true})});
await t("accepted call 2 min old CANNOT be overwritten", assertFails(dial(alice, "alice", "bob", "c8")));

await clearCalls();
await seed({"Call/bob": call("eve", "bob", false, {channel_id: "old", created_at: ago(5 * HOUR), accepted: true})});
await t("accepted call 5 h old can be overwritten", assertSucceeds(dial(alice, "alice", "bob", "c9")));
await clearCalls();

console.log("Chat list rows (same as addMessagetoDb, merged)");
const bump = (db, owner, peer) => setDoc(doc(db, `Users/${owner}/Contacts/${peer}`),
  {contact_id: peer, last_message_at: Timestamp.now(), unread_count: increment(1)}, {merge: true});
await seed({"Users/carol/Contacts/alice": {contact_id: "alice", unread_count: 2}});
await t("alice bumps carol's unread count by one", assertSucceeds(bump(alice, "carol", "alice")));
await t("alice CANNOT jump carol's unread count", assertFails(updateDoc(doc(alice, "Users/carol/Contacts/alice"), {unread_count: 50})));
await t("alice CANNOT zero carol's unread count", assertFails(updateDoc(doc(alice, "Users/carol/Contacts/alice"), {unread_count: 0})));
await t("carol clears her own unread count", assertSucceeds(updateDoc(doc(env.authenticatedContext("carol").firestore(), "Users/carol/Contacts/alice"), {unread_count: 0})));
await t("alice creates a new row for dave with 1 unread", assertSucceeds(bump(alice, "dave", "alice")));
await t("eve CANNOT bump alice's row about bob", assertFails(bump(eve, "alice", "bob")));
await t("eve CANNOT change the id in her row", assertFails(setDoc(doc(eve, "Users/eve/Contacts/bob"), {contact_id: "alice"})));

console.log("Ticks");
const tickMsg = (status) => ({...msg("alice", "bob"), status});
await seed({"messages/alice/bob/m1": tickMsg("sent"), "messages/bob/alice/m1": tickMsg("sent")});
await t("bob marks alice's copy delivered", assertSucceeds(updateDoc(doc(bob, "messages/alice/bob/m1"), {status: "delivered"})));
await t("bob marks his copy read", assertSucceeds(updateDoc(doc(bob, "messages/bob/alice/m1"), {status: "read"})));
await t("bob marks alice's copy read", assertSucceeds(updateDoc(doc(bob, "messages/alice/bob/m1"), {status: "read"})));
await t("ticks CANNOT go backwards (read -> delivered)", assertFails(updateDoc(doc(bob, "messages/alice/bob/m1"), {status: "delivered"})));
await seed({"messages/alice/bob/m2": tickMsg("sent")});
await t("the sender CANNOT tick her own message", assertFails(updateDoc(doc(alice, "messages/alice/bob/m2"), {status: "read"})));
await t("bob CANNOT edit the text while ticking", assertFails(updateDoc(doc(bob, "messages/alice/bob/m2"), {status: "read", message: "changed"})));
await t("eve CANNOT tick alice and bob's message", assertFails(updateDoc(doc(eve, "messages/alice/bob/m2"), {status: "read"})));
await t("a new message CANNOT start as read", assertFails(addDoc(collection(alice, "messages/alice/bob"), tickMsg("read"))));

console.log("Deleting");
const wipe = {type: "deleted", message: "", photoUrl: "", videoUrl: "", thumbnailUrl: "", pdfUrl: "", pdfName: "", fileName: ""};
await seed({"messages/alice/bob/m3": msg("alice", "bob"), "messages/bob/alice/m3": msg("alice", "bob")});
await t("alice deletes her message for everyone (her copy)", assertSucceeds(updateDoc(doc(alice, "messages/alice/bob/m3"), wipe)));
await t("alice deletes her message for everyone (bob's copy)", assertSucceeds(updateDoc(doc(alice, "messages/bob/alice/m3"), wipe)));
await seed({"messages/bob/alice/m4": msg("alice", "bob")});
await t("bob CANNOT delete alice's message for everyone", assertFails(updateDoc(doc(bob, "messages/bob/alice/m4"), wipe)));
await t("alice CANNOT rewrite her sent message", assertFails(updateDoc(doc(alice, "messages/bob/alice/m4"), {message: "edited"})));
await t("bob deletes a message for himself", assertSucceeds(deleteDoc(doc(bob, "messages/bob/alice/m4"))));
await seed({"messages/bob/alice/m5": msg("alice", "bob")});
await t("alice lists bob's side of their chat (delete for everyone)", assertSucceeds(getDocs(collection(alice, "messages/bob/alice"))));
await t("alice deletes bob's copy (delete chat for everyone)", assertSucceeds(deleteDoc(doc(alice, "messages/bob/alice/m5"))));
await t("eve CANNOT list alice and bob's chat", assertFails(getDocs(collection(eve, "messages/alice/bob"))));
await t("eve CANNOT delete from alice and bob's chat", assertFails(deleteDoc(doc(eve, "messages/alice/bob/m1"))));
await t("alice removes herself from bob's list", assertSucceeds(deleteDoc(doc(alice, "Users/bob/Contacts/alice"))));
await t("eve CANNOT remove alice from bob's list", assertFails(deleteDoc(doc(eve, "Users/bob/Contacts/alice"))));
await t("alice updates her last_seen", assertSucceeds(updateDoc(doc(alice, "Users/alice"), {state: 1, last_seen: serverTimestamp()})));

console.log("Everything else");
await t("unknown collection is closed", assertFails(setDoc(doc(alice, "Other/x"), {a: 1})));

console.log("Storage");
const aS = env.authenticatedContext("alice").storage();
const eS = env.authenticatedContext("eve").storage();
const img = new Uint8Array([1, 2, 3]);
await t("alice uploads to her Media folder", assertSucceeds(uploadBytes(ref(aS, "Media/alice/1_cv.pdf"), img, {contentType: "application/pdf"})));
await t("eve CANNOT upload into alice's folder", assertFails(uploadBytes(ref(eS, "Media/alice/1_cv.pdf"), img)));
await t("old root-level path is closed", assertFails(uploadBytes(ref(aS, "cv.pdf"), img)));
await t("alice uploads a thumbnail", assertSucceeds(uploadBytes(ref(aS, "thumbnails/alice/1.jpg"), img, {contentType: "image/jpeg"})));
await t("thumbnail must be an image", assertFails(uploadBytes(ref(aS, "thumbnails/alice/1.jpg"), img, {contentType: "application/pdf"})));
await t("alice uploads profile pic", assertSucceeds(uploadBytes(ref(aS, "Users/alice/1.jpg"), img, {contentType: "image/jpeg"})));
await t("eve reads a shared file", assertSucceeds(getBytes(ref(eS, "Media/alice/1_cv.pdf"))));
await t("101 MB file is refused", assertFails(uploadBytes(ref(aS, "Media/alice/big.mp4"), new Uint8Array(101 * 1024 * 1024))));

console.log(`\n${pass} passed, ${fail} failed`);
await env.cleanup();
process.exit(fail ? 1 : 0);
