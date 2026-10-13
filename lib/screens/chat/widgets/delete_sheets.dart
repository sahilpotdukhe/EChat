import 'package:flutter/material.dart';
import 'package:shadcn_kit/shadcn_kit.dart';

enum MessageAction { copy, deleteForMe, deleteForEveryone }

/// Long-press menu for one message. "Delete for everyone" is only offered
/// for your own messages. Returns null if closed without choosing.
Future<MessageAction?> showMessageActionsSheet(
  BuildContext context, {
  required bool canCopy,
  required bool canDeleteForEveryone,
}) {
  return showShadcnSheet<MessageAction>(
    context: context,
    builder: (context) => ShadcnSheet(
      title: 'Message',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canCopy) _Option(icon: Icons.copy_rounded, label: 'Copy', value: MessageAction.copy),
          const _Option(
            icon: Icons.delete_outline_rounded,
            label: 'Delete for me',
            description: 'Removed from this chat on your side only.',
            value: MessageAction.deleteForMe,
            destructive: true,
          ),
          if (canDeleteForEveryone)
            const _Option(
              icon: Icons.delete_forever_outlined,
              label: 'Delete for everyone',
              description: 'Both of you will see "This message was deleted".',
              value: MessageAction.deleteForEveryone,
              destructive: true,
            ),
        ],
      ),
    ),
  );
}

/// Asks how to delete a whole chat: true for everyone, false for just me,
/// null if cancelled.
Future<bool?> showDeleteChatSheet(BuildContext context, {required String name}) {
  final who = name.trim().isEmpty ? 'this person' : name.trim();
  return showShadcnSheet<bool>(
    context: context,
    builder: (context) => ShadcnSheet(
      title: 'Delete this chat?',
      description: 'All messages, photos and files in your chat with $who will be removed. This can\'t be undone.',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Option(
            icon: Icons.delete_outline_rounded,
            label: 'Delete for me',
            description: 'They keep their copy of the chat.',
            value: false,
            destructive: true,
          ),
          _Option(
            icon: Icons.delete_forever_outlined,
            label: 'Delete for everyone',
            description: 'Also removes the chat from $who\'s phone.',
            value: true,
            destructive: true,
          ),
        ],
      ),
    ),
  );
}

class _Option<T> extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? description;
  final T value;
  final bool destructive;

  const _Option({
    required this.icon,
    required this.label,
    required this.value,
    this.description,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.shadcn;
    final color = destructive ? t.destructive : t.foreground;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(t.radiusLg)),
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      subtitle: description == null
          ? null
          : Text(description!, style: TextStyle(color: t.mutedForeground, fontSize: 12.5)),
      onTap: () => Navigator.of(context).pop(value),
    );
  }
}
