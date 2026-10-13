import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/resources/chat_firebase_methods.dart';
import 'package:echat/resources/notification_router.dart';
import 'package:echat/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// Shows a push message as a phone notification: a ringing full-screen one
/// for calls (Accept / Decline), a normal one for chat messages, one per chat
/// so different people's messages don't replace each other.
///
/// Pushes from the server carry a notification part, which the phone shows
/// by itself while the app is in the background. This class shows the rest:
/// pushes that arrive while the app is open, and data-only pushes.
class LocalNotifications {
  static const _callId = 123;

  /// The chat on screen right now, so its own messages don't notify.
  static String? openChatPeerId;

  /// Once, at startup, before any notification is shown.
  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: "call_channel",
        channelName: "Calls",
        channelDescription: "Incoming voice and video calls",
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
        channelName: "Messages",
        channelDescription: "New chat messages",
        defaultColor: Colors.redAccent,
        ledColor: Colors.white,
        importance: NotificationImportance.Max,
        channelShowBadge: true,
        defaultRingtoneType: DefaultRingtoneType.Notification,
        playSound: true,
      ),
    ]);
    await AwesomeNotifications().setListeners(onActionReceivedMethod: _onAction);
  }

  /// [appOpen] is true for pushes received while the app is on screen.
  static Future<void> show(RemoteMessage message, {bool appOpen = false}) async {
    final Map<String, dynamic> data = message.data;
    // Data-only messages have no notification part; fall back to the data
    // fields (sent by server/src/app.js) instead of crashing.
    final bool isCall = data['type'] == 'call' || message.notification?.title == 'Incoming Call';
    final String senderId = (data['senderId'] ?? data['callerId'] ?? '').toString();

    // With the app open, an incoming call already fills the screen, and a
    // message for the chat you're reading is already in front of you.
    if (appOpen && isCall) return;
    if (appOpen && senderId.isNotEmpty && senderId == openChatPeerId) return;

    final String? title = message.notification?.title ?? data['title'] ?? (isCall ? 'Incoming Call' : null);
    final String? body = message.notification?.body ?? data['body'];
    if (title == null && body == null) return;
    final String? image = message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: isCall ? _callId : notificationIdFor(senderId),
        channelKey: isCall ? 'call_channel' : 'message_channel',
        title: title,
        body: body,
        groupKey: isCall ? null : senderId,
        category: isCall ? NotificationCategory.Call : NotificationCategory.Message,
        wakeUpScreen: true,
        fullScreenIntent: isCall,
        autoDismissible: !isCall,
        locked: isCall,
        backgroundColor: AppColors.shadcnLight.primary,
        notificationLayout: image != null && !isCall ? NotificationLayout.BigPicture : NotificationLayout.Default,
        bigPicture: isCall ? null : image,
        largeIcon: 'asset://assets/login.png',
        payload: {'type': isCall ? 'call' : 'message', 'senderId': senderId},
      ),
      actionButtons: isCall
          ? [
              NotificationActionButton(
                  key: 'Decline',
                  label: 'Decline',
                  color: Colors.red,
                  actionType: ActionType.SilentBackgroundAction,
                  autoDismissible: true),
              // Opens the app, where the incoming call screen is waiting.
              NotificationActionButton(key: 'Accept', label: 'Answer', color: Colors.green, autoDismissible: true),
            ]
          : null,
    );
  }

  /// The message in this push reached this phone: two grey ticks for the
  /// sender, even if the app stays closed.
  static Future<void> markDeliveredFromPush(RemoteMessage message) async {
    final data = message.data;
    final String? messageId = data['messageId'];
    final String? senderId = data['senderId'];
    if (data['type'] != 'message' || messageId == null || senderId == null) return;
    try {
      final user = FirebaseAuth.instance.currentUser ?? await FirebaseAuth.instance.authStateChanges().first;
      if (user == null) return;
      await ChatFirebaseMethods()
          .markDeliveredById(myId: user.uid, peerId: senderId, messageId: messageId)
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      debugPrint('Could not mark the message delivered: $e');
    }
  }

  /// One notification per chat: a stable id from the sender's uid (Dart's
  /// own String.hashCode isn't promised to be the same between runs).
  static int notificationIdFor(String senderId) {
    var hash = 7;
    for (final unit in senderId.codeUnits) {
      hash = (hash * 31 + unit) & 0x3fffffff;
    }
    // Keep clear of the call notification's id.
    return hash == _callId ? hash + 1 : hash;
  }

  /// Clears a chat's notifications once it is opened.
  static Future<void> dismissChat(String senderId) =>
      AwesomeNotifications().dismiss(notificationIdFor(senderId));

  /// Asks once for permission to show notifications. iPhones (and Android
  /// 13+) show nothing until the user agrees; later calls don't ask again.
  static Future<void> requestPermission() async {
    try {
      await FirebaseMessaging.instance.requestPermission();
    } catch (e) {
      debugPrint('Could not ask for notification permission: $e');
    }
  }

  /// The number on the app icon (where the launcher supports it).
  static Future<void> setBadge(int count) async {
    try {
      await AwesomeNotifications().setGlobalBadgeCounter(count);
    } catch (e) {
      debugPrint('Could not set the app badge: $e');
    }
  }

  // May run with the app closed (Decline), in its own isolate.
  @pragma('vm:entry-point')
  static Future<void> _onAction(ReceivedAction action) async {
    final payload = action.payload ?? const {};
    if (action.buttonKeyPressed == 'Decline') {
      await _declineCall(payload['senderId'] ?? '');
      return;
    }
    // Tapped a message (or Answer): open the app on that chat; for a call
    // the incoming call screen shows by itself.
    if (payload['type'] == 'message') NotificationRouter.openChat(payload['senderId'] ?? '');
  }

  // Hangs up a ringing call from the notification, like the Decline button
  // on the incoming call screen (which then logs it as missed).
  static Future<void> _declineCall(String callerId) async {
    try {
      await Firebase.initializeApp();
      final user = FirebaseAuth.instance.currentUser ?? await FirebaseAuth.instance.authStateChanges().first;
      if (user == null) return;
      final calls = FirebaseFirestore.instance.collection('Call');
      await Future.wait([
        calls.doc(user.uid).delete(),
        if (callerId.isNotEmpty) calls.doc(callerId).delete(),
      ]);
    } catch (e) {
      debugPrint('Could not decline the call: $e');
    }
  }
}
