import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Rings the phone while the incoming call screen is showing in the app.
/// With the app in the background or closed, the call notification rings
/// instead (see LocalNotifications).
///
/// The sound is native code in MainActivity.kt / AppDelegate.swift: Android
/// loops the user's own ringtone, iOS repeats a system alert sound. Both
/// follow silent / vibrate mode like a normal phone call.
class CallRinger {
  static const MethodChannel _channel = MethodChannel('echat/ringer');
  static bool _ringing = false;

  static Future<void> start() async {
    if (_ringing) return;
    _ringing = true;
    await _call('start');
  }

  static Future<void> stop() async {
    if (!_ringing) return;
    _ringing = false;
    await _call('stop');
  }

  static Future<void> _call(String method) async {
    try {
      await _channel.invokeMethod<void>(method);
    } catch (e) {
      // Desktop / web builds have no ringer: the call simply rings silently.
      debugPrint('Ringer $method failed: $e');
    }
  }
}
