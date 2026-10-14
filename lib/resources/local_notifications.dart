import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/models/message_model.dart';
import 'package:echat/resources/chat_firebase_methods.dart';
import 'package:echat/resources/notification_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// Draws EChat's phone notifications, WhatsApp-style:
///
/// * Messages: the sender's round photo, name and text, stacked per chat,
///   with **Reply** (type in the notification) and **Mark as read**.
/// * Calls: a full-screen, ringing notification with the caller's photo and
///   **Decline** / **Answer**, which stops ringing after 45 seconds.
///
/// On Android the server sends the details as data only and this class draws
/// the notification, even with the app closed (see the background handler in
/// main.dart). iPhones get the system's own notification from the server.
class LocalNotifications {
  static const _callId = 123;
  // The small status-bar icon: the EChat logo as a one-colour silhouette
  // (Android only allows one colour there). The full-colour app icon is used
  // as the big picture when the sender has no profile photo.
  static const String _icon = 'resource://drawable/ic_stat_echat';
  static const String _appIcon = 'resource://mipmap/ic_launcher';
  static const Color _brand = Color(0xFF6C5CE7);

  /// The chat on screen right now, so its own messages don't notify.
  static String? openChatPeerId;

  /// Once, at startup, before any notification is shown.
  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(_icon, [
      NotificationChannel(
        channelKey: "call_channel",
        channelName: "Calls",
        channelDescription: "Incoming voice and video calls",
        defaultColor: _brand,
        ledColor: _brand,
        importance: NotificationImportance.Max,
        channelShowBadge: false,
        locked: true,
        criticalAlerts: true,
        defaultRingtoneType: DefaultRingtoneType.Ringtone,
        playSound: true,
        enableVibration: true,
      ),
      NotificationChannel(
        channelKey: "message_channel",
        channelName: "Messages",
        channelDescription: "New chat messages",
        defaultColor: _brand,
        ledColor: _brand,
        importance: NotificationImportance.High,
        channelShowBadge: true,
        defaultRingtoneType: DefaultRingtoneType.Notification,
        playSound: true,
        enableVibration: true,
        groupAlertBehavior: GroupAlertBehavior.Children,
      ),
    ]);
    await AwesomeNotifications().setListeners(onActionReceivedMethod: _onAction);
  }

  /// [appOpen] is true for pushes received while the app is on screen.
  static Future<void> show(RemoteMessage message, {bool appOpen = false}) async {
    final Map<String, dynamic> data = message.data;
    final bool isCall = data['type'] == 'call';
    final String senderId = (data['senderId'] ?? data['callerId'] ?? '').toString();

    // The caller hung up (or gave up): stop ringing right away instead of
    // waiting out the 45 second timeout.
    if (data['type'] == 'call_ended') {
      await dismissCall(callerId: senderId);
      return;
    }

    // With the app open, an incoming call already fills the screen, and a
    // message for the chat you're reading is already in front of you.
    if (appOpen && isCall) return;
    if (appOpen && senderId.isNotEmpty && senderId == openChatPeerId) return;

    final String title = (message.notification?.title ?? data['title'] ?? '').toString();
    final String body = (message.notification?.body ?? data['body'] ?? '').toString();
    if (title.isEmpty && body.isEmpty) return;
    // No profile photo: show the EChat icon instead of an empty space.
    final String avatar = _url(data['avatar']) ?? _appIcon;

    final badge = int.tryParse('${data['badge'] ?? ''}');
    if (badge != null) setBadge(badge);

    if (isCall) {
      await _showCall(title: title, body: body, avatar: avatar, callerId: senderId);
    } else {
      await _showMessage(
        title: title,
        body: body,
        avatar: avatar,
        image: _url(data['image']),
        senderId: senderId,
        messageId: (data['messageId'] ?? '').toString(),
      );
    }
  }

  static Future<void> _showMessage({
    required String title,
    required String body,
    required String senderId,
    required String messageId,
    required String avatar,
    String? image,
  }) async {
    final payload = {'type': 'message', 'senderId': senderId, 'messageId': messageId};
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        // One per message, stacked under the chat's group.
        id: notificationIdFor(messageId.isEmpty ? '$senderId${DateTime.now().millisecondsSinceEpoch}' : messageId),
        channelKey: 'message_channel',
        groupKey: senderId,
        title: title,
        body: body,
        summary: title,
        category: NotificationCategory.Message,
        color: _brand,
        largeIcon: avatar,
        roundedLargeIcon: true,
        // A photo shows big; text stacks like a conversation.
        notificationLayout: image != null ? NotificationLayout.BigPicture : NotificationLayout.Messaging,
        bigPicture: image,
        hideLargeIconOnExpand: image != null,
        wakeUpScreen: true,
        autoDismissible: true,
        payload: payload,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'Reply',
          label: 'Reply',
          requireInputText: true,
          actionType: ActionType.SilentBackgroundAction,
          autoDismissible: true,
        ),
        NotificationActionButton(
          key: 'MarkRead',
          label: 'Mark as read',
          actionType: ActionType.SilentBackgroundAction,
          autoDismissible: true,
        ),
      ],
    );
  }

  static Future<void> _showCall({
    required String title,
    required String body,
    required String callerId,
    required String avatar,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _callId,
        channelKey: 'call_channel',
        groupKey: _callGroup(callerId),
        title: title,
        body: body,
        category: NotificationCategory.Call,
        color: _brand,
        largeIcon: avatar,
        roundedLargeIcon: true,
        notificationLayout: NotificationLayout.Default,
        wakeUpScreen: true,
        fullScreenIntent: true,
        autoDismissible: false,
        locked: true,
        // The caller gives up after 45 seconds; stop ringing then too.
        timeoutAfter: const Duration(seconds: 45),
        payload: {'type': 'call', 'senderId': callerId},
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'Decline',
          label: 'Decline',
          color: const Color(0xFFE5484D),
          actionType: ActionType.SilentBackgroundAction,
          autoDismissible: true,
          isDangerousOption: true,
        ),
        // Opens the app, where the incoming call screen is waiting.
        NotificationActionButton(key: 'Accept', label: 'Answer', color: const Color(0xFF16A34A), autoDismissible: true),
      ],
    );
  }

  static String _callGroup(String callerId) => 'call_$callerId';

  static String? _url(Object? value) {
    final s = value?.toString() ?? '';
    return s.startsWith('https://') ? s : null;
  }

  /// The message in this push reached this phone: two grey ticks for the
  /// sender, even if the app stays closed.
  static Future<void> markDeliveredFromPush(RemoteMessage message) async {
    final data = message.data;
    final String? messageId = data['messageId'];
    final String? senderId = data['senderId'];
    if (data['type'] != 'message' || messageId == null || senderId == null) return;
    try {
      final user = await _signedInUser();
      if (user == null) return;
      await ChatFirebaseMethods()
          .markDeliveredById(myId: user.uid, peerId: senderId, messageId: messageId)
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      debugPrint('Could not mark the message delivered: $e');
    }
  }

  /// A stable notification id from a string (Dart's own String.hashCode
  /// isn't promised to be the same between runs).
  static int notificationIdFor(String key) {
    var hash = 7;
    for (final unit in key.codeUnits) {
      hash = (hash * 31 + unit) & 0x3fffffff;
    }
    // Keep clear of the call notification's id.
    return hash == _callId ? hash + 1 : hash;
  }

  /// Takes down the ringing call notification. With [callerId], only if it
  /// is that person's call (a late "call ended" for an older call must not
  /// silence a new one).
  static Future<void> dismissCall({String? callerId}) async {
    try {
      if (callerId != null && callerId.isNotEmpty) {
        await AwesomeNotifications().dismissNotificationsByGroupKey(_callGroup(callerId));
      } else {
        await AwesomeNotifications().dismiss(_callId);
      }
    } catch (e) {
      debugPrint('Could not clear the call notification: $e');
    }
  }

  /// Clears a chat's notifications once it is opened.
  static Future<void> dismissChat(String senderId) async {
    try {
      await AwesomeNotifications().dismissNotificationsByGroupKey(senderId);
    } catch (e) {
      debugPrint('Could not clear notifications: $e');
    }
  }

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

  // May run with the app closed (Decline, Reply, Mark as read), in its own
  // isolate, so it sets up Firebase itself.
  @pragma('vm:entry-point')
  static Future<void> _onAction(ReceivedAction action) async {
    final payload = action.payload ?? const {};
    final String senderId = payload['senderId'] ?? '';
    switch (action.buttonKeyPressed) {
      case 'Decline':
        await _declineCall(senderId);
      case 'Reply':
        await _reply(senderId, payload['messageId'] ?? '', action.buttonKeyInput.trim());
      case 'MarkRead':
        await _markRead(senderId, payload['messageId'] ?? '');
      default:
        // Tapped a message (or Answer): open the app on that chat; for a
        // call the incoming call screen shows by itself.
        if (payload['type'] == 'message') NotificationRouter.openChat(senderId);
    }
  }

  static Future<User?> _signedInUser() async {
    await Firebase.initializeApp();
    return FirebaseAuth.instance.currentUser ?? await FirebaseAuth.instance.authStateChanges().first;
  }

  // Sends a text reply typed in the notification, and marks their message
  // read (replying means you've seen it).
  static Future<void> _reply(String senderId, String messageId, String text) async {
    if (senderId.isEmpty || text.isEmpty) return;
    try {
      final user = await _signedInUser();
      if (user == null) return;
      await ChatFirebaseMethods().addMessagetoDb(MessageModel(
        senderId: user.uid,
        receiverId: senderId,
        type: 'text',
        message: text,
        timestamp: Timestamp.now(),
        photoUrl: '',
        thumbnailUrl: '',
        pdfUrl: '',
        pdfName: '',
      ));
      await _markRead(senderId, messageId);
    } catch (e) {
      debugPrint('Could not send the reply: $e');
    }
  }

  static Future<void> _markRead(String senderId, String messageId) async {
    if (senderId.isEmpty) return;
    try {
      final user = await _signedInUser();
      if (user == null) return;
      final chat = ChatFirebaseMethods();
      await Future.wait([
        if (messageId.isNotEmpty) chat.markRead(myId: user.uid, peerId: senderId, messageIds: [messageId]),
        chat.clearUnread(myId: user.uid, peerId: senderId),
      ]);
      await dismissChat(senderId);
    } catch (e) {
      debugPrint('Could not mark as read: $e');
    }
  }

  // Hangs up a ringing call from the notification, like the Decline button
  // on the incoming call screen (which then logs it as missed).
  static Future<void> _declineCall(String callerId) async {
    try {
      final user = await _signedInUser();
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
