import 'package:echat/Models/MessageModel.dart';
import 'package:echat/Utils/MessageUtils.dart';
import 'package:echat/Utils/ScreenDimensions.dart';
import 'package:echat/Utils/UniversalVariables.dart';
import 'package:echat/Widgets/CachedChatImage.dart';
import 'package:echat/Widgets/CachedVideoPlayer.dart';
import 'package:echat/Widgets/FullImageWidget.dart';
import 'package:echat/Widgets/PdfViewerScreen.dart';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// One chat message. [isMe] picks the side, colours and corner shape.
class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const MessageBubble({super.key, required this.message, required this.isMe});

  Color get _textColor => isMe ? Colors.white : Colors.black;

  @override
  Widget build(BuildContext context) {
    final Radius corner = Radius.circular(10 * ScaleUtils.scaleFactor);
    return Container(
      margin: isMe
          ? EdgeInsets.fromLTRB(0, 12 * ScaleUtils.verticalScale, 12 * ScaleUtils.horizontalScale, 0)
          : EdgeInsets.only(top: 12 * ScaleUtils.verticalScale),
      constraints: BoxConstraints(maxWidth: ScaleUtils.width * 0.75),
      decoration: BoxDecoration(
          gradient: isMe ? UniversalVariables.appGradient : null,
          color: isMe ? null : HexColor('aeb9cc'),
          borderRadius: isMe
              ? BorderRadius.only(topLeft: corner, topRight: corner, bottomLeft: corner)
              : BorderRadius.only(bottomRight: corner, topRight: corner, bottomLeft: corner)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [_content(context)],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(8.0 * ScaleUtils.horizontalScale, 8 * ScaleUtils.verticalScale,
                    8 * ScaleUtils.horizontalScale, 4 * ScaleUtils.verticalScale),
                child: Text(
                  DateFormat.jm().format(message.timestamp.toDate()),
                  textAlign: TextAlign.end,
                  style: TextStyle(color: _textColor, fontSize: 13 * ScaleUtils.scaleFactor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context) {
    final EdgeInsets mediaPadding = EdgeInsets.fromLTRB(
        8.0 * ScaleUtils.horizontalScale, 8 * ScaleUtils.verticalScale, 8 * ScaleUtils.horizontalScale, 0);
    final double side = 250;

    switch (MessageUtils.kindForType(message.type)) {
      case MessageKind.text:
        return Flexible(
          child: Padding(
            padding: EdgeInsets.fromLTRB(12 * ScaleUtils.horizontalScale, 8 * ScaleUtils.verticalScale,
                20 * ScaleUtils.horizontalScale, 0),
            child: Text(
              message.message,
              textAlign: TextAlign.start,
              style: TextStyle(color: _textColor, fontSize: 15 * ScaleUtils.scaleFactor),
            ),
          ),
        );

      case MessageKind.video:
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CachedVideoPlayerScreen(videoUrl: message.photoUrl)),
          ),
          child: Padding(
            padding: mediaPadding,
            child: Stack(
              children: [
                // No thumbnail (it couldn't be made): plain dark box with the play icon.
                message.thumbnailUrl.isEmpty
                    ? Container(
                        height: side * ScaleUtils.verticalScale,
                        width: side * ScaleUtils.horizontalScale,
                        decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(10 * ScaleUtils.scaleFactor)),
                      )
                    : CachedChatImage(
                        imageUrl: message.thumbnailUrl,
                        height: side * ScaleUtils.verticalScale,
                        width: side * ScaleUtils.horizontalScale,
                        radius: 10 * ScaleUtils.scaleFactor,
                        isRound: false,
                        fit: BoxFit.cover,
                      ),
                SizedBox(
                  width: side * ScaleUtils.horizontalScale,
                  height: side * ScaleUtils.verticalScale,
                  child: Center(
                    child: Icon(Icons.play_circle, size: 70 * ScaleUtils.scaleFactor, color: Colors.white),
                  ),
                )
              ],
            ),
          ),
        );

      case MessageKind.pdf:
        final String name = message.pdfName.isNotEmpty ? message.pdfName : message.fileName;
        return Padding(
          padding: mediaPadding,
          child: GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => PdfViewerScreen(
                        pdfUrl: message.pdfUrl.isNotEmpty ? message.pdfUrl : message.photoUrl,
                        pdfName: name.isNotEmpty ? name : 'PDF'))),
            child: _fileCard(Icons.picture_as_pdf_outlined, Colors.red, name.isNotEmpty ? name : 'PDF'),
          ),
        );

      case MessageKind.image:
        return Padding(
          padding: mediaPadding,
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) {
              return FullImageWidget(imageUrl: message.photoUrl);
            })),
            child: Hero(
              tag: "imageHero_${message.photoUrl}",
              child: CachedChatImage(
                imageUrl: message.photoUrl,
                height: side * ScaleUtils.verticalScale,
                width: side * ScaleUtils.horizontalScale,
                radius: 10 * ScaleUtils.scaleFactor,
                isRound: false,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );

      case MessageKind.file:
        final String name = message.fileName.isNotEmpty ? message.fileName : 'File';
        return Padding(
          padding: mediaPadding,
          child: GestureDetector(
            onTap: () => _openExternally(context),
            child: _fileCard(Icons.insert_drive_file_outlined, UniversalVariables.appThemeColor, name),
          ),
        );
    }
  }

  Widget _fileCard(IconData icon, Color iconColor, String name) {
    return Container(
      height: 250 * ScaleUtils.verticalScale,
      width: 250 * ScaleUtils.horizontalScale,
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(14.0 * ScaleUtils.scaleFactor),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 100 * ScaleUtils.scaleFactor, color: iconColor),
            Text(
              name,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20 * ScaleUtils.scaleFactor),
            )
          ],
        ),
      ),
    );
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Couldn't open this file")));
    }
  }
}
