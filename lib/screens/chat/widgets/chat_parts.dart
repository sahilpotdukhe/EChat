import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/enums/user_state.dart';
import 'package:echat/models/user_model.dart';
import 'package:echat/theme/app_colors.dart';
import 'package:echat/utils/utilities.dart';
import 'package:echat/widgets/common/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_kit/shadcn_kit.dart';

/// The chat's top bar title: the other person's photo with a live online
/// dot, their name, and "Online" / "Tap to view profile" underneath.
class ChatHeaderTitle extends StatelessWidget {
  final UserModel receiver;

  /// Live copy of the receiver's profile, for their online state. While it
  /// loads, [receiver] (passed in when the chat opened) is shown.
  final Stream<DocumentSnapshot> receiverStream;
  final VoidCallback? onTap;

  const ChatHeaderTitle({
    super.key,
    required this.receiver,
    required this.receiverStream,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shadcn = context.shadcn;
    return StreamBuilder<DocumentSnapshot>(
      stream: receiverStream,
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final user = data == null ? receiver : UserModel.fromMap(data);
        final online = Utils.numToState(user.state) == UserState.online;
        final name = user.name.isEmpty ? 'EChat user' : user.name;

        return Semantics(
          button: onTap != null,
          label: '$name${online ? ', online' : ''}. View profile',
          excludeSemantics: true,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(shadcn.radiusLg),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                children: [
                  UserAvatar(name: user.name, imageUrl: user.profilePhoto, size: 38, isOnline: online),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: shadcn.foreground),
                        ),
                        Text(
                          online ? 'Online' : 'Tap to view profile',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: online ? context.colors.success : shadcn.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// "Today" / "Yesterday" / a date, centered between messages of different
/// days.
class DateChip extends StatelessWidget {
  final String label;

  const DateChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final shadcn = context.shadcn;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Center(
        child: ShadcnBadge(
          variant: ShadcnBadgeVariant.outline,
          style: ShadcnBadgeStyle(
            backgroundColor: shadcn.card,
            foregroundColor: shadcn.mutedForeground,
            borderColor: shadcn.border,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

/// The outgoing "Sending photo… 45%" bubble shown while a file uploads.
class UploadBubble extends StatelessWidget {
  /// 0–1, or null while the upload hasn't reported progress yet.
  final double? progress;

  const UploadBubble({super.key, this.progress});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final percent = progress == null || progress! <= 0 ? null : (progress! * 100).clamp(0, 100).round();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          width: 220,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: colors.bubbleOutgoing.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Semantics(
            liveRegion: true,
            label: percent == null ? 'Sending file' : 'Sending file, $percent percent',
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.upload_rounded, size: 18, color: colors.onBubbleOutgoing),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        percent == null ? 'Sending…' : 'Sending… $percent%',
                        style: TextStyle(color: colors.onBubbleOutgoing, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent == null ? null : percent / 100,
                    minHeight: 4,
                    color: colors.onBubbleOutgoing,
                    backgroundColor: colors.onBubbleOutgoing.withValues(alpha: 0.25),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
