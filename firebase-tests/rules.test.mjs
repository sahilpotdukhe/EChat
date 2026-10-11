import fs from "node:fs";
import {initializeTestEnvironment, assertSucceeds, assertFails} from "@firebase/rules-unit-testing";
import {doc, getDoc, setDoc, updateDoc, deleteDoc, addDoc, collection, getDocs, Timestamp} from "firebase/firestore";
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
const call = (from, to, dialled) => ({caller_id: from, caller_name: "A", caller_pic: "", receiver_id: to,
  receiver_name: "B", receiver_pic: "", channel_id: "x", has_dialled: dialled, callType: "audioCall"});

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
await t("alice writes her call doc", assertSucceeds(setDoc(doc(alice, "Call/alice"), call("alice", "bob", true))));
await t("alice writes bob's call doc", assertSucceeds(setDoc(doc(alice, "Call/bob"), call("alice", "bob", false))));
await t("bob reads his call doc", assertSucceeds(getDoc(doc(bob, "Call/bob"))));
await t("eve CANNOT read bob's call (room id)", assertFails(getDoc(doc(eve, "Call/bob"))));
await t("eve CANNOT fake a call from alice", assertFails(setDoc(doc(eve, "Call/bob"), call("alice", "bob", false))));
await t("eve CANNOT hang up alice's call", assertFails(deleteDoc(doc(eve, "Call/alice"))));
await t("bob (receiver) hangs up caller's doc", assertSucceeds(deleteDoc(doc(bob, "Call/alice"))));
await t("bob hangs up his own doc", assertSucceeds(deleteDoc(doc(bob, "Call/bob"))));
await t("deleting an already-gone doc is fine", assertSucceeds(deleteDoc(doc(alice, "Call/bob"))));

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
