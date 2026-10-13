import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/enums/user_state.dart';
import 'package:echat/resources/connectivity_service.dart';
import 'package:echat/utils/presence.dart';
import 'package:echat/utils/utilities.dart';
import 'package:flutter/widgets.dart';

/// Tells other people whether I'm online.
///
/// While the app is on screen it marks me online and refreshes `last_seen`
/// every [Presence.heartbeat]; when the app goes to the background it marks
/// me offline. If the phone dies or loses signal nothing can mark me
/// offline, so others treat an online that stops being refreshed as offline
/// (see Presence.isOnline).
///
/// Brief interruptions (pulling down the notification shade, a system
/// dialog) don't count as leaving: only going to the background does.
class PresenceService with WidgetsBindingObserver {
  PresenceService._();

  static final PresenceService instance = PresenceService._();

  String? _uid;
  Timer? _heartbeat;
  bool _foreground = true;

  /// Starts for the signed-in user. Safe to call again (e.g. after the
  /// profile reloads); a different user replaces the previous one.
  void start(String uid) {
    if (uid.isEmpty) return;
    if (_uid == null) {
      WidgetsBinding.instance.addObserver(this);
      ConnectivityService.instance.isOnline.addListener(_onConnectivityChanged);
    }
    _uid = uid;
    _foreground = WidgetsBinding.instance.lifecycleState != AppLifecycleState.paused &&
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.hidden;
    if (_foreground) _goOnline();
  }

  /// Marks me offline and stops (used on logout, before signing out).
  Future<void> stop() async {
    final uid = _uid;
    if (uid == null) return;
    WidgetsBinding.instance.removeObserver(this);
    ConnectivityService.instance.isOnline.removeListener(_onConnectivityChanged);
    _heartbeat?.cancel();
    _uid = null;
    await _write(uid, UserState.offline).timeout(const Duration(seconds: 5), onTimeout: () {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _foreground = true;
        _goOnline();
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        if (_foreground) {
          _foreground = false;
          _goOffline();
        }
      case AppLifecycleState.inactive:
        // A moment's interruption; still on screen.
        break;
    }
  }

  // Back online after losing the connection: say so straight away rather
  // than waiting for the next heartbeat.
  void _onConnectivityChanged() {
    if (ConnectivityService.instance.isOnline.value && _foreground) _goOnline();
  }

  void _goOnline() {
    final uid = _uid;
    if (uid == null) return;
    _write(uid, UserState.online);
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(Presence.heartbeat, (_) {
      final current = _uid;
      if (current != null && _foreground) _write(current, UserState.online);
    });
  }

  void _goOffline() {
    _heartbeat?.cancel();
    final uid = _uid;
    if (uid != null) _write(uid, UserState.offline);
  }

  static Future<void> _write(String uid, UserState state) async {
    try {
      await FirebaseFirestore.instance.collection('Users').doc(uid).update({
        'state': Utils.stateToNum(state),
        'last_seen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Presence update failed: $e');
    }
  }
}
