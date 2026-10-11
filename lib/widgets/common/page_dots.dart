import 'package:flutter/material.dart';
import 'package:shadcn_kit/shadcn_kit.dart';

/// Page indicator: the current page is a wide pill, the others are dots.
class PageDots extends StatelessWidget {
  final int count;
  final int current;

  const PageDots({super.key, required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    final shadcn = context.shadcn;
    return Semantics(
      label: 'Page ${current + 1} of $count',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(count, (i) {
          final active = i == current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: active ? shadcn.primary : shadcn.border,
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }),
      ),
    );
  }
}
