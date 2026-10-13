import 'package:cached_network_image/cached_network_image.dart';
import 'package:echat/models/message_model.dart';
import 'package:echat/screens/chat/widgets/message_extras.dart';
import 'package:echat/theme/app_colors.dart';
import 'package:echat/utils/message_utils.dart';
import 'package:echat/widgets/cached_video_player_screen.dart';
import 'package:echat/widgets/full_image_widget.dart';
import 'package:echat/widgets/pdf_viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_kit/shadcn_kit.dart';
import 'package:url_launcher/url_launcher.dart';

/// One chat message.
///
/// [isMe] picks the side and colors. Messages sent close together by the
/// same person form a group: [groupedWithOlder] tightens the gap above, and
/// only the newest in a group ([groupedWithNewer] false) gets the "tail"
/// corner. Long-press a text message to copy it.
class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool groupedWithOlder;
  final bool groupedWithNewer;

  /// Read out before the message by screen readers, e.g. "Priya".
  final String senderName;

  /// Widest the bubble may get (a share of the chat's width).
  final double maxWidth;

  /// Not on the server yet (sent while offline): shows a clock, not ticks.
  final bool isPending;

  /// Long-press: the Copy / Delete menu.
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.senderName,
    required this.maxWidth,
    this.groupedWithOlder = false,
    this.groupedWithNewer = false,
    this.isPending = false,
    this.onLongPress,
  });

  static const double _radius = 18;
  static const double _tail = 4;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final kind = MessageUtils.kindForType(message.type);
    final time = DateFormat.jm().format(message.timestamp.toDate());
    final background = isMe ? colors.bubbleOutgoing : colors.bubbleIncoming;
    final foreground = isMe ? colors.onBubbleOutgoing : colors.onBubbleIncoming;

    const big = Radius.circular(_radius);
    const small = Radius.circular(_tail);
    final hasTail = !groupedWithNewer;
    final shape = BorderRadius.only(
      topLeft: big,
      topRight: big,
      bottomLeft: !isMe && hasTail ? small : big,
      bottomRight: isMe && hasTail ? small : big,
    );

    final Widget meta = MessageMeta(
      time: time,
      color: foreground,
      ticks: isMe && !message.isDeleted ? MessageTicks(status: message.status, pending: isPending, color: foreground) : null,
    );
    final Widget mediaMeta = MessageMeta(
      time: time,
      color: Colors.white,
      ticks: isMe ? MessageTicks(status: message.status, pending: isPending, color: Colors.white) : null,
    );

    final Widget body = switch (kind) {
      MessageKind.text => _TextBody(text: message.message, meta: meta, color: foreground),
      MessageKind.deleted => DeletedMessageBody(isMe: isMe, meta: meta, color: foreground),
      MessageKind.call => CallMessageBody(message: message, isMe: isMe, meta: meta, color: foreground),
      MessageKind.image => _MediaBody(
          url: message.photoUrl,
          heroTag: 'imageHero_${message.photoUrl}',
          meta: mediaMeta,
          maxWidth: maxWidth,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => FullImageWidget(imageUrl: message.photoUrl),
          )),
        ),
      MessageKind.video => _MediaBody(
          url: message.thumbnailUrl,
          isVideo: true,
          meta: mediaMeta,
          maxWidth: maxWidth,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => CachedVideoPlayerScreen(videoUrl: message.photoUrl),
          )),
        ),
      MessageKind.pdf => _FileBody(
          name: _pdfName,
          kindLabel: 'PDF document',
          icon: Icons.picture_as_pdf_outlined,
          iconColor: const Color(0xFFE5484D),
          meta: meta,
          color: foreground,
          maxWidth: maxWidth,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => PdfViewerScreen(
              pdfUrl: message.pdfUrl.isNotEmpty ? message.pdfUrl : message.photoUrl,
              pdfName: _pdfName,
            ),
          )),
        ),
      MessageKind.file => _FileBody(
          name: message.fileName.isNotEmpty ? message.fileName : 'File',
          kindLabel: _fileKindLabel,
          icon: Icons.insert_drive_file_outlined,
          iconColor: context.shadcn.primary,
          meta: meta,
          color: foreground,
          maxWidth: maxWidth,
          onTap: () => _openExternally(context),
        ),
    };

    final preview = MessageUtils.previewText(
      type: message.type,
      message: message.message,
      fileName: message.fileName.isNotEmpty ? message.fileName : message.pdfName,
      callType: message.callType,
      sentByMe: isMe,
    );
    final statusLabel = !isMe || message.isDeleted
        ? ''
        : isPending
            ? ', sending'
            : switch (message.status) {
                MessageStatus.read => ', read',
                MessageStatus.delivered => ', delivered',
                MessageStatus.sent => ', sent',
                _ => '',
              };

    return Padding(
      padding: EdgeInsets.only(left: 12, right: 12, top: groupedWithOlder ? 2 : 10),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Semantics(
            label: '${isMe ? 'You' : senderName}: $preview, $time$statusLabel',
            onLongPressHint: onLongPress == null ? null : 'Message options',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPress: onLongPress == null
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      onLongPress!();
                    },
              child: Material(
                color: message.isDeleted ? background.withValues(alpha: 0.6) : background,
                borderRadius: shape,
                clipBehavior: Clip.antiAlias,
                child: body,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _pdfName {
    final name = message.pdfName.isNotEmpty ? message.pdfName : message.fileName;
    return name.isNotEmpty ? name : 'PDF';
  }

  String get _fileKindLabel {
    final ext = MessageUtils.fileExtension(message.fileName);
    return ext.isEmpty ? 'File' : '${ext.toUpperCase()} file';
  }

  // Files the app can't preview (docx, zip, ...) open in another app.
  Future<void> _openExternally(BuildContext context) async {
    final Uri? uri = Uri.tryParse(message.photoUrl);
    bool opened = false;
    try {
      if (uri != null) opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // No app can handle it; reported below.
    }
    if (!opened && context.mounted) {
      showShadcnToast(context,
          title: 'Couldn\'t open this file',
          description: 'No app on this phone can open it.',
          variant: ShadcnToastVariant.destructive);
    }
  }
}

/// Text with the time tucked in at the end: on the last line when it fits,
/// otherwise on its own line at the right.
class _TextBody extends StatelessWidget {
  final String text;
  final Widget meta;
  final Color color;

  const _TextBody({required this.text, required this.meta, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 9, 12, 7),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: 8,
        children: [
          Text(text, style: TextStyle(color: color, fontSize: 15, height: 1.35)),
          Padding(padding: const EdgeInsets.only(top: 2), child: meta),
        ],
      ),
    );
  }
}

