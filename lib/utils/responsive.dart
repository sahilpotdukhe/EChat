import 'package:flutter/material.dart';

/// Screen-size buckets. Phones are compact, small tablets / landscape phones
/// are medium, and big tablets / desktops are expanded.
enum ScreenSize { compact, medium, expanded }

class Breakpoints {
  static const double medium = 600;
  static const double expanded = 840;

  /// The widest a form or reading column should get, so text fields don't
  /// stretch across a whole tablet.
  static const double formMaxWidth = 440;
  static const double contentMaxWidth = 720;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  ScreenSize get screenSize {
    final width = screenWidth;
    if (width >= Breakpoints.expanded) return ScreenSize.expanded;
    if (width >= Breakpoints.medium) return ScreenSize.medium;
    return ScreenSize.compact;
  }

  bool get isCompact => screenSize == ScreenSize.compact;
  bool get isExpanded => screenSize == ScreenSize.expanded;

  /// Short and wide, e.g. a phone turned sideways.
  bool get isLandscapeShort => screenHeight < 500 && screenWidth > screenHeight;

  /// Side padding that grows a little on bigger screens.
  double get pagePadding => switch (screenSize) {
        ScreenSize.compact => 20,
        ScreenSize.medium => 32,
        ScreenSize.expanded => 40,
      };
}

/// Centers [child] and stops it growing wider than [maxWidth].
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.contentMaxWidth,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
