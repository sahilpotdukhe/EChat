import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/Provider/AppLoadingProvider.dart';
import 'package:echat/Provider/UserProvider.dart';
import 'package:echat/Resources/AuthMethods.dart';
import 'package:echat/Screens/OnBoardScreens.dart';
import 'package:echat/Screens/SplashScreen.dart';
import 'package:echat/Utils/UniversalVariables.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:echat/Provider/ImageUploadProvider.dart';
import 'package:echat/Screens/SearchScreen.dart';
import 'package:echat/Widgets/BottomNavigationBar.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

int? isViewed;

Future<void> backgroundHandler(RemoteMessage message) async{
  String? title= message.notification!.title;
  String? body = message.notification!.body;
  if(title == 'Incoming Call'){
    AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 123,
          channelKey: "call_channel",
          title: title,
          body: body,
          category: NotificationCategory.Call,
          wakeUpScreen: true,
          fullScreenIntent: true,
          autoDismissible: false,
          backgroundColor: UniversalVariables.appThemeColor,
          notificationLayout: NotificationLayout.BigPicture,
          largeIcon: 'asset://assets/login.png',
          displayOnForeground: true,
          displayOnBackground: true,
        ),
        actionButtons: [
          NotificationActionButton(key: "Accept", label: "Accept Call",color: Colors.green,autoDismissible: true),
          NotificationActionButton(key: "Reject", label: "Reject Call",color: Colors.red,autoDismissible: true),
        ]
    );
  }else{
    AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 456,
          channelKey: "message_channel",
          title: title,
          body: body,
          category: NotificationCategory.Message,
          wakeUpScreen: true,
          fullScreenIntent: true,
          autoDismissible: false,
          backgroundColor: UniversalVariables.appThemeColor,
          notificationLayout: NotificationLayout.BigPicture,
          largeIcon: 'asset://assets/login.png',
          displayOnForeground: true,
          displayOnBackground: true,
        ),
        actionButtons: [
          NotificationActionButton(key: "Reply", label: "Reply",color: Colors.grey,autoDismissible: true),
          NotificationActionButton(key: "Mark as read", label: "Mark as read",color: Colors.grey,actionType: ActionType.DismissAction),
        ]
    );
  }


  AwesomeNotifications().setListeners(
      onActionReceivedMethod: (receivedAction) async{
        if(receivedAction.buttonKeyPressed == "Accept"){
          print("Call Accepted");
        }else if(receivedAction.buttonKeyPressed == "Reject"){
          print("Call Rejected");
        }else if(receivedAction.buttonKeyPressed == "Reply"){
          print("Message replied");
        }else{
          print("Clicked on notification");
          await AwesomeNotifications().dismiss(receivedAction.id!);
        }

      });
}


void main() async {
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

  //This line ensures that the Flutter framework is initialized before proceeding further. This is necessary to use Flutter widgets and services.
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Future.delayed(Duration(seconds: 3));
  FlutterNativeSplash.remove();
  await Firebase
      .initializeApp(); // This line initializes Firebase services asynchronously.
  SharedPreferences prefs = await SharedPreferences.getInstance();
  isViewed = prefs.getInt("OnBoard");
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
    AuthMethods authMethods = AuthMethods();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ImageUploadProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => GoogleSignInProvider())
      ],
      child: MaterialApp(
        title: 'ECHAT',
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/searchScreen': (context) => SearchScreen()},
        home: FutureBuilder(
          // Flutter widget used for building UI elements based on asynchronous operations.
          future: authMethods.getCurrentUser(),
          // It defines the asynchronous operation that the FutureBuilder will wait for. returns User object
          builder: (context, AsyncSnapshot<User?> snapshot) {
            // snapshot: An AsyncSnapshot object that contains the latest data received from the future. and the snapshot contains data of type User
            if (snapshot.hasData) {
              return BotttomNavigationBar();
            } else {
              return isViewed != 0 ? OnBoardScreens() : Authenticate();
            }
          },
        ),
      ),
    );
  }
}
