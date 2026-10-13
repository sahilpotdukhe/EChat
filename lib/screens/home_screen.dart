import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/models/contact_model.dart';
import 'package:echat/resources/chat_firebase_methods.dart';
import 'package:echat/resources/notification_router.dart';
import 'package:echat/resources/presence_service.dart';
import 'package:echat/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:echat/providers/user_provider.dart';
import 'package:echat/resources/auth_methods.dart';
import 'package:echat/resources/local_notifications.dart';
import 'package:echat/resources/repositories/log_repository.dart';
import 'package:echat/screens/call/pickup_layout.dart';
import 'package:echat/screens/call_logs/call_logs_screen.dart';
import 'package:echat/screens/chat_list/chat_list_screen.dart';
import 'package:echat/screens/search_screen.dart';
import 'package:echat/widgets/new_user_details.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  late UserProvider userProvider;
  AuthMethods authMethods = AuthMethods();
  final ChatFirebaseMethods _chatMethods = ChatFirebaseMethods();
  bool _disposed = false;
  final List<StreamSubscription> _subscriptions = [];

  /// Chats with unread messages: the number on the Chats tab.
  int _unreadChats = 0;

  // Chats whose new messages are being marked delivered right now.
  final Set<String> _delivering = {};

  @override
  void initState() {
    super.initState();
    initializeUser();
    final messaging = FirebaseMessaging.instance;
    _subscriptions.addAll([
      // Pushes that arrive while the app is open: the phone doesn't show
      // these itself.
      FirebaseMessaging.onMessage.listen((message) {
        LocalNotifications.show(message, appOpen: true);
        LocalNotifications.markDeliveredFromPush(message);
      }),
      // Tapping a notification the phone showed while the app was in the
      // background.
      FirebaseMessaging.onMessageOpenedApp.listen(_openFromPush),
      // The push address of this phone can change; without saving the new
      // one, notifications silently stop arriving.
      messaging.onTokenRefresh.listen((token) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) authMethods.updateToken(uid, token).catchError((Object e) => debugPrint('$e'));
      }),
    ]);
  }

  Future<void> initializeUser() async {
    await Future.delayed(Duration.zero); // This ensures that the context is available
    if (_disposed || !mounted) return;
    userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.refreshUser();
    if (_disposed) return;
    final user = userProvider.getUser;
    if (user == null) {
      debugPrint('User is null');
      return;
    }
    PresenceService.instance.start(user.uid);
    LogRepository.initialize(dbName: user.uid);
    _subscriptions.add(_chatMethods.fetchUnreadContacts(userId: user.uid).listen(
          (snapshot) => _onUnreadChanged(user.uid, snapshot),
          onError: (Object e) => debugPrint('Unread chats: $e'),
        ));
    // An iPhone only gets a push token once notifications are allowed, so
    // save it again here; the one saved at sign-in may be missing.
    LocalNotifications.requestPermission().then((_) => authMethods.saveNotificationToken(user.uid));
    await _openFromLaunch();
  }

  // The app was opened by tapping a notification.
  Future<void> _openFromLaunch() async {
    try {
      final RemoteMessage? push = await FirebaseMessaging.instance.getInitialMessage();
      if (push != null) _openFromPush(push);
      final action = await AwesomeNotifications().getInitialNotificationAction(removeFromActionEvents: true);
      final payload = action?.payload ?? const {};
      if (payload['type'] == 'message') NotificationRouter.openChat(payload['senderId'] ?? '');
    } catch (e) {
      debugPrint('Could not read the launch notification: $e');
    }
    NotificationRouter.openPending();
  }

  void _openFromPush(RemoteMessage message) {
    if (message.data['type'] == 'message') NotificationRouter.openChat(message.data['senderId'] ?? '');
  }

  // Keeps the badges up to date, and marks new messages as delivered: this
  // phone has them now, so the sender sees two grey ticks.
  void _onUnreadChanged(String myId, QuerySnapshot snapshot) {
    var messages = 0;
    for (final doc in snapshot.docs) {
      final contact = ContactModel.fromMap(doc.data() as Map<String, dynamic>);
      messages += contact.unreadCount;
      if (contact.uid.isNotEmpty && _delivering.add(contact.uid)) {
        _chatMethods
            .markDelivered(myId: myId, peerId: contact.uid)
            .catchError((Object e) => debugPrint('Mark delivered: $e'))
            .whenComplete(() => _delivering.remove(contact.uid));
      }
    }
    LocalNotifications.setBadge(messages);
    if (mounted && snapshot.docs.length != _unreadChats) setState(() => _unreadChats = snapshot.docs.length);
  }

  @override
  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    NotificationRouter.homeClosed();
    super.dispose();
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
                        for (final (i, t) in _tabs.indexed)
                          NavigationRailDestination(
                            icon: _badged(i, Icon(t.icon)),
                            selectedIcon: _badged(i, Icon(t.selectedIcon)),
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
                    for (final (i, t) in _tabs.indexed)
                      NavigationDestination(
                        icon: _badged(i, Icon(t.icon)),
                        selectedIcon: _badged(i, Icon(t.selectedIcon)),
                        label: t.label,
                        tooltip: i == 0 && _unreadChats > 0 ? '${t.label}, $_unreadChats unread' : null,
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

extension on _HomeScreenState {
  // The Chats tab shows how many chats have unread messages, like WhatsApp.
  Widget _badged(int index, Widget icon) {
    if (index != 0 || _unreadChats == 0) return icon;
    return Badge(
      label: Text(_unreadChats > 99 ? '99+' : '$_unreadChats'),
      backgroundColor: context.colors.success,
      child: icon,
    );
  }
}

class _Tab {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _Tab(this.label, this.icon, this.selectedIcon);
}
