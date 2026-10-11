import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:echat/providers/user_provider.dart';
import 'package:echat/resources/auth_methods.dart';
import 'package:echat/resources/repositories/log_repository.dart';
import 'package:echat/screens/call/pickup_layout.dart';
import 'package:echat/screens/call_logs/call_logs_screen.dart';
import 'package:echat/screens/chat_list/chat_list_screen.dart';
import 'package:echat/screens/available_users.dart';
import 'package:echat/widgets/new_user_details.dart';
import 'package:echat/enums/user_state.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:echat/screens/contact_page.dart';
import 'package:echat/utils/universal_variables.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>  with WidgetsBindingObserver{
  late UserProvider userProvider;
  AuthMethods authMethods = AuthMethods();
  bool _disposed = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initializeUser();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
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
              debugPrint("Call Accepted");
            }else if(receivedAction.buttonKeyPressed == "Reject"){
              debugPrint("Call Rejected");
            }else if(receivedAction.buttonKeyPressed == "Reply"){
              debugPrint("Message replied");
            }else{
              await AwesomeNotifications().dismiss(receivedAction.id!);
              debugPrint("Clicked on notification");
            }
          });
    });
  }

  Future<void> initializeUser() async {
    await Future.delayed(Duration.zero); // This ensures that the context is available
    if (_disposed || !mounted) return;
    userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.refreshUser();
    if (_disposed) return;
    if (userProvider.getUser != null) {
      authMethods.setUserState(userId: userProvider.getUser!.uid, userState: UserState.online);
      LogRepository.initialize(isHive: true,dbName: userProvider.getUser!.uid);
      debugPrint('${userProvider.getUser!.state}');

    } else {
      debugPrint('User is null');
    }
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_disposed) {
      // Re-initialize user when app is resumed, if the state is not disposed
      initializeUser();
    }
    String currentUserid = (userProvider.getUser != null)?userProvider.getUser!.uid : "";
    // TODO: implement didChangeAppLifecycleState
    super.didChangeAppLifecycleState(state);
    switch(state){
      case AppLifecycleState.resumed:
        authMethods.setUserState(userId: currentUserid, userState: UserState.online);
            break;
      case AppLifecycleState.inactive:
        authMethods.setUserState(userId: currentUserid, userState: UserState.offline);
        break;
      case AppLifecycleState.paused:
        authMethods.setUserState(userId: currentUserid, userState: UserState.waiting);
        break;
      case AppLifecycleState.detached:
        authMethods.setUserState(userId: currentUserid, userState: UserState.waiting);
        break;
      case AppLifecycleState.hidden:
        // TODO: Handle this case.
    }
  }
  int page = 0;
  GlobalKey<CurvedNavigationBarState> bottomNavigationKey = GlobalKey(); // The GlobalKey class is commonly used in Flutter to provide access to the state of a widget from outside of the widget itself.

  @override
  Widget build(BuildContext context) {
    return PickupLayout(
      scaffold: Scaffold(
          backgroundColor: Colors.grey,
          bottomNavigationBar: CurvedNavigationBar(
            key: bottomNavigationKey,
            index: 0,
            items: const [
              Icon(Icons.chat),
              Icon(Icons.call),
              Icon(Icons.person_search),
              Icon(Icons.contacts),
              Icon(Icons.person)
            ],
            height: 60,
            color: Colors.white,
            buttonBackgroundColor: Colors.white,
            backgroundColor: UniversalVariables.appThemeColor,
            animationCurve: Curves.easeInOut,
            animationDuration: Duration(milliseconds: 300),
            onTap: (index) {
              setState(() {
                page = index;
              });
            },
            letIndexChange: (index) => true,
          ),
          body: getPage(page),
        ),
    );
  }
}

getPage(int page) {
  switch (page) {
    case 0:
      return ChatListScreen();
    case 1:
      return CallLogsScreen();
    case 2:
      return AvailableUsers();
    case 3:
      return ContactPage();
    case 4:
      return NewUserDetails();
  }
}
