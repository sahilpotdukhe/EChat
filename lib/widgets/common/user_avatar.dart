import 'package:cached_network_image/cached_network_image.dart';
import 'package:echat/theme/app_colors.dart';
import 'package:echat/utils/utilities.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_kit/shadcn_kit.dart';

/// A round profile picture built on [ShadcnAvatar].
///
/// Shows the person's initials, on a color picked from their name, while the
/// photo loads or when there is no photo / it fails to load. Photos are
/// cached on the device. Set [isOnline] to draw a green dot in the corner.
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final bool isOnline;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 48,
    this.isOnline = false,
    this.onTap,
  });

  static const _palette = [
    Color(0xFF6C5CE7),
    Color(0xFF00A884),
    Color(0xFFE17055),
    Color(0xFF0984E3),
    Color(0xFFD63384),
    Color(0xFFF59F00),
    Color(0xFF20C997),
    Color(0xFF845EF7),
  ];

  Color get _tint {
    final hash = name.codeUnits.fold<int>(0, (a, b) => (a * 31 + b) & 0x7fffffff);
    return _palette[hash % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shadcn = context.shadcn;
    final url = imageUrl ?? '';
    final initials = Utils.getInitials(name);
    final background = _tint.withValues(alpha: 0.16);
    final label = isOnline ? '$name, online' : name;

    final avatar = url.isEmpty
        ? ShadcnAvatar.fallback(
            initials: initials,
            size: size,
            backgroundColor: background,
            foregroundColor: _tint,
            semanticLabel: label,
            onTap: onTap,
          )
        : ShadcnAvatar.provider(
            CachedNetworkImageProvider(url),
            initials: initials,
            size: size,
            backgroundColor: background,
            foregroundColor: _tint,
            semanticLabel: label,
            onTap: onTap,
          );

    if (!isOnline) return avatar;

    final dotSize = (size * 0.28).clamp(10.0, 16.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: colors.online,
                shape: BoxShape.circle,
                // Ring in the page color so the dot stands off the photo.
                border: Border.all(color: shadcn.background, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
