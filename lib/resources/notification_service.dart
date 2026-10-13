import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Asks the EChat notification server (server/, hosted on Vercel) to send a
/// push notification. The server checks the user's Firebase sign-in and that
/// the message or call really exists, so the app never holds messaging keys.
///
/// Every method is fire-and-forget: a slow or unreachable server
/// only means a missing notification, never a failed message or call.
class NotificationService {
  /// Override per build with `--dart-define=NOTIFY_SERVER_URL=https://...`.
  static const String baseUrl = String.fromEnvironment(
    'NOTIFY_SERVER_URL',
    defaultValue: 'https://echat-notify.vercel.app',
  );

  // Covers a Vercel cold start plus a slow mobile connection.
  static const Duration _timeout = Duration(seconds: 15);

  static Future<void> notifyMessage({required String messageId, required String receiverId}) =>
      _post('/notify/message', {'messageId': messageId, 'receiverId': receiverId});

  static Future<void> notifyCall({required String receiverId}) =>
      _post('/notify/call', {'receiverId': receiverId});

  /// Lets this account upload files to Supabase (see MediaStorage). Unlike
  /// the notifications, this throws on failure so the upload can report it.
  static Future<void> grantStorageAccess() async {
    final String? idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) throw StateError('Not signed in');
    final http.Response response = await http
        .post(Uri.parse('$baseUrl/supabase/role'), headers: {'Authorization': 'Bearer $idToken'})
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('Storage access refused: ${response.statusCode} ${response.body}');
    }
  }

  static Future<void> _post(String path, Map<String, String> body) async {
    try {
      final String? idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) return;
      final http.Response response = await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      if (response.statusCode != 200) {
        debugPrint('Notification $path failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Notification $path failed: $e');
    }
  }
}
