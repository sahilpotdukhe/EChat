import 'package:echat/models/message_model.dart';
import 'package:echat/utils/message_utils.dart';
import 'package:flutter/material.dart';

/// Bright enough to stand out from the white "delivered" ticks on the
/// violet bubble, in light and dark mode.
const Color readTickColor = Color(0xFF7DD3FC);

/// The time at the bottom-right of a bubble, plus ticks on your own
/// messages.
class MessageMeta extends StatelessWidget {
  final String time;
  final Color color;
  final Widget? ticks;

  const MessageMeta(
      {super.key, required this.time, required this.color, this.ticks});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(time,
            style:
                TextStyle(color: color.withValues(alpha: 0.65), fontSize: 11)),
        if (ticks != null) ...[const SizedBox(width: 3), ticks!],
      ],
    );
  }
}

/// WhatsApp's ticks: 🕓 not sent yet (offline), ✓ sent, ✓✓ delivered to
/// their phone, blue ✓✓ read. Messages from before ticks existed show none.
class MessageTicks extends StatelessWidget {
  final String status;
  final bool pending;
  final Color color;

  const MessageTicks(
      {super.key,
      required this.status,
      required this.pending,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final muted = color.withValues(alpha: 0.7);
    final (IconData? icon, Color tint, String label) = pending
        ? (Icons.schedule_rounded, muted, 'Sending')
        : switch (status) {
            MessageStatus.read => (
                Icons.done_all_rounded,
                readTickColor,
                'Read'
              ),
            MessageStatus.delivered => (
                Icons.done_all_rounded,
                muted,
                'Delivered'
              ),
            MessageStatus.sent => (Icons.done_rounded, muted, 'Sent'),
            _ => (null, muted, ''),
          };
    if (icon == null) return const SizedBox.shrink();
    return Tooltip(
      message: label,
      child: Icon(icon, size: pending ? 13 : 16, color: tint),
    );
  }
}

/// "This message was deleted", in italics with a 🚫 icon.
class DeletedMessageBody extends StatelessWidget {
  final bool isMe;
  final Widget meta;
  final Color color;

  const DeletedMessageBody(
      {super.key, required this.isMe, required this.meta, required this.color});

  @override
  Widget build(BuildContext context) {
    final faded = color.withValues(alpha: 0.75);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 7),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: 8,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.block_rounded, size: 15, color: faded),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  isMe
                      ? 'You deleted this message'
                      : 'This message was deleted',
                  style: TextStyle(
                      color: faded,
                      fontSize: 14.5,
                      fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
          meta,
        ],
      ),
    );
  }
}

/// A call in the chat, like WhatsApp: a round phone/video icon, "Voice
/// call" / "Missed voice call" and how long you talked.
class CallMessageBody extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final Widget meta;
  final Color color;

  const CallMessageBody({
    super.key,
    required this.message,
    required this.isMe,
    required this.meta,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final missed = message.isMissedCall;
    final title = MessageUtils.callTitle(
        callType: message.callType, answered: !missed, sentByMe: isMe);
    final IconData icon = message.isVideoCall
        ? (missed ? Icons.missed_video_call_rounded : Icons.videocam_rounded)
        : missed
            ? (isMe ? Icons.call_made_rounded : Icons.call_missed_rounded)
            : (isMe ? Icons.call_made_rounded : Icons.call_received_rounded);
    final Color iconColor = missed && !isMe ? const Color(0xFFE5484D) : color;
    // A call nobody answered has no length to show.
    final String? subtitle =
        missed ? null : MessageUtils.callDurationLabel(message.callDuration);

    return SizedBox(
      width: 230,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 12, 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      shape: BoxShape.circle),
                  child: Icon(icon, size: 21, color: iconColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: color,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: color.withValues(alpha: 0.7),
                              fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            meta,
          ],
        ),
      ),
    );
  }
}
