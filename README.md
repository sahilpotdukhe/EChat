<!-- Project Title -->
<div align="center" style="display: flex; align-items: center; justify-content: center;">
  <img src="readmeimages/Echatlogoname.png" alt="Echat Logo" width="500" height="300">
</div>

**ECHAT** is a comprehensive chat application created using Flutter, Firebase, Dart, and Figma, offering a seamless communication experience.

### 🎥 Simple demo
<p align="center">
  <img src="echatdemo.gif" alt="EchatDemo" width="350" />
</p>

### 🔰 Project Description
- Created **ECHAT**, a robust chat application, leveraging Flutter, Firebase, Dart, and Figma, to provide users with an all-encompassing communication platform.
- Empowered with real-time messaging capabilities, supporting text, images, videos, and PDFs, facilitating seamless interaction between users.
- Ensured utmost user security and privacy by implementing secure authentication mechanisms via email and Google Integration.
- Integrated advanced voice and video calling functionalities using Agora SDK, allowing users to mute audio, disable video, and terminate calls as needed, enhancing the overall user experience.
- Implemented essential features including user search, profile management, contact inviting, and call/message history, to enhance usability and convenience.
- Optimized app performance through media caching techniques and reliable push notifications using cloud messaging, ensuring smooth and uninterrupted communication experiences.

---
### ➤ Key Features
- **Real-time Messaging**: Instant exchange of text, images, videos, and PDFs.
- **Secure Authentication**: Email and Google Integration for secure login.
- **Voice and Video Calling**: Real-time calls with mute, disable video, and call termination.
- **Optimized Performance**: Enhanced app performance with media caching and reliable push notifications.
- **Contact Invitations**: Invite contacts to join ECHAT for conversations.
- **Profile Editing**: Customize profiles with personal information and pictures.
- **Call Log Management**: View and delete call logs for control.
- **Search Functionality**: Easily discover and connect with other users.|

---
### 🛠 Technologies and Frameworks Used
- <img src="https://upload.wikimedia.org/wikipedia/commons/3/33/Figma-logo.svg" alt="Figma" width="20" height="20"> Figma (for UI design)
- <img src="https://user-images.githubusercontent.com/25181517/186150365-da1eccce-6201-487c-8649-45e9e99435fd.png" alt="Flutter" width="20" height="20"> Flutter Framework (Dart language)
- <img src="https://user-images.githubusercontent.com/25181517/189716855-2c69ca7a-5149-4647-936d-780610911353.png" alt="Firebase" width="20" height="20"> Firebase (for Authentication And Storing Data)
- <img src="readmeimages/provider.svg" alt="Provider" width="20" height="20"> Provider (for state management)
- <img src="readmeimages/agora.png" alt="Agora SDK" width="20" height="20"> Agora SDK (for Video and voice calling)
- <img src="readmeimages/hive.jpg" alt="Hive" width="20" height="20"> Hive (for local storage)
- <img src="https://github.com/marwin1991/profile-technology-icons/assets/136815194/82df4543-236b-4e45-9604-5434e3faab17" alt="SQLite" width="20" height="20"> SQLite (for local storage)

---
## ⚡Usage/Examples

```javascript
import 'package:flutter/material.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

//MyApp
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}
class _MyAppState extends State<MyApp> {
    Widget build(BuildContext context) {
        return MaterialApp(
            home: FutureBuilder(
                    future: authMethods.getCurrentUser(),
                    builder: (context, AsyncSnapshot<User?> snapshot) {
                    if (snapshot.hasData) {
                      return BotttomNavigationBar();
                    } else {
                      return isViewed != 0 ? OnBoardScreens() : Authenticate();
                    }
                  },
                ),
            );
    }
```
---

## 🚀 Installation

1. **Clone the repository:**

   ```bash
   git clone https://github.com/sahilpotdukhe/echat.git
2. **Navigate to the project directory:**
    ```bash
    cd echat
3. **Install dependencies:**
    ```bash
    flutter pub get
4. **Run the app:**
    ```bash
    flutter run

## 📋 Requirements

