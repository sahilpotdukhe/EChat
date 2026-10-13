import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/models/call_log_model.dart';
import 'package:echat/models/call_model.dart';
import 'package:echat/models/message_model.dart';
import 'package:echat/resources/chat_firebase_methods.dart';
import 'package:echat/resources/repositories/log_repository.dart';
import 'package:echat/providers/user_provider.dart';
import 'package:echat/resources/agora_call_session.dart';
import 'package:echat/resources/call_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_kit/shadcn_kit.dart';

/// What the voice and video call screens share: joining the Agora channel,
/// closing when the other side hangs up (their call document is deleted),
/// hanging up after 45 seconds with no answer (caller only), and tracking
/// when the other person connected, for the call timer.
mixin CallLifecycle<T extends StatefulWidget> on State<T> {
  CallModel get callModel;
  bool get isVideo;

  late final CallMethods callMethods = CallMethods();
  late final AgoraCallSession session;

  bool isStarting = true;
  String? error;

  /// The receiver picked up (they may still be connecting to Agora).
  bool accepted = false;

  /// When the other person joined; null until then.
  DateTime? connectedAt;

  StreamSubscription? _callSubscription;
  // The call is saved to the history and the chat only once.
  bool _recorded = false;
  Timer? _noAnswerTimer;
  // Set once this screen starts closing, so it is popped only once.
  bool _closing = false;

  /// The person on the other end of the call.
  String get otherName => callModel.hasDialled ? callModel.receiverName : callModel.callerName;
  String get otherPic => callModel.hasDialled ? callModel.receiverPic : callModel.callerPic;

  /// "Ringing…", "Connecting…", or null once connected (show the timer).
  String? get statusText {
    if (error != null) return error;
    if (connectedAt != null) return null;
    if (isStarting) return 'Connecting…';
    if (callModel.hasDialled && !accepted) return 'Ringing…';
    return 'Connecting…';
  }

  void startCall() {
    session = AgoraCallSession(channelId: callModel.channelId, video: isVideo);
    session.remoteUid.addListener(_onRemoteChanged);
    _join();
    SchedulerBinding.instance.addPostFrameCallback((_) => _listenForHangUp());
    // Caller only: hang up if nobody answers within 45 seconds.
    if (callModel.hasDialled) {
      _noAnswerTimer = Timer(const Duration(seconds: 45), _onNoAnswer);
    }
  }

  void _onRemoteChanged() {
    if (!mounted) return;
    if (session.remoteUid.value != null) {
      _noAnswerTimer?.cancel();
      setState(() => connectedAt ??= DateTime.now());
    } else {
      setState(() {});
    }
  }

  Future<void> _join() async {
    try {
      await session.start();
    } catch (e) {
      debugPrint('Error starting ${isVideo ? 'video' : 'voice'} call: $e');
      error = 'Couldn\'t connect the call. Please try again.';
    }
    if (mounted) setState(() => isStarting = false);
  }

  void _listenForHangUp() {
    if (!mounted) return;
    final uid = Provider.of<UserProvider>(context, listen: false).getUser?.uid;
    if (uid == null) return;
    _callSubscription = callMethods.callStream(uid: uid).listen((DocumentSnapshot snapshot) {
      final data = snapshot.data() as Map?;
      if (data == null) {
        if (mounted && !_closing) {
          _closing = true;
          _noAnswerTimer?.cancel();
          _recordCall();
          Navigator.pop(context);
        }
        return;
      }
      final nowAccepted = data['accepted'] == true;
      if (nowAccepted != accepted && mounted) setState(() => accepted = nowAccepted);
    });
  }

  // Skipped once the receiver accepted: their token fetch can be slow when
  // the token server is waking up, and they can still hang up themselves.
  void _onNoAnswer() {
    if (!mounted || _closing || accepted || session.remoteUid.value != null) return;
    showShadcnToast(context, title: 'No answer', description: '$otherName didn\'t pick up.');
    hangUp();
  }

  Future<void> hangUp() async {
    if (_closing) return;
    _closing = true;
    _noAnswerTimer?.cancel();
    _recordCall();
    await _callSubscription?.cancel();
    await session.release();
    callMethods.endCall(callModel: callModel);
    if (mounted) Navigator.pop(context);
  }

  void disposeCall() {
    _recordCall();
    _noAnswerTimer?.cancel();
    _callSubscription?.cancel();
    session.release();
  }

  /// Saves the finished call: in this phone's Calls tab (both people), and
  /// as a call bubble in the chat ("Voice call · 3 min" / "Missed voice
  /// call"), written once, by the caller. Never throws.
  void _recordCall() {
    if (_recorded) return;
    _recorded = true;
    final started = connectedAt;
    final int seconds = started == null ? 0 : DateTime.now().difference(started).inSeconds;
    final bool answered = started != null;
    final isCaller = callModel.hasDialled;

    try {
      LogRepository.addLogs(CallLogModel(
        callerId: callModel.callerId,
        receiverId: callModel.receiverId,
        callerName: callModel.callerName,
        callerPic: callModel.callerPic,
        receiverName: callModel.receiverName,
        receiverPic: callModel.receiverPic,
        callStatus: isCaller ? 'Dialled' : 'received',
        timestamp: DateTime.now().toString(),
        callType: callModel.callType,
        durationSeconds: seconds,
      )).catchError((Object e) => debugPrint('Call history not saved: $e'));
    } catch (e) {
      debugPrint('Call history not saved: $e');
    }

    if (!isCaller) return;
    // A missed call notifies them and counts as unread; a call they
    // answered doesn't.
    ChatFirebaseMethods()
        .addMessagetoDb(
          MessageModel.call(
            senderId: callModel.callerId,
            receiverId: callModel.receiverId,
            callType: callModel.callType,
            answered: answered,
            callDuration: seconds,
            timestamp: Timestamp.now(),
          ),
          notify: !answered,
          countAsUnread: !answered,
        )
        .catchError((Object e) => debugPrint('Call not added to the chat: $e'));
  }
}
