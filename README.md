<div align="center">
  <img src="docs/images/echat_banner.png" alt="EChat" width="420">

  <p><b>Chat, share and call: a fast, private messenger built with Flutter.</b></p>

  <img src="https://img.shields.io/badge/Flutter-3-02569B?logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore%20%7C%20FCM-FFCA28?logo=firebase&logoColor=black" alt="Firebase">
  <img src="https://img.shields.io/badge/Agora-voice%20%26%20video-099DFD" alt="Agora">
  <img src="https://img.shields.io/badge/platform-Android%20%7C%20iOS-6C5CE7" alt="Android and iOS">
</div>

---

### 🎥 Demo
<p align="center">
  <img src="docs/images/echat_demo.gif" alt="EChat demo" width="320" />
</p>

### 🔰 About
**EChat** is a chat app for Android and iPhone. Send messages, photos, videos and files, see when they're delivered and read, and jump into a voice or video call, all in a clean light or dark design that also adapts to tablets.

- Real-time chat on **Firebase Firestore**, with media kept in **Supabase Storage** (photos and videos are compressed before upload).
- One-to-one **voice and video calls** with **Agora**, with a full-screen incoming-call screen that rings.
- **Push notifications** with quick actions: reply or mark as read from the notification, and answer or decline calls. A small **Node.js server on Vercel** sends them and issues call tokens.
- Sign in with **email** or **Google**.

---
### ✨ Features
- **Messaging:** text, photos, videos, PDFs and any other file, with an in-app PDF viewer and video player.
- **Message status:** 🕓 waiting to send, ✓ sent, ✓✓ delivered, blue ✓✓ read.
- **"typing…" indicator** and a reliable **online dot / last seen**.
- **Voice and video calls:** mute, camera on/off, switch camera, speaker. Calls show up in the chat ("Video call · 1 min", "Missed call").
- **Call history** with an *All / Missed* filter.
- **Unread badges** on each chat, the Chats tab and the app icon.
- **Delete** a message or a whole chat, for you or for everyone.
- **People search** by name or username, and **contacts**: see which of your contacts use EChat and invite the rest by SMS (contacts are never uploaded).
- **Profile editing** with a profile picture.
- **Light, dark or system theme**, and a layout that adapts to tablets.
- **Offline friendly:** a "No internet" banner, and messages send once you're back online.

---
### 📱 Screenshots

<table align="center">
  <tr>
    <td align="center"><img src="docs/images/screenshots/onboarding.png" alt="Onboarding" width="220"><br><sub>Onboarding</sub></td>
    <td align="center"><img src="docs/images/screenshots/sign_in.png" alt="Sign in" width="220"><br><sub>Sign in</sub></td>
    <td align="center"><img src="docs/images/screenshots/chats.png" alt="Chats" width="220"><br><sub>Chats</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/images/screenshots/conversation.png" alt="Conversation" width="220"><br><sub>Conversation</sub></td>
    <td align="center"><img src="docs/images/screenshots/people.png" alt="People search" width="220"><br><sub>People search</sub></td>
    <td align="center"><img src="docs/images/screenshots/profile.png" alt="Profile & theme" width="220"><br><sub>Profile & theme</sub></td>
  </tr>
</table>

<p align="center"><b>Dark mode</b></p>
<table align="center">
  <tr>
    <td align="center"><img src="docs/images/screenshots/chats_dark.png" alt="Chats" width="220"><br><sub>Chats</sub></td>
    <td align="center"><img src="docs/images/screenshots/conversation_dark.png" alt="Conversation" width="220"><br><sub>Conversation</sub></td>
    <td align="center"><img src="docs/images/screenshots/profile_dark.png" alt="Profile" width="220"><br><sub>Profile</sub></td>
  </tr>
</table>

<p align="center"><b>Calls</b></p>
<table align="center">
  <tr>
    <td align="center"><img src="docs/images/pickup_screen.png" alt="Incoming call" width="220"><br><sub>Incoming call</sub></td>
    <td align="center"><img src="docs/images/videocall.png" alt="Video call" width="220"><br><sub>Video call</sub></td>
  </tr>
</table>

---
### 🛠 Built with
- <img src="https://user-images.githubusercontent.com/25181517/186150365-da1eccce-6201-487c-8649-45e9e99435fd.png" alt="Flutter" width="20" height="20"> **Flutter** (Dart): one app for Android and iOS
- <img src="https://user-images.githubusercontent.com/25181517/189716855-2c69ca7a-5149-4647-936d-780610911353.png" alt="Firebase" width="20" height="20"> **Firebase**: Authentication, Firestore, Cloud Messaging
- <img src="https://supabase.com/favicon/favicon-32x32.png" alt="Supabase" width="20" height="20"> **Supabase Storage**: photos, videos, files and profile pictures
- <img src="docs/images/agora.png" alt="Agora" width="20" height="20"> **Agora**: voice and video calls
- <img src="https://assets.vercel.com/image/upload/front/favicon/vercel/32x32.png" alt="Vercel" width="20" height="20"> **Node.js on Vercel**: push notifications and call tokens (`server/`)
- <img src="docs/images/provider.svg" alt="Provider" width="20" height="20"> **Provider**: state management
- <img src="docs/images/hive.jpg" alt="Hive" width="20" height="20"> **Hive**: call history stored on the device
- <img src="https://upload.wikimedia.org/wikipedia/commons/3/33/Figma-logo.svg" alt="Figma" width="20" height="20"> **Figma**: UI design

