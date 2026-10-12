import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:echat/providers/user_provider.dart';
import 'package:echat/resources/auth_methods.dart';
import 'package:echat/resources/local_notifications.dart';
import 'package:echat/screens/on_board_screens.dart';
import 'package:echat/theme/app_colors.dart';
import 'package:echat/theme/app_theme.dart';
import 'package:echat/utils/theme_preference.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:echat/providers/image_upload_provider.dart';
import 'package:echat/screens/search_screen.dart';
import 'package:echat/screens/home_screen.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_kit/shadcn_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

int? isViewed;
bool isSignedIn = false;
ThemeMode savedThemeMode = ThemeMode.system;

// Runs in a separate background isolate, so it must be a top-level function
// kept by the compiler and must set up Firebase itself.
@pragma('vm:entry-point')
Future<void> backgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await LocalNotifications.show(message);
}


void main() async {
  // Must run before any plugin (notifications, Firebase) is used.
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Keep the splash only as long as startup actually takes.
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  AwesomeNotifications().initialize(null, [
    NotificationChannel(
        channelKey: "call_channel",
        channelName: "Call Channel",
        channelDescription: "Channel of Calling",
        defaultColor: Colors.redAccent,
        ledColor: Colors.white,
        importance: NotificationImportance.Max,
        channelShowBadge: true,
        locked: true,
        defaultRingtoneType: DefaultRingtoneType.Ringtone,
        playSound: true,

    ),
    NotificationChannel(
        channelKey: "message_channel",
        channelName: "Message Channel",
        channelDescription: "Channel of Calling",
        defaultColor: Colors.redAccent,
        ledColor: Colors.white,
        importance: NotificationImportance.Max,
        channelShowBadge: true,
        locked: true,
        defaultRingtoneType: DefaultRingtoneType.Notification,
        playSound: true
    )
  ]);
  FirebaseMessaging.onBackgroundMessage(backgroundHandler);

  await Firebase
      .initializeApp(); // This line initializes Firebase services asynchronously.
  SharedPreferences prefs = await SharedPreferences.getInstance();
  isViewed = prefs.getInt("OnBoard");
  savedThemeMode = ThemePreference.read(prefs);
  // Wait for Firebase to restore the saved sign-in while the splash is still
  // up, so a signed-in user goes straight to their chats instead of seeing
  // the login screen flash first.
  isSignedIn = await FirebaseAuth.instance.authStateChanges().first != null;
  FlutterNativeSplash.remove();
  runApp(MyApp());
  //runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  // Stateful: appearance can change in response to events or user interactions.
  const MyApp(
      {super.key}); //It is defined as a const constructor, which means it can be used to create compile-time constant objects.

  @override
  State<MyApp> createState() => _MyAppState();
}

//his class is responsible for managing the changing state for the MyApp widget.
class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    // it takes a BuildContext object as a parameter which Flutter uses to locate the position of this widget within the widget tree
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ImageUploadProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => GoogleSignInProvider())
      ],
      child: ShadcnApp(
        title: 'EChat',
        light: AppColors.shadcnLight,
        dark: AppColors.shadcnDark,
        initialMode: savedThemeMode,
        materialThemeBuilder: AppTheme.build,
        routes: {
          '/searchScreen': (context) => SearchScreen()},
        home: isSignedIn
            ? HomeScreen()
            : isViewed != 0
                ? OnBoardScreens()
                : Authenticate(),
      ),
    );
  }
}
