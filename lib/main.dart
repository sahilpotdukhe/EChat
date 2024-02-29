import 'package:echat/Provider/UserProvider.dart';
import 'package:echat/Resources/AuthMethods.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:echat/Provider/ImageUploadProvider.dart';
import 'package:echat/Screens/LoginScreen.dart';
import 'package:echat/Screens/SearchScreen.dart';
import 'package:echat/Widgets/BottomNavigationBar.dart';
import 'package:provider/provider.dart';


void main() async {
  //This line ensures that the Flutter framework is initialized before proceeding further. This is necessary to use Flutter widgets and services.
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();// This line initializes Firebase services asynchronously.

    runApp(MyApp());
  //runApp(const MyApp());
}

class MyApp extends StatefulWidget { // Stateful: appearance can change in response to events or user interactions.
  const MyApp({super.key}); //It is defined as a const constructor, which means it can be used to create compile-time constant objects.

  @override
  State<MyApp> createState() => _MyAppState();
}

//his class is responsible for managing the changing state for the MyApp widget.
class _MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) { // it takes a BuildContext object as a parameter which Flutter uses to locate the position of this widget within the widget tree
    AuthMethods authMethods = AuthMethods();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ImageUploadProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider())
      ],
      child: MaterialApp(
        title: 'ECHAT',
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {'/searchScreen': (context) => SearchScreen()},
        home: FutureBuilder( // Flutter widget used for building UI elements based on asynchronous operations.
          future: authMethods.getCurrentUser(), // It defines the asynchronous operation that the FutureBuilder will wait for. returns User object
          builder: (context, AsyncSnapshot<User?> snapshot) { // snapshot: An AsyncSnapshot object that contains the latest data received from the future. and the snapshot contains data of type User
            if (snapshot.hasData) {
              return BotttomNavigationBar();
            } else {
              return LoginScreen();
            }
          },
        ),
      ),
    );
  }
}

