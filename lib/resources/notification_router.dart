import 'package:echat/resources/auth_methods.dart';
import 'package:echat/screens/chat/chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Opens the chat a tapped notification belongs to.
///
/// A tap can arrive before the home screen exists (the app was closed), so
/// the chat is remembered until HomeScreen calls [openPending].
class NotificationRouter {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static String? _pendingPeerId;
  static bool _homeReady = false;

  static void openChat(String peerId) {
    if (peerId.isEmpty) return;
    if (!_homeReady || navigatorKey.currentState == null) {
      _pendingPeerId = peerId;
      return;
    }
    _open(peerId);
  }

  /// HomeScreen is up: open any chat tapped while the app was starting.
  static void openPending() {
    _homeReady = true;
    final peerId = _pendingPeerId;
    _pendingPeerId = null;
    if (peerId != null) _open(peerId);
  }

  /// HomeScreen went away (logout).
  static void homeClosed() => _homeReady = false;

  static Future<void> _open(String peerId) async {
    if (FirebaseAuth.instance.currentUser == null) return;
    try {
      final peer = await AuthMethods().getUserDetailsById(peerId);
      final navigator = navigatorKey.currentState;
      if (peer == null || navigator == null) return;
      // Replace a chat that's already open rather than stacking chats.
      navigator.popUntil((route) => route.isFirst);
      navigator.push(MaterialPageRoute(builder: (_) => ChatScreen(receiver: peer)));
    } catch (e) {
      debugPrint('Could not open the chat from a notification: $e');
    }
  }
}
