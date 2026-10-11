import 'package:flutter/material.dart';
import 'package:shadcn_kit/shadcn_kit.dart';

/// A titled card of rows, like a settings group: "DETAILS" above a card with
/// thin lines between its [InfoRow]s. Empty sections draw nothing.
class InfoSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  /// Small grey line under the card, e.g. a tip.
  final String? footer;

  const InfoSection({super.key, this.title, required this.children, this.footer});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    final t = context.shadcn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: ShadcnText(
              title!.toUpperCase(),
              variant: ShadcnTextVariant.muted,
              style: const ShadcnTextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8),
            ),
          ),
        ShadcnCard(
          padding: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (i, row) in children.indexed) ...[
                if (i > 0) Padding(padding: const EdgeInsets.only(left: 56), child: Divider(color: t.border)),
                row,
              ],
            ],
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 8),
            child: ShadcnText(footer!, variant: ShadcnTextVariant.muted),
          ),
      ],
    );
  }
}

/// One row in an [InfoSection]: an icon, a main line, an optional smaller
/// line, and a chevron when it can be tapped.
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// For "Log out"-style rows.
  final bool destructive;
  final String? semanticLabel;

  const InfoRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.destructive = false,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.shadcn;
    final color = destructive ? t.destructive : t.foreground;
    return ShadcnListTile(
      leading: Icon(icon, color: destructive ? t.destructive : t.mutedForeground, size: 22),
      gap: 18,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      titleStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: color),
      subtitleStyle: TextStyle(fontSize: 12, color: t.mutedForeground),
      trailing: trailing ?? (onTap == null || destructive ? null : const Icon(Icons.chevron_right_rounded)),
      onTap: onTap,
      onLongPress: onLongPress,
      semanticLabel: semanticLabel,
    );
  }
}
