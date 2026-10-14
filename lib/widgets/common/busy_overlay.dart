import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shadcn_kit/shadcn_kit.dart';
import 'package:lottie/lottie.dart';

/// Covers the screen with a blurred backdrop and a small card while
/// something slow (like Google sign-in) runs. Blocks taps underneath.
class BusyOverlay extends StatelessWidget {
  final bool visible;
  final String message;

  /// A smaller line under [message], e.g. what to do meanwhile.
  final String? hint;
  final Widget child;

  const BusyOverlay({
    super.key,
    required this.visible,
    required this.child,
    this.message = 'Please wait…',
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final shadcn = context.shadcn;
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            // Only built while visible, so the animation isn't running hidden.
            child: !visible
                ? const SizedBox.shrink()
                // The overlay sits above the page's Scaffold, so it needs its
                // own Material: without one, text gets Flutter's yellow
                // "missing Material" underline.
                : Material(
                    type: MaterialType.transparency,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: ColoredBox(
                        color: shadcn.background.withValues(alpha: 0.72),
                        child: Center(
                          child: Semantics(
                            liveRegion: true,
                            label: hint == null ? message : '$message. $hint',
                            excludeSemantics: true,
                            child: _Card(message: message, hint: hint),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final String message;
  final String? hint;

  const _Card({required this.message, this.hint});

  @override
  Widget build(BuildContext context) {
    final shadcn = context.shadcn;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        color: shadcn.card,
        borderRadius: BorderRadius.circular(shadcn.radiusLg * 1.5),
        border: Border.all(color: shadcn.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 32, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 120, height: 120, child: Lottie.asset('assets/google_loader.json')),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: shadcn.foreground,
              decoration: TextDecoration.none,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 6),
            Text(
              hint!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: shadcn.mutedForeground,
                decoration: TextDecoration.none,
              ),
            ),
          ],
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              minHeight: 3,
              color: shadcn.primary,
              backgroundColor: shadcn.muted,
            ),
          ),
        ],
      ),
    );
  }
}
