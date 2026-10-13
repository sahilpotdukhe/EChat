import 'dart:async';

import 'package:echat/resources/connectivity_service.dart';
import 'package:echat/theme/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_kit/shadcn_kit.dart';

/// A bar across the top of every screen while the phone is offline
/// ("No internet connection"), which turns green for a moment ("Back
/// online") when the connection returns.
class ConnectivityBanner extends StatefulWidget {
  final Widget child;

  /// Defaults to the app-wide [ConnectivityService]; tests pass their own.
  final ValueListenable<bool>? online;

  const ConnectivityBanner({super.key, required this.child, this.online});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

enum _BannerState { hidden, offline, backOnline }

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  late final ValueListenable<bool> _online = widget.online ?? ConnectivityService.instance.isOnline;
  _BannerState _state = _BannerState.hidden;
  Timer? _hide;

  @override
  void initState() {
    super.initState();
    _online.addListener(_onChanged);
    if (!_online.value) _state = _BannerState.offline;
  }

  @override
  void dispose() {
    _online.removeListener(_onChanged);
    _hide?.cancel();
    super.dispose();
  }

  void _onChanged() {
    _hide?.cancel();
    if (!_online.value) {
      setState(() => _state = _BannerState.offline);
    } else if (_state == _BannerState.offline) {
      setState(() => _state = _BannerState.backOnline);
      _hide = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _state = _BannerState.hidden);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _state != _BannerState.hidden;
    final offline = _state == _BannerState.offline;
    final shadcn = context.shadcn;
    final background = offline ? shadcn.destructive : context.colors.success;

    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: !visible
              ? const SizedBox(width: double.infinity)
              : Material(
                  color: background,
                  child: SafeArea(
                    bottom: false,
                    child: Semantics(
                      liveRegion: true,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(offline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                                size: 16, color: Colors.white),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                offline ? 'No internet connection. Messages will send when you\'re back.' : 'Back online',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ),
        Expanded(
          // The bar already covers the status bar area. Always the same
          // wrapper, so showing the bar never rebuilds the app's screens.
          child: MediaQuery.removePadding(context: context, removeTop: visible, child: widget.child),
        ),
      ],
    );
  }
}
