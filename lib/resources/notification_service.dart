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

  /// The caller hung up or gave up: stops the receiver's phone ringing at
  /// once, even with EChat closed (otherwise it rings for the full 45 s).
  static Future<void> notifyCallEnded({required String receiverId}) =>
      _post('/notify/call-ended', {'receiverId': receiverId});

  static DateTime? _lastWarmUp;

  /// Wakes the server up ahead of time. Vercel puts it to sleep when idle,
  /// and waking costs a few seconds, which would otherwise delay the first
  /// notification. Called when the app or a chat opens; at most every few
  /// minutes. Fire-and-forget.
  static void warmUp() {
    final now = DateTime.now();
    final last = _lastWarmUp;
    if (last != null && now.difference(last) < const Duration(minutes: 4)) return;
    _lastWarmUp = now;
    http.get(Uri.parse('$baseUrl/health')).timeout(_timeout).catchError((Object e) {
      debugPrint('Notification server warm-up failed: $e');
      return http.Response('', 0);
    });
  }

  /// The pass to join call [channelId]'s Agora channel. Throws if the
  /// server can't give one (not set up yet, not in that call, offline).
  static Future<String> callToken(String channelId) async {
    final String? idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) throw StateError('Not signed in');
    final http.Response response = await http
        .post(
          Uri.parse('$baseUrl/agora/token'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $idToken'},
          body: jsonEncode({'channelId': channelId}),
        )
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('Call pass refused: ${response.statusCode} ${response.body}');
    }
    final token = (jsonDecode(response.body) as Map)['token'];
    if (token is! String || token.isEmpty) throw Exception('Call pass missing from the reply');
    return token;
  }

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
