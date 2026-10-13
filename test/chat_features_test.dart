import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/models/call_log_model.dart';
import 'package:echat/models/contact_model.dart';
import 'package:echat/models/message_model.dart';
import 'package:echat/models/user_model.dart';
import 'package:echat/resources/media_storage.dart';
import 'package:echat/utils/message_utils.dart';
import 'package:echat/utils/presence.dart';
import 'package:flutter_test/flutter_test.dart';

UserModel _user({int state = 1, Timestamp? lastSeen}) => UserModel(
      uid: 'u',
      name: 'U',
      email: '',
      username: '',
      status: '',
      state: state,
      gender: '',
      phoneNumber: '',
      profilePhoto: '',
      authType: '',
      notificationToken: '',
      lastSeen: lastSeen,
    );

void main() {
  final now = DateTime(2026, 10, 13, 15, 0);

  group('ticks', () {
    test('status only moves forward', () {
      expect(MessageStatus.rank(''), 0);
      expect(MessageStatus.rank(MessageStatus.sent), 1);
      expect(MessageStatus.rank(MessageStatus.delivered), 2);
      expect(MessageStatus.rank(MessageStatus.read), 3);
    });

    test('new messages start as sent; old ones have no status', () {
      final fresh = MessageModel(senderId: 'a', receiverId: 'b', type: 'text', message: 'hi',
          timestamp: Timestamp.now(), photoUrl: '', thumbnailUrl: '', pdfUrl: '', pdfName: '');
      expect(fresh.toMap()['status'], MessageStatus.sent);
      expect(MessageModel.fromMap({'type': 'text'}).status, '');
      expect(MessageModel.fromMap({'status': 42}).status, '');
    });
  });

  group('calls in the chat', () {
    test('a call survives saving and loading', () {
      final call = MessageModel.call(
          senderId: 'a', receiverId: 'b', callType: 'videoCall', answered: true, callDuration: 125,
          timestamp: Timestamp.now());
      final back = MessageModel.fromMap(call.toMap());
      expect(back.isCall, isTrue);
      expect(back.isMissedCall, isFalse);
      expect(back.isVideoCall, isTrue);
      expect(back.callDuration, 125);
      expect(MessageUtils.kindForType(back.type), MessageKind.call);
    });

    test('titles read like WhatsApp', () {
      expect(MessageUtils.callTitle(callType: 'audioCall', answered: true, sentByMe: true), 'Voice call');
      expect(MessageUtils.callTitle(callType: 'videoCall', answered: false, sentByMe: false), 'Missed video call');
      expect(MessageUtils.callTitle(callType: 'audioCall', answered: false, sentByMe: true), 'Voice call · No answer');
    });

    test('durations', () {
      expect(MessageUtils.callDurationLabel(-3), '0 sec');
      expect(MessageUtils.callDurationLabel(45), '45 sec');
      expect(MessageUtils.callDurationLabel(60), '1 min');
      expect(MessageUtils.callDurationLabel(3 * 60 + 59), '3 min');
      expect(MessageUtils.callDurationLabel(3600), '1 hr');
      expect(MessageUtils.callDurationLabel(3600 + 5 * 60), '1 hr 5 min');
    });

    test('chat list preview', () {
      expect(MessageUtils.previewText(type: 'call', message: 'missed', callType: 'audioCall'), 'Missed voice call');
      expect(MessageUtils.previewText(type: 'deleted', message: ''), '🚫 This message was deleted');
      expect(MessageUtils.previewText(type: 'deleted', message: '', sentByMe: true), '🚫 You deleted this message');
    });

    test('call history keeps the length; old entries read as 0', () {
      final log = CallLogModel(callerName: 'a', callerPic: '', receiverName: 'b', receiverPic: '',
          callStatus: 'Dialled', timestamp: '', callType: 'audioCall', durationSeconds: 90);
      expect(CallLogModel.fromMap(log.toMap(log)).durationSeconds, 90);
      expect(CallLogModel.fromMap({'call_status': 'missed'}).durationSeconds, 0);
    });
  });

  group('delete for everyone', () {
    test('wipes the content and marks it deleted', () {
      expect(MessageModel.deletedFields['type'], 'deleted');
      for (final key in ['message', 'photoUrl', 'videoUrl', 'thumbnailUrl', 'pdfUrl', 'pdfName', 'fileName']) {
        expect(MessageModel.deletedFields[key], '', reason: key);
      }
      expect(MessageModel.fromMap({'type': 'deleted'}).isDeleted, isTrue);
    });
  });

  group('online dot', () {
    test('fresh heartbeat is online', () {
      final seen = Timestamp.fromDate(now.subtract(const Duration(seconds: 50)));
      expect(Presence.isOnline(_user(lastSeen: seen), now), isTrue);
    });

    test('online that stopped refreshing counts as offline', () {
      final seen = Timestamp.fromDate(now.subtract(const Duration(minutes: 5)));
      expect(Presence.isOnline(_user(lastSeen: seen), now), isFalse);
    });

    test('offline or away is never online', () {
      final seen = Timestamp.fromDate(now);
      expect(Presence.isOnline(_user(state: 0, lastSeen: seen), now), isFalse);
      expect(Presence.isOnline(_user(state: 2, lastSeen: seen), now), isFalse);
    });

    test('profiles from older builds trust the flag', () {
      expect(Presence.isOnline(_user(), now), isTrue);
    });

    test('last seen wording', () {
      // intl puts a narrow no-break space before AM/PM.
      String label(DateTime t) => MessageUtils.lastSeenLabel(t, now).replaceAll('\u202f', ' ');
      expect(label(DateTime(2026, 10, 13, 10, 32)), 'last seen today at 10:32 AM');
      expect(label(DateTime(2026, 10, 12, 21, 5)), 'last seen yesterday at 9:05 PM');
      expect(label(DateTime(2026, 10, 9, 8, 0)), 'last seen Friday at 8:00 AM');
      expect(MessageUtils.lastSeenLabel(DateTime(2026, 9, 1, 8, 0), now), 'last seen 01/09/26');
    });
  });

  group('chat list', () {
    test('newest chat first, unknown times last', () {
      final old = ContactModel(uid: 'old', lastMessageAt: Timestamp.fromMillisecondsSinceEpoch(1000));
      final fresh = ContactModel(uid: 'new', lastMessageAt: Timestamp.fromMillisecondsSinceEpoch(5000));
      final legacy = ContactModel(uid: 'legacy', addedOn: Timestamp.fromMillisecondsSinceEpoch(3000));
      final none = ContactModel(uid: 'none');
      final sorted = [none, old, legacy, fresh]..sort(ContactModel.newestFirst);
      expect(sorted.map((c) => c.uid), ['new', 'legacy', 'old', 'none']);
    });

    test('old rows and bad counts read safely', () {
      final c = ContactModel.fromMap({'contact_id': 'x', 'added_on': Timestamp.now()});
      expect(c.unreadCount, 0);
      expect(c.lastMessageAt, isNull);
      expect(ContactModel.fromMap({'contact_id': 'x', 'unread_count': -4}).unreadCount, 0);
      expect(ContactModel.fromMap({}).uid, '');
    });
  });

  group('Supabase storage paths', () {
    const base = 'https://abc.supabase.co';
    test('finds the path in our own public links only', () {
      expect(MediaStorage.storagePathFromUrl('$base/storage/v1/object/public/media/Media/u1/xyz_a%20b.jpg', base, 'media'),
          'Media/u1/xyz_a b.jpg');
      expect(MediaStorage.storagePathFromUrl('https://firebasestorage.googleapis.com/v0/b/x/o/a.jpg', base, 'media'), isNull);
      expect(MediaStorage.storagePathFromUrl('$base/storage/v1/object/public/other/a.jpg', base, 'media'), isNull);
      expect(MediaStorage.storagePathFromUrl('anything', '', 'media'), isNull);
    });

    test('file names become safe keys', () {
      expect(MediaStorage.safeFileName('My résumé (final).pdf'), 'My_r_sum___final_.pdf');
      expect(MediaStorage.safeFileName(''), 'file');
      expect(MediaStorage.safeFileName('${'a' * 100}.pdf').length, 80);
      expect(MediaStorage.safeFileName('${'a' * 100}.pdf'), endsWith('.pdf'));
    });
  });
}
