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

  /// Time shown on the right of a chat-list row: the time for today,
  /// 'Yesterday', the weekday within the last week, otherwise dd/MM/yy.
  static String chatListTime(DateTime messageTime, DateTime now) {
    final DateTime messageDay = DateTime(messageTime.year, messageTime.month, messageTime.day);
    final DateTime today = DateTime(now.year, now.month, now.day);
    // Rounded so a 23- or 25-hour daylight-saving day still counts as one.
    final int daysAgo = (today.difference(messageDay).inHours / 24).round();
    if (daysAgo <= 0) return DateFormat.jm().format(messageTime);
    if (daysAgo == 1) return 'Yesterday';
    if (daysAgo < 7) return DateFormat.E().format(messageTime);
    return DateFormat('dd/MM/yy').format(messageTime);
  }

  /// Messages close together from the same sender are drawn as one group:
  /// tighter spacing and a single "tail" corner. True when [a] and [b] are
  /// from the same sender, on the same day and at most [gap] apart.
  static bool groupsWith({
    required String senderA,
    required DateTime timeA,
    required String senderB,
    required DateTime timeB,
    Duration gap = const Duration(minutes: 5),
  }) {
    return senderA == senderB &&
        isSameDay(timeA, timeB) &&
        timeA.difference(timeB).abs() <= gap;
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
