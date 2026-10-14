import 'package:flutter/material.dart';
import 'package:shadcn_kit/shadcn_kit.dart';

/// The EChat mark: the app icon (`assets/logo.png`), optionally followed by
/// the name.
class BrandLogo extends StatelessWidget {
  final double size;
  final bool showName;

  /// Use on a colored (brand gradient) background.
  final bool onBrand;

  const BrandLogo({super.key, this.size = 44, this.showName = true, this.onBrand = false});

  @override
  Widget build(BuildContext context) {
    final shadcn = context.shadcn;
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.225),
        boxShadow: onBrand
            ? null
            : [
                BoxShadow(
                  color: shadcn.primary.withValues(alpha: 0.35),
                  blurRadius: size * 0.4,
                  offset: Offset(0, size * 0.12),
                ),
              ],
      ),
      child: Image.asset('assets/logo.png', width: size, height: size, filterQuality: FilterQuality.medium),
    );
    if (!showName) return mark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: size * 0.28),
        Text(
          'EChat',
          style: TextStyle(
            fontSize: size * 0.5,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: onBrand ? Colors.white : shadcn.foreground,
          ),
        ),
      ],
    );
  }
}
