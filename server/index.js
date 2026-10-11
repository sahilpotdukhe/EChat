// Runs the notification server locally (`npm start`). In production it runs
// on Vercel through api/index.js instead.
//
// Environment: FIREBASE_SERVICE_ACCOUNT (see src/firebase.js), PORT (default 8080).

const {createApp} = require("./src/app");
const {firebaseDeps} = require("./src/firebase");

const app = createApp(firebaseDeps());
const port = Number(process.env.PORT) || 8080;
app.listen(port, () => console.log(`EChat notification server listening on ${port}`));
