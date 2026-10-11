import 'package:echat/Utils/MessageUtils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('chatDateLabel', () {
    test('same calendar day is Today', () {
      expect(MessageUtils.chatDateLabel(DateTime(2026, 10, 11, 0, 5), DateTime(2026, 10, 11, 23, 50)), 'Today');
    });

    test('previous day is Yesterday', () {
      expect(MessageUtils.chatDateLabel(DateTime(2026, 10, 10, 23, 59), DateTime(2026, 10, 11, 0, 1)), 'Yesterday');
    });

    test('Yesterday across a month boundary (the old day - 1 bug)', () {
      expect(MessageUtils.chatDateLabel(DateTime(2026, 9, 30, 18), DateTime(2026, 10, 1, 9)), 'Yesterday');
    });

    test('Yesterday across a year boundary', () {
      expect(MessageUtils.chatDateLabel(DateTime(2025, 12, 31, 22), DateTime(2026, 1, 1, 8)), 'Yesterday');
    });

    test('Yesterday on 1 March in a leap year', () {
      expect(MessageUtils.chatDateLabel(DateTime(2028, 2, 29), DateTime(2028, 3, 1)), 'Yesterday');
    });

    test('same day number in an earlier month is a date, not Today', () {
      expect(MessageUtils.chatDateLabel(DateTime(2026, 9, 11, 10), DateTime(2026, 10, 11, 10)), '11-09-2026');
    });

    test('older messages show dd-MM-yyyy', () {
      expect(MessageUtils.chatDateLabel(DateTime(2026, 10, 9), DateTime(2026, 10, 11)), '09-10-2026');
    });
  });

  group('fileExtension', () {
    test('lowercases the extension', () {
      expect(MessageUtils.fileExtension('Holiday.JPG'), 'jpg');
    });

    test('uses the last dot', () {
      expect(MessageUtils.fileExtension('archive.tar.gz'), 'gz');
    });

    test('no extension gives an empty string', () {
      expect(MessageUtils.fileExtension('README'), '');
      expect(MessageUtils.fileExtension('.env'), '');
      expect(MessageUtils.fileExtension('trailing.'), '');
    });
  });

  group('kindForType', () {
    test('text', () => expect(MessageUtils.kindForType('text'), MessageKind.text));

    test('photos, including the camera type and uppercase extensions', () {
      for (final type in ['Image', 'jpg', 'JPEG', 'png', 'heic', 'webp']) {
        expect(MessageUtils.kindForType(type), MessageKind.image, reason: type);
      }
    });

    test('videos beyond mp4', () {
      for (final type in ['mp4', 'MOV', 'm4v', '3gp', 'webm', 'mkv']) {
        expect(MessageUtils.kindForType(type), MessageKind.video, reason: type);
      }
    });

    test('pdf', () => expect(MessageUtils.kindForType('PDF'), MessageKind.pdf));

    test('anything else is a generic file, not an image', () {
      for (final type in ['docx', 'zip', 'file', '']) {
        expect(MessageUtils.kindForType(type), MessageKind.file, reason: type);
      }
    });
  });

  group('previewText', () {
    test('text shows the message', () {
      expect(MessageUtils.previewText(type: 'text', message: 'hello'), 'hello');
    });

    test('media shows a label, not the raw type', () {
      expect(MessageUtils.previewText(type: 'Image', message: 'IMAGE'), '📷 Photo');
      expect(MessageUtils.previewText(type: 'mov', message: 'mov'), '🎥 Video');
      expect(MessageUtils.previewText(type: 'pdf', message: 'pdf', fileName: 'cv.pdf'), '📄 cv.pdf');
      expect(MessageUtils.previewText(type: 'docx', message: 'docx', fileName: 'notes.docx'), '📎 notes.docx');
      expect(MessageUtils.previewText(type: 'zip', message: 'zip'), '📎 File');
    });
  });
}