/// A photo or a video thumbnail, with the time on a dark pill in the corner.
class _MediaBody extends StatelessWidget {
  final String url;
  final Widget meta;
  final double maxWidth;
  final VoidCallback onTap;
  final bool isVideo;
  final String? heroTag;

  const _MediaBody({
    required this.url,
    required this.meta,
    required this.maxWidth,
    required this.onTap,
    this.isVideo = false,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final shadcn = context.shadcn;
    final width = maxWidth.clamp(0.0, 260.0);
    final height = width * 0.8;

    Widget fallback(IconData icon) => Container(
          color: isVideo ? Colors.black87 : shadcn.muted,
          alignment: Alignment.center,
          child: Icon(icon, color: isVideo ? Colors.white54 : shadcn.mutedForeground, size: 32),
        );

    Widget picture = url.isEmpty
        ? fallback(isVideo ? Icons.videocam_outlined : Icons.image_outlined)
        : CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 150),
            placeholder: (_, __) => const ShadcnSkeleton(height: double.infinity, borderRadius: BorderRadius.zero),
            errorWidget: (_, __, ___) => fallback(Icons.broken_image_outlined),
          );
    if (heroTag != null) picture = Hero(tag: heroTag!, child: picture);

    return Padding(
      padding: const EdgeInsets.all(3),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: SizedBox(
          width: width,
          height: height,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  picture,
                  if (isVideo)
                    Center(
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                      ),
                    ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                      child: meta,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A PDF or other file: an icon, its name and "Tap to open".
class _FileBody extends StatelessWidget {
  final String name;
  final String kindLabel;
  final IconData icon;
  final Color iconColor;
  final Widget meta;
  final Color color;
  final double maxWidth;
  final VoidCallback onTap;

  const _FileBody({
    required this.name,
    required this.kindLabel,
    required this.icon,
    required this.iconColor,
    required this.meta,
    required this.color,
    required this.maxWidth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: maxWidth.clamp(0.0, 280.0),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 12, 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$kindLabel · Tap to open',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              meta,
            ],
          ),
        ),
      ),
    );
  }
}
