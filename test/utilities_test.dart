import 'package:echat/utils/message_utils.dart';
import 'package:echat/utils/utilities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('getInitials', () {
    test('first and last initials', () => expect(Utils.getInitials('Sahil Potdukhe'), 'SP'));
    test('single name', () => expect(Utils.getInitials('sahil'), 'S'));
    test('extra spaces are ignored', () => expect(Utils.getInitials('  ada   lovelace '), 'AL'));
    test('empty name does not crash', () => expect(Utils.getInitials(''), '?'));
    test('null name does not crash', () => expect(Utils.getInitials(null), '?'));
  });

  group('chatListTime', () {
    final now = DateTime(2026, 10, 11, 15, 0); // a Sunday
    test('today shows the time', () {
      // intl puts a narrow no-break space before AM/PM.
      expect(MessageUtils.chatListTime(DateTime(2026, 10, 11, 9, 5), now).replaceAll('\u202f', ' '), '9:05 AM');
    });
    test('previous day is Yesterday', () {
      expect(MessageUtils.chatListTime(DateTime(2026, 10, 10, 23, 59), now), 'Yesterday');
    });
    test('Yesterday across a month boundary', () {
      expect(MessageUtils.chatListTime(DateTime(2026, 9, 30, 18), DateTime(2026, 10, 1, 9)), 'Yesterday');
    });
    test('within the week shows the weekday', () {
      expect(MessageUtils.chatListTime(DateTime(2026, 10, 7, 12), now), 'Wed');
    });
    test('older shows a short date', () {
      expect(MessageUtils.chatListTime(DateTime(2026, 10, 3, 12), now), '03/10/26');
    });
  });

  group('groupsWith', () {
    final t = DateTime(2026, 10, 11, 10, 0);
    bool g(String a, DateTime ta, String b, DateTime tb) =>
        MessageUtils.groupsWith(senderA: a, timeA: ta, senderB: b, timeB: tb);
    test('same sender, close together', () => expect(g('me', t, 'me', t.add(const Duration(minutes: 2))), isTrue));
    test('exactly at the gap still groups', () => expect(g('me', t, 'me', t.add(const Duration(minutes: 5))), isTrue));
    test('too far apart', () => expect(g('me', t, 'me', t.add(const Duration(minutes: 6))), isFalse));
    test('different sender', () => expect(g('me', t, 'you', t), isFalse));
    test('order does not matter', () => expect(g('me', t.add(const Duration(minutes: 1)), 'me', t), isTrue));
    test('across midnight does not group', () {
      expect(g('me', DateTime(2026, 10, 11, 23, 59), 'me', DateTime(2026, 10, 12, 0, 1)), isFalse);
    });
  });
}
