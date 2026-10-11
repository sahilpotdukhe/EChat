import 'package:echat/models/call_log_model.dart';
import 'package:flutter_test/flutter_test.dart';

CallLogModel log(String status, {String type = 'audioCall'}) => CallLogModel(
      callerId: 'caller',
      callerName: 'Caller',
      callerPic: 'caller.jpg',
      receiverId: 'receiver',
      receiverName: 'Receiver',
      receiverPic: 'receiver.jpg',
      callStatus: status,
      timestamp: '2026-10-11 09:05:00.000',
      callType: type,
    );

void main() {
  test('an outgoing call shows the person we called', () {
    final l = log('Dialled');
    expect(l.isOutgoing, isTrue);
    expect(l.isMissed, isFalse);
    expect((l.peerId, l.peerName, l.peerPic), ('receiver', 'Receiver', 'receiver.jpg'));
  });

  test('a received call shows the caller', () {
    final l = log('received');
    expect(l.isOutgoing, isFalse);
    expect(l.isMissed, isFalse);
    expect(l.peerName, 'Caller');
  });

  test('a missed call shows the caller and is missed', () {
    final l = log('missed');
    expect(l.isMissed, isTrue);
    expect(l.peerId, 'caller');
  });

  test('video calls are recognised', () => expect(log('Dialled', type: 'videoCall').isVideo, isTrue));

  test('round-trips through a map', () {
    final l = CallLogModel.fromMap(log('missed').toMap(log('missed')));
    expect((l.callerId, l.receiverId, l.callStatus, l.time), ('caller', 'receiver', 'missed', DateTime(2026, 10, 11, 9, 5)));
  });

  test('old logs without ids or with missing fields still load', () {
    final l = CallLogModel.fromMap({
      'caller_name': 'Old',
      'call_status': 'Dialled',
      'timestamp': 'not a date',
    });
    expect(l.peerId, '');
    expect(l.receiverName, '');
    expect(l.time, isNull);
  });
}
