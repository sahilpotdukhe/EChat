import 'dart:async';

import 'package:echat/enums/user_state.dart';
import 'package:echat/models/user_model.dart';
import 'package:echat/utils/utilities.dart';
import 'package:flutter/foundation.dart';

/// Decides whether someone is online.
///
/// Their app marks them online and refreshes `last_seen` about once a
/// minute while it is open (PresenceService). If their phone dies, loses
/// signal or the app is killed, nothing marks them offline, so an "online"
/// that hasn't been refreshed for [staleAfter] counts as offline.
class Presence {
  static const Duration heartbeat = Duration(seconds: 45);
  static const Duration staleAfter = Duration(minutes: 2, seconds: 30);

  static bool isOnline(UserModel user, DateTime now) {
    if (Utils.numToState(user.state) != UserState.online) return false;
    final lastSeen = user.lastSeen;
    // Profiles from older app builds have no last_seen: trust the flag.
    if (lastSeen == null) return true;
    // Allow a little clock difference between phones in the other direction.
    return now.difference(lastSeen.toDate()) < staleAfter;
  }

  /// Ticks every 30 seconds so "online" dots expire on screen even when the
  /// person's profile doesn't change. Wrap presence UI in a
  /// ValueListenableBuilder on this.
  static final ValueNotifier<DateTime> clock = _Clock();
}

class _Clock extends ValueNotifier<DateTime> {
  Timer? _timer;

  _Clock() : super(DateTime.now());

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    _timer ??= Timer.periodic(const Duration(seconds: 30), (_) => value = DateTime.now());
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      _timer?.cancel();
      _timer = null;
    }
  }
}
