import 'package:flutter/material.dart';
import 'package:shadcn_kit/shadcn_kit.dart';

enum AttachmentChoice { gallery, camera, video, pdf, document }

/// Asks what to share and returns the choice, or null if the sheet was
/// closed without picking.
Future<AttachmentChoice?> showAttachmentSheet(BuildContext context) {
  return showShadcnSheet<AttachmentChoice>(
    context: context,
    builder: (context) => const ShadcnSheet(
      title: 'Share',
      description: 'Send a photo, video or file in this chat.',
      content: _AttachmentGrid(),
    ),
  );
}

class _AttachmentGrid extends StatelessWidget {
  const _AttachmentGrid();

  static const _options = [
    (AttachmentChoice.gallery, 'Gallery', Icons.photo_library_outlined, Color(0xFF6C5CE7)),
    (AttachmentChoice.camera, 'Camera', Icons.photo_camera_outlined, Color(0xFFE17055)),
    (AttachmentChoice.video, 'Video', Icons.videocam_outlined, Color(0xFF0984E3)),
    (AttachmentChoice.pdf, 'PDF', Icons.picture_as_pdf_outlined, Color(0xFFE5484D)),
    (AttachmentChoice.document, 'Document', Icons.description_outlined, Color(0xFF00A884)),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.shadcn;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      // One even row: five options fit on every phone width.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (choice, label, icon, color) in _options)
            Expanded(
              child: Semantics(
                button: true,
                label: label,
                excludeSemantics: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(t.radiusLg),
                  onTap: () => Navigator.of(context).pop(choice),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 26),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: t.foreground),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
