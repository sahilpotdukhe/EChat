import 'package:flutter/material.dart';
import 'package:shadcn_kit/shadcn_kit.dart';
import 'package:lottie/lottie.dart';

/// Covers the screen with a soft panel and a message while something slow
/// (like Google sign-in) runs. Blocks taps underneath.
class BusyOverlay extends StatelessWidget {
  final bool visible;
  final String message;
  final Widget child;

  const BusyOverlay({
    super.key,
    required this.visible,
    required this.child,
    this.message = 'Please wait…',
  });

  @override
  Widget build(BuildContext context) {
    final shadcn = context.shadcn;
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            // Only built while visible, so the animation isn't running hidden.
            child: !visible
                ? const SizedBox.shrink()
                : ColoredBox(
                    color: shadcn.background.withValues(alpha: 0.94),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 140,
                            height: 140,
                            child: Lottie.asset('assets/google_loader.json'),
                          ),
                          ShadcnGap.lg,
                          ShadcnText(message, variant: ShadcnTextVariant.large),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
