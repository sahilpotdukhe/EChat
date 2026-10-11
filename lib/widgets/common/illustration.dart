import 'package:flutter/material.dart';
import 'package:shadcn_kit/shadcn_kit.dart';

/// An illustration sitting on a soft tinted circle, so it reads well on both
/// light and dark backgrounds. It scales down to fit the space it is given.
class Illustration extends StatelessWidget {
  final String asset;
  final double maxSize;

  /// Draw the circle in translucent white, for use on the brand gradient.
  final bool onBrand;

  const Illustration({super.key, required this.asset, this.maxSize = 280, this.onBrand = false});

  @override
  Widget build(BuildContext context) {
    final shadcn = context.shadcn;
    return LayoutBuilder(builder: (context, constraints) {
      final size = [maxSize, constraints.maxWidth, constraints.maxHeight]
          .where((v) => v.isFinite)
          .reduce((a, b) => a < b ? a : b);
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size * 0.86,
              height: size * 0.86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: onBrand ? Colors.white.withValues(alpha: 0.12) : shadcn.accent,
              ),
            ),
            Image.asset(asset, width: size, height: size, fit: BoxFit.contain),
          ],
        ),
      );
    });
  }
}