- Flutter SDK: [Installation Guide](https://flutter.dev/docs/get-started/install)
- Firebase Account: [Sign up for Firebase](https://firebase.google.com/)
- Agora Account: [Sign up for Agora](https://www.agora.io/en/)
- Figma Account: [Sign up for Figma](https://www.figma.com/)

---

## <img src="https://upload.wikimedia.org/wikipedia/commons/3/33/Figma-logo.svg" alt="Figma" width="20" height="20"> App Design

<div align="center">
  <table style="border-collapse: collapse;">
    <tr>
      <td style="padding-right: 0px; border: none;">
        <img src="readmeimages/Onboarding Screen 2.png" alt="Screen 1" width="250">
        <p align="center">OnBoarding Screen</p>
      </td>
      <td style="padding-right: 0px; border: none;">
        <img src="readmeimages/SignUp.png" alt="Screen 2" width="250">
        <p align="center">SignUp Screen</p>
      </td>
      <td style="border: none;">
        <img src="readmeimages/Chats.png" alt="Screen 3" width="250">
        <p align="center">ChatLists Screen</p>
      </td>
    </tr>
  </table>
</div>
<div align="center">
  <table style="border-collapse: collapse;">
    <tr>
      <td style="padding-right: 0px; border: none;">
        <img src="readmeimages/Conversations.png" alt="Screen 1" width="250">
        <p align="center">Conversations Screen</p>
      </td>
      <td style="padding-right: 0px; border: none;">
        <img src="readmeimages/Profilepage.png" alt="Screen 2" width="250">
        <p align="center">Profile Screen</p>
      </td>
      <td style="border: none;">
        <img src="readmeimages/search2.png" alt="Screen 3" width="250">
        <p align="center">Search Screen</p>
      </td>
    </tr>
  </table>
</div>
<div align="center">
  <table style="border-collapse: collapse;">
    <tr>
      <td style="padding-right: 0px; border: none;">
        <img src="readmeimages/Pickup Screen.png" alt="Screen 1" width="250">
        <p align="center">Pickup Screen</p>
      </td>
      <td style="padding-right: 0px; border: none;">
        <img src="readmeimages/videocall.png" alt="Screen 2" width="250">
        <p align="center">VideoCall Screen</p>
      </td>
      <td style="border: none;">
        <img src="readmeimages/call logs.png" alt="Screen 3" width="250">
        <p align="center">CallLogs Screen</p>
      </td>
    </tr>
  </table>
</div>

## 🤝 Contributing
Contributions are always welcome!
If you have a suggestion that would make this better, please fork the repo and create a pull request. Don't forget to give the project a star! Thanks again!
- Fork the Project
- Create your Feature Branch (```bash git checkout -b feature/AmazingFeature```)
- Commit your Changes (```bash git commit -m 'Add some AmazingFeature'```)
- Push to the Branch (```bash git push origin feature/AmazingFeature```)
- Open a Pull Request 


---
## ➤ Contact
You can reach out to me via the following methods:

- **Email:**  <img src="https://github.com/SatYu26/SatYu26/blob/master/Assets/Gmail.svg" alt="Gmail" width="20" height="20">&nbsp;&nbsp;<a href="mailto:sahilpotdukhe.ssp@gmail.com">sahilpotdukhe.ssp@gmail.com
- **Social Media:**
   - <img src="https://github.com/SatYu26/SatYu26/blob/master/Assets/Linkedin.svg" alt="Linkedin" width="20" height="20">&nbsp;&nbsp;[LinkedIn](https://www.linkedin.com/in/sahil-potdukhe/)
   - <img src="https://w7.pngwing.com/pngs/914/758/png-transparent-github-social-media-computer-icons-logo-android-github-logo-computer-wallpaper-banner-thumbnail.png" alt="Github" width="20" height="20">&nbsp;&nbsp;[GitHub](https://github.com/sahilpotdukhe)
   - <img src="https://github.com/SatYu26/SatYu26/blob/master/Assets/Instagram.svg" alt="Instagram" width="20" height="20">&nbsp;&nbsp;[Instagram](https://www.instagram.com/sahilpotdukhe11/)
   - <img src="https://github.com/SatYu26/SatYu26/blob/master/Assets/Twitter.svg" alt="Twitter" width="20" height="20">&nbsp;&nbsp;[Twitter](https://twitter.com/SahilPotdukhe)
  ---

This project underscores the power of modern technologies in creating a feature-rich and secure chat application tailored for today's communication needs.
