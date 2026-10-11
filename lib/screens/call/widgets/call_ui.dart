import 'dart:async';

import 'package:echat/widgets/common/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Calls always use a dark violet backdrop, whatever the app theme, so the
/// photo and the controls stand out.
class CallBackground extends StatelessWidget {
  final Widget child;

  const CallBackground({super.key, required this.child});

  static const top = Color(0xFF241C52);
  static const bottom = Color(0xFF0B0B12);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, bottom]),
        ),
        child: DefaultTextStyle.merge(style: const TextStyle(color: Colors.white), child: child),
      ),
    );
  }
}

enum CallButtonTone { normal, end, accept }

/// A round call control with its label underneath ("Mute", "End"…).
///
/// [active] shows a toggle as switched on (white circle, dark icon), e.g.
/// muted or speaker on.
class CallControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool active;
  final CallButtonTone tone;
  final double size;

  const CallControlButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.active = false,
    this.tone = CallButtonTone.normal,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final (Color fill, Color iconColor) = switch (tone) {
      CallButtonTone.end => (const Color(0xFFE5484D), Colors.white),
      CallButtonTone.accept => (const Color(0xFF22C55E), Colors.white),
      CallButtonTone.normal => active ? (Colors.white, const Color(0xFF16161D)) : (Colors.white24, Colors.white),
    };

    return Semantics(
      button: true,
      enabled: enabled,
      toggled: tone == CallButtonTone.normal ? active : null,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: fill,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onPressed == null
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        onPressed!();
                      },
                child: SizedBox.square(
                  dimension: size,
                  child: Icon(icon, color: iconColor, size: size * 0.45),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

/// A profile photo with soft rings pulsing out from it while a call rings.
class PulsingAvatar extends StatefulWidget {
  final String name;
  final String imageUrl;
  final double size;
  final bool pulsing;

  const PulsingAvatar({super.key, required this.name, required this.imageUrl, this.size = 128, this.pulsing = true});

  @override
  State<PulsingAvatar> createState() => _PulsingAvatarState();
}

class _PulsingAvatarState extends State<PulsingAvatar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulsing) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant PulsingAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulsing && !_controller.isAnimating) _controller.repeat();
    if (!widget.pulsing && _controller.isAnimating) _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final ringSpace = widget.size * 0.35;
    return SizedBox.square(
      dimension: widget.size + ringSpace * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.pulsing && !reduceMotion)
            for (final offset in [0.0, 0.5])
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final t = (_controller.value + offset) % 1.0;
                  return Container(
                    width: widget.size + ringSpace * 2 * t,
                    height: widget.size + ringSpace * 2 * t,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.14 * (1 - t)),
                    ),
                  );
                },
              ),
          UserAvatar(name: widget.name, imageUrl: widget.imageUrl, size: widget.size),
        ],
      ),
    );
  }
}

/// "04:27" counting up from [since], updated every second.
class CallDuration extends StatefulWidget {
  final DateTime since;
  final TextStyle? style;

  const CallDuration({super.key, required this.since, this.style});

  @override
  State<CallDuration> createState() => _CallDurationState();
}

class _CallDurationState extends State<CallDuration> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = CallDurationFormat.format(DateTime.now().difference(widget.since));
    return Semantics(
      label: 'Call time $text',
      excludeSemantics: true,
      child: Text(text, style: widget.style ?? const TextStyle(fontSize: 15, color: Colors.white70)),
    );
  }
}

/// "04:27", or "1:02:03" past an hour.
class CallDurationFormat {
  static String format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }
}
