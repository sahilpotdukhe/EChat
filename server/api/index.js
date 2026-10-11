// Vercel entry point: every path is rewritten here (see vercel.json) and the
// Express app routes it.

const {createApp} = require("../src/app");
const {firebaseDeps} = require("../src/firebase");

module.exports = createApp(firebaseDeps());
