import 'package:intl/intl.dart';

/// How a chat message is shown. Stored message `type`s are 'text', 'Image'
/// (camera/gallery photos) or the lowercased file extension for other uploads.
enum MessageKind { text, image, video, pdf, file }

const Set<String> _imageExtensions = {'image', 'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif', 'bmp'};
const Set<String> _videoExtensions = {'mp4', 'mov', 'm4v', '3gp', 'webm', 'mkv', 'avi'};

class MessageUtils {
  /// Lowercased extension without the dot, or '' when the name has none
  /// (e.g. "README" or ".env").
  static String fileExtension(String fileName) {
    final int dot = fileName.lastIndexOf('.');
    if (dot <= 0 || dot == fileName.length - 1) return '';
    return fileName.substring(dot + 1).toLowerCase();
  }

  static MessageKind kindForType(String type) {
    final String t = type.toLowerCase();
    if (t == 'text') return MessageKind.text;
    if (_imageExtensions.contains(t)) return MessageKind.image;
    if (_videoExtensions.contains(t)) return MessageKind.video;
    if (t == 'pdf') return MessageKind.pdf;
    return MessageKind.file;
  }

  /// Date chip above a group of messages: 'Today', 'Yesterday' or dd-MM-yyyy.
  /// Compares calendar days, so it also works across month and year ends.
  static String chatDateLabel(DateTime messageTime, DateTime now) {
    final DateTime messageDay = DateTime(messageTime.year, messageTime.month, messageTime.day);
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime yesterday = DateTime(now.year, now.month, now.day - 1);
    if (messageDay == today) return 'Today';
    if (messageDay == yesterday) return 'Yesterday';
    return DateFormat('dd-MM-yyyy').format(messageTime);
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// One-line preview for the chat list.
  static String previewText({required String type, required String message, String fileName = ''}) {
    switch (kindForType(type)) {
      case MessageKind.text:
        return message;
      case MessageKind.image:
        return '📷 Photo';
      case MessageKind.video:
        return '🎥 Video';
      case MessageKind.pdf:
        return '📄 ${fileName.isNotEmpty ? fileName : 'PDF'}';
      case MessageKind.file:
        return '📎 ${fileName.isNotEmpty ? fileName : 'File'}';
    }
  }
}
