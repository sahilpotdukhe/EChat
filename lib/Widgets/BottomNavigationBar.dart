import 'package:echat/Provider/UserProvider.dart';
import 'package:echat/Resources/AuthMethods.dart';
import 'package:echat/Resources/Repository/LogRepository.dart';
import 'package:echat/Screens/Call/PickupLayout.dart';
import 'package:echat/Screens/CallLogs/CallLogsScreen.dart';
import 'package:echat/Screens/ChatList/ChatListScreen.dart';
import 'package:echat/enum/UserState.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:echat/Screens/ContactPage.dart';
import 'package:echat/Utils/UniversalVariables.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

class BotttomNavigationBar extends StatefulWidget {
  const BotttomNavigationBar({super.key});

  @override
  State<BotttomNavigationBar> createState() => _BotttomNavigationBarState();
}

class _BotttomNavigationBarState extends State<BotttomNavigationBar>  with WidgetsBindingObserver{
  late UserProvider userProvider;
  AuthMethods authMethods = AuthMethods();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initializeUser();
  }

  Future<void> initializeUser() async {
    await Future.delayed(Duration.zero); // This ensures that the context is available
    userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.refreshUser();
    if (userProvider.getUser != null) {
      authMethods.setUserState(userId: userProvider.getUser!.uid, userState: UserState.Online);
      LogRepository.initialize(isHive: true,dbName: userProvider.getUser!.uid);
      print(userProvider.getUser!.state);
    } else {
      print('User is null');
    }
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    String currentUserid = (userProvider.getUser != null)?userProvider.getUser!.uid : "";
    // TODO: implement didChangeAppLifecycleState
    super.didChangeAppLifecycleState(state);
    switch(state){
      case AppLifecycleState.resumed:
        currentUserid !=null ? authMethods.setUserState(userId: currentUserid, userState: UserState.Online): print("resumed");
            break;
      case AppLifecycleState.inactive:
        currentUserid !=null ? authMethods.setUserState(userId: currentUserid, userState: UserState.Offline): print("inactive");
        break;
      case AppLifecycleState.paused:
        currentUserid !=null ? authMethods.setUserState(userId: currentUserid, userState: UserState.Waiting): print("paused");
        break;
      case AppLifecycleState.detached:
        currentUserid !=null ? authMethods.setUserState(userId: currentUserid, userState: UserState.Waiting): print("detached");
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
              Icon(Icons.contacts),
            ],
            height: 60,
            color: Colors.white,
            buttonBackgroundColor: Colors.white,
            backgroundColor: UniversalVariables.blueColor,
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
      return ContactPage();
  }
}
