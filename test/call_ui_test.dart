import 'package:echat/screens/call/widgets/call_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('call timer format', () {
    test('seconds', () => expect(CallDurationFormat.format(const Duration(seconds: 7)), '00:07'));
    test('minutes', () => expect(CallDurationFormat.format(const Duration(minutes: 4, seconds: 27)), '04:27'));
    test('hours', () => expect(CallDurationFormat.format(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03'));
  });
}
