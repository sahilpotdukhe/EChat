import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:echat/theme/app_colors.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// Shows a push message as a phone notification: a ringing full-screen one
/// for calls (Accept / Reject), a normal one for chat messages.
///
/// Used both when the app is closed (the background handler in main.dart)
/// and when it's open (HomeScreen), so they always look the same.
class LocalNotifications {
  static const _callId = 123;
  static const _messageId = 456;

  static Future<void> show(RemoteMessage message) async {
    // Data-only messages have no notification part; fall back to the data
    // fields (sent by server/src/app.js) instead of crashing.
    final bool isCall = message.data['type'] == 'call' || message.notification?.title == 'Incoming Call';
    final String? title = message.notification?.title ?? (isCall ? 'Incoming Call' : null);
    final String? body = message.notification?.body;
    if (title == null && body == null) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: isCall ? _callId : _messageId,
        channelKey: isCall ? 'call_channel' : 'message_channel',
        title: title,
        body: body,
        category: isCall ? NotificationCategory.Call : NotificationCategory.Message,
        wakeUpScreen: true,
        fullScreenIntent: true,
        autoDismissible: false,
        backgroundColor: AppColors.shadcnLight.primary,
        notificationLayout: NotificationLayout.BigPicture,
        largeIcon: 'asset://assets/login.png',
        displayOnForeground: true,
        displayOnBackground: true,
      ),
      actionButtons: isCall
          ? [
              NotificationActionButton(key: 'Accept', label: 'Accept Call', color: Colors.green, autoDismissible: true),
              NotificationActionButton(key: 'Reject', label: 'Reject Call', color: Colors.red, autoDismissible: true),
            ]
          : [
              NotificationActionButton(key: 'Reply', label: 'Reply', color: Colors.grey, autoDismissible: true),
              NotificationActionButton(
                  key: 'Mark as read', label: 'Mark as read', color: Colors.grey, actionType: ActionType.DismissAction),
            ],
    );

    AwesomeNotifications().setListeners(onActionReceivedMethod: _onAction);
  }

  @pragma('vm:entry-point')
  static Future<void> _onAction(ReceivedAction action) async {
    switch (action.buttonKeyPressed) {
      case 'Accept':
        debugPrint('Call Accepted');
      case 'Reject':
        debugPrint('Call Rejected');
      case 'Reply':
        debugPrint('Message replied');
      default:
        debugPrint('Clicked on notification');
        if (action.id != null) await AwesomeNotifications().dismiss(action.id!);
    }
  }
}
