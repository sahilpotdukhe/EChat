import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

/// Turns the other person's `typing_at` into a yes/no for "typing…".
///
/// Their phone refreshes `typing_at` about every 3 seconds while they type.
/// Each new value shows "typing…" for [window], counted on this phone from
/// when it arrived, so a phone with the wrong time can't break it. The value
/// already there when this first appears only counts if it is recent by the
/// server's clock.
class TypingWatcher extends StatefulWidget {
  final Timestamp? typingAt;
  final Widget Function(BuildContext context, bool typing) builder;

  static const Duration window = Duration(seconds: 6);

  const TypingWatcher({super.key, required this.typingAt, required this.builder});

  @override
  State<TypingWatcher> createState() => _TypingWatcherState();
}

class _TypingWatcherState extends State<TypingWatcher> {
  bool _typing = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final at = widget.typingAt;
    if (at != null) {
      final left = TypingWatcher.window - DateTime.now().difference(at.toDate());
      if (left > Duration.zero && left <= TypingWatcher.window) _show(left);
    }
  }

  @override
  void didUpdateWidget(covariant TypingWatcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.typingAt == oldWidget.typingAt) return;
    if (widget.typingAt == null) {
      _timer?.cancel();
      _typing = false;
    } else {
      _show(TypingWatcher.window);
    }
  }

  void _show(Duration duration) {
    _typing = true;
    _timer?.cancel();
    _timer = Timer(duration, () {
      if (mounted) setState(() => _typing = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _typing);
}