---
### 🗂 Project structure
```text
lib/
├── main.dart            app start-up, theme and routing
├── screens/             chat list, chat, calls, people, contacts, sign in / sign up
├── widgets/             shared UI (avatars, PDF viewer, video player, …)
├── resources/           Firebase, Agora, Supabase, notifications, presence
├── models/              user, message, call and call-log data
├── providers/           app state (Provider)
├── theme/               light and dark colours
└── utils/               helpers and validators
server/                  notification + call-token server (Vercel)
firestore.rules          database security rules
supabase/                storage setup
test/                    unit and widget tests
```

---
## 🚀 Getting started

1. **Clone the repository**
   ```bash
   git clone https://github.com/sahilpotdukhe/EChat.git
   cd EChat
   ```
2. **Install dependencies**
   ```bash
   flutter pub get
   ```
3. **Run the app** (with an Android emulator, iOS simulator or phone connected)
   ```bash
   flutter run
   ```
4. **Run the tests**
   ```bash
   flutter test
   ```

### 🍎 Running on iPhone

The iOS project is set up already; these one-time steps need your own accounts:

1. Install Xcode from the App Store, then run `sudo xcode-select -s /Applications/Xcode.app` and open Xcode once.
2. In the Firebase console (project `echat-888ef`), add an iOS app with bundle ID `com.sahilpotdukhe.echat` (already done; the file is in the repo), download `GoogleService-Info.plist` and put it in `ios/Runner/`.
3. Copy `REVERSED_CLIENT_ID` from that file into `ios/Runner/Info.plist`, replacing `com.googleusercontent.apps.REPLACE_WITH_REVERSED_CLIENT_ID` (needed for Google Sign-In).
4. Run `cd ios && pod install`, then `flutter run` with a simulator or iPhone connected.

For push notifications on a real iPhone (a paid Apple Developer account is needed):

5. Open `ios/Runner.xcworkspace`, pick your team under **Signing & Capabilities**, and add the **Push Notifications** capability.
6. Create an APNs key at developer.apple.com and upload it in Firebase console > Project settings > Cloud Messaging > Apple app configuration.

### 🗂 File storage (Supabase)

Photos, videos, files and profile pictures are stored in Supabase Storage. See
[docs/SUPABASE_SETUP.md](docs/SUPABASE_SETUP.md) for the one-time setup.

## 📋 Requirements

- Flutter SDK: [Installation Guide](https://docs.flutter.dev/get-started/install)
- Firebase account: [Sign up for Firebase](https://firebase.google.com/)
- Supabase account: [Sign up for Supabase](https://supabase.com/)
- Agora account: [Sign up for Agora](https://www.agora.io/en/)

---
## 🤝 Contributing
Contributions are always welcome! If you have an idea that would make EChat better, fork the repo and open a pull request. And don't forget to give the project a ⭐!

1. Fork the project
2. Create your feature branch: `git checkout -b feature/AmazingFeature`
3. Commit your changes: `git commit -m "Add some AmazingFeature"`
4. Push to the branch: `git push origin feature/AmazingFeature`
5. Open a pull request

---
## ➤ Contact
You can reach out to me via the following methods:

- **Email:**  <img src="https://github.com/SatYu26/SatYu26/blob/master/Assets/Gmail.svg" alt="Gmail" width="20" height="20">&nbsp;&nbsp;<a href="mailto:sahilpotdukhe.ssp@gmail.com">sahilpotdukhe.ssp@gmail.com</a>
- **Social Media:**
   - <img src="https://github.com/SatYu26/SatYu26/blob/master/Assets/Linkedin.svg" alt="Linkedin" width="20" height="20">&nbsp;&nbsp;[LinkedIn](https://www.linkedin.com/in/sahil-potdukhe/)
   - <img src="https://w7.pngwing.com/pngs/914/758/png-transparent-github-social-media-computer-icons-logo-android-github-logo-computer-wallpaper-banner-thumbnail.png" alt="Github" width="20" height="20">&nbsp;&nbsp;[GitHub](https://github.com/sahilpotdukhe)
   - <img src="https://github.com/SatYu26/SatYu26/blob/master/Assets/Instagram.svg" alt="Instagram" width="20" height="20">&nbsp;&nbsp;[Instagram](https://www.instagram.com/sahilpotdukhe11/)
   - <img src="https://github.com/SatYu26/SatYu26/blob/master/Assets/Twitter.svg" alt="Twitter" width="20" height="20">&nbsp;&nbsp;[Twitter](https://twitter.com/SahilPotdukhe)
