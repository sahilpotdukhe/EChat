import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/models/call_model.dart';
import 'package:echat/models/message_model.dart';
import 'package:echat/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

// Old documents in Firestore are missing fields added later; reading them must
// fall back to defaults instead of crashing.
void main() {
  group('MessageModel.fromMap', () {
    test('old message without newer fields', () {
      final m = MessageModel.fromMap({
        'senderId': 'a',
        'receiverId': 'b',
        'type': 'text',
        'message': 'hi',
        'timestamp': Timestamp.fromMillisecondsSinceEpoch(1000),
      });
      expect(m.message, 'hi');
      expect(m.fileName, '');
      expect(m.pdfName, '');
      expect(m.thumbnailUrl, '');
      expect(m.timestamp.millisecondsSinceEpoch, 1000);
    });

    test('missing timestamp does not crash', () {
      final m = MessageModel.fromMap({'senderId': 'a', 'type': 'text'});
      expect(m.timestamp, isA<Timestamp>());
      expect(m.message, '');
    });

    test('toMap and fromMap round-trip, including fileName', () {
      final original = MessageModel(
        senderId: 'a',
        receiverId: 'b',
        type: 'docx',
        message: 'docx',
        timestamp: Timestamp.fromMillisecondsSinceEpoch(5000),
        photoUrl: 'https://example.com/f',
        thumbnailUrl: '',
        pdfUrl: '',
        pdfName: '',
        fileName: 'notes.docx',
      );
      final copy = MessageModel.fromMap(original.toMap());
      expect(copy.fileName, 'notes.docx');
      expect(copy.type, 'docx');
      expect(copy.photoUrl, 'https://example.com/f');
    });
  });

  group('CallModel.fromMap', () {
    test('call doc from an old app build (no created_at / accepted)', () {
      final c = CallModel.fromMap({
        'caller_id': 'a',
        'receiver_id': 'b',
        'channel_id': 'room',
        'has_dialled': false,
        'callType': 'audioCall',
      });
      expect(c.createdAt, isNull);
      expect(c.accepted, isFalse);
      expect(c.hasDialled, isFalse);
      expect(c.channelId, 'room');
    });
  });

  group('UserModel.fromMap', () {
    test('partly filled profile', () {
      final u = UserModel.fromMap({'uid': 'a', 'name': 'Alice'});
      expect(u.name, 'Alice');
      expect(u.notificationToken, '');
      expect(u.state, 0);
    });
  });
}
