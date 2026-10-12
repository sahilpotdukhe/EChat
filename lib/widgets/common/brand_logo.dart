import 'package:flutter/material.dart';
import 'package:shadcn_kit/shadcn_kit.dart';

/// The EChat mark (the same logo as the app icon and splash screen),
/// optionally followed by the name.
class BrandLogo extends StatelessWidget {
  final double size;
  final bool showName;

  /// Use on a colored (brand gradient) background: the dark purple logo
  /// sits on a white tile so it stays visible.
  final bool onBrand;

  const BrandLogo({super.key, this.size = 44, this.showName = true, this.onBrand = false});

  @override
  Widget build(BuildContext context) {
    final shadcn = context.shadcn;
    final image = Image.asset(
      'assets/brand_mark.png',
      width: onBrand ? size * 0.7 : size,
      height: onBrand ? size * 0.7 : size,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
    );
    final mark = onBrand
        ? Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(size * 0.3),
            ),
            child: image,
          )
        : image;
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
