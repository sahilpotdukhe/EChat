import 'dart:async';

import 'package:echat/providers/user_provider.dart';
import 'package:echat/resources/auth_methods.dart';
import 'package:echat/resources/local_notifications.dart';
import 'package:echat/resources/repositories/log_repository.dart';
import 'package:echat/screens/call/pickup_layout.dart';
import 'package:echat/screens/call_logs/call_logs_screen.dart';
import 'package:echat/screens/chat_list/chat_list_screen.dart';
import 'package:echat/screens/search_screen.dart';
import 'package:echat/widgets/new_user_details.dart';
import 'package:echat/enums/user_state.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:echat/screens/contact_page.dart';
import 'package:echat/utils/responsive.dart';
import 'package:echat/widgets/common/brand_logo.dart';
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
  StreamSubscription<RemoteMessage>? _messageSubscription;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initializeUser();
    // Show notifications while the app is open too. Messages without a
    // title are handled (the old code assumed one and could crash).
    _messageSubscription = FirebaseMessaging.onMessage.listen(LocalNotifications.show);
  }

  Future<void> initializeUser() async {
    await Future.delayed(Duration.zero); // This ensures that the context is available
    if (_disposed || !mounted) return;
    userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.refreshUser();
    if (_disposed) return;
    if (userProvider.getUser != null) {
      authMethods.setUserState(userId: userProvider.getUser!.uid, userState: UserState.online);
      LogRepository.initialize(dbName: userProvider.getUser!.uid);
      debugPrint('${userProvider.getUser!.state}');

    } else {
      debugPrint('User is null');
    }
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _messageSubscription?.cancel();
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
  static const _tabs = [
    _Tab('Chats', Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded),
    _Tab('Calls', Icons.call_outlined, Icons.call_rounded),
    _Tab('People', Icons.group_outlined, Icons.group_rounded),
    _Tab('Contacts', Icons.contacts_outlined, Icons.contacts_rounded),
    _Tab('Profile', Icons.person_outline_rounded, Icons.person_rounded),
  ];
  static const _profileTab = 4;

  int _page = 0;

  // Tabs are built the first time they're opened and then kept, so switching
  // back keeps their scroll position and doesn't reload everything. (Built
  // lazily so e.g. Contacts doesn't ask for permission before it's opened.)
  final Set<int> _visited = {0};

  void _select(int index) {
    if (index == _page) return;
    setState(() {
      _page = index;
      _visited.add(index);
    });
  }

  Widget _pageFor(int index) {
    switch (index) {
      case 0:
        return ChatListScreen(onOpenProfile: () => _select(_profileTab));
      case 1:
        return CallLogsScreen(isActive: _page == 1);
      case 2:
        return const SearchScreen(asTab: true);
      case 3:
        return ContactPage();
      default:
        return NewUserDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    final useRail = !context.isCompact;
    final pages = IndexedStack(
      index: _page,
      children: [
        for (var i = 0; i < _tabs.length; i++)
          _visited.contains(i) ? _pageFor(i) : const SizedBox.shrink(),
      ],
    );

    return PickupLayout(
      scaffold: PopScope(
        // Back from another tab returns to Chats before leaving the app.
        canPop: _page == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _select(0);
        },
        child: Scaffold(
          body: useRail
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _page,
                      onDestinationSelected: _select,
                      labelType: NavigationRailLabelType.all,
                      groupAlignment: -0.85,
                      leading: const Padding(
                        padding: EdgeInsets.only(top: 8, bottom: 16),
                        child: BrandLogo(size: 40, showName: false),
                      ),
                      destinations: [
                        for (final t in _tabs)
                          NavigationRailDestination(
                            icon: Icon(t.icon),
                            selectedIcon: Icon(t.selectedIcon),
                            label: Text(t.label),
                          ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: pages),
                  ],
                )
              : pages,
          bottomNavigationBar: useRail
              ? null
              : NavigationBar(
                  selectedIndex: _page,
                  onDestinationSelected: _select,
                  destinations: [
                    for (final t in _tabs)
                      NavigationDestination(
                        icon: Icon(t.icon),
                        selectedIcon: Icon(t.selectedIcon),
                        label: t.label,
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Tab {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _Tab(this.label, this.icon, this.selectedIcon);
}
