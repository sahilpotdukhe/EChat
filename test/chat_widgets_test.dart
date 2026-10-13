import 'package:echat/models/message_model.dart';
import 'package:echat/screens/chat/widgets/message_extras.dart';
import 'package:echat/theme/app_colors.dart';
import 'package:echat/widgets/common/connectivity_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  group('MessageTicks', () {
    Future<Icon> iconFor(WidgetTester tester, String status, {bool pending = false}) async {
      await tester.pumpWidget(_wrap(MessageTicks(status: status, pending: pending, color: Colors.white)));
      return tester.widget<Icon>(find.byType(Icon));
    }

    testWidgets('clock while offline', (tester) async {
      expect((await iconFor(tester, MessageStatus.sent, pending: true)).icon, Icons.schedule_rounded);
    });
    testWidgets('one tick when sent', (tester) async {
      expect((await iconFor(tester, MessageStatus.sent)).icon, Icons.done_rounded);
    });
    testWidgets('two grey ticks when delivered', (tester) async {
      final icon = await iconFor(tester, MessageStatus.delivered);
      expect(icon.icon, Icons.done_all_rounded);
      expect(icon.color, isNot(readTickColor));
    });
    testWidgets('two blue ticks when read', (tester) async {
      final icon = await iconFor(tester, MessageStatus.read);
      expect(icon.icon, Icons.done_all_rounded);
      expect(icon.color, readTickColor);
    });
    testWidgets('nothing for old messages', (tester) async {
      await tester.pumpWidget(_wrap(const MessageTicks(status: '', pending: false, color: Colors.white)));
      expect(find.byType(Icon), findsNothing);
    });
  });

  testWidgets('connectivity banner: offline, then back online, then gone', (tester) async {
    final online = ValueNotifier<bool>(true);
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: [AppColors.shadcnLight, AppColors.light]),
      builder: (context, child) => ConnectivityBanner(online: online, child: child!),
      home: const Scaffold(body: Text('chats')),
    ));
    expect(find.textContaining('No internet'), findsNothing);

    online.value = false;
    await tester.pumpAndSettle();
    expect(find.textContaining('No internet'), findsOneWidget);
    expect(find.text('chats'), findsOneWidget);

    online.value = true;
    await tester.pumpAndSettle();
    expect(find.text('Back online'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Back online'), findsNothing);
  });
}
