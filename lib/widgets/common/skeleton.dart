import 'package:flutter/material.dart';
import 'package:shadcn_kit/shadcn_kit.dart';

/// Placeholder shaped like a [ShadcnListTile] with an avatar.
class SkeletonListTile extends StatelessWidget {
  final double avatarSize;

  /// Pulse on its own. Off inside a [SkeletonList], which pulses as one.
  final bool animate;

  const SkeletonListTile({super.key, this.avatarSize = 52, this.animate = true});

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: ShadcnSpacing.lg, vertical: 10),
      child: Row(
        children: [
          ShadcnSkeleton.circle(size: avatarSize, animate: false),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShadcnSkeleton(width: 140, height: 14, animate: false),
                SizedBox(height: 8),
                ShadcnSkeleton(height: 12, animate: false),
              ],
            ),
          ),
          const SizedBox(width: 24),
          const ShadcnSkeleton(width: 36, height: 10, animate: false),
        ],
      ),
    );
    return animate ? ShadcnSkeletonPulse(child: row) : row;
  }
}

/// A whole list of placeholder rows that pulse together.
class SkeletonList extends StatelessWidget {
  final int count;

  const SkeletonList({super.key, this.count = 8});

  @override
  Widget build(BuildContext context) {
    return ShadcnSkeletonPulse(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        itemBuilder: (_, __) => const SkeletonListTile(animate: false),
      ),
    );
  }
}
