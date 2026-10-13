import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Whether this phone can reach the internet right now.
///
/// Being on Wi-Fi or mobile data isn't enough (a café login page, no
/// signal), so when the phone says it is connected we also check that a
/// Google server answers. While offline, it re-checks every few seconds.
class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService instance = ConnectivityService._();

  /// True while online. Starts true so nothing flashes "offline" at launch.
  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _retry;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    _subscription = Connectivity().onConnectivityChanged.listen((_) => _check());
    _check();
  }

  Future<void> _check() async {
    _retry?.cancel();
    final results = await Connectivity().checkConnectivity();
    final hasNetwork = results.any((r) => r != ConnectivityResult.none);
    final online = hasNetwork && await _reachesInternet();
    isOnline.value = online;
    // The phone won't tell us when the internet comes back on the same
    // network, so keep checking until it does.
    if (!online) _retry = Timer(const Duration(seconds: 5), _check);
  }

  static Future<bool> _reachesInternet() async {
    if (kIsWeb) return true;
    try {
      final result = await InternetAddress.lookup('firestore.googleapis.com').timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _retry?.cancel();
    _started = false;
  }
}
