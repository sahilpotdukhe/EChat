import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/models/call_log_model.dart';
import 'package:echat/models/call_model.dart';
import 'package:echat/models/user_model.dart';
import 'package:echat/resources/auth_methods.dart';
import 'package:echat/resources/call_methods.dart';
import 'package:echat/resources/call_ringer.dart';
import 'package:echat/resources/local_notifications.dart';
import 'package:echat/resources/repositories/log_repository.dart';
import 'package:echat/screens/call/audio_call_screen.dart';
import 'package:echat/screens/call/call_screen.dart';
import 'package:echat/screens/call/widgets/call_ui.dart';
import 'package:echat/screens/chat/chat_screen.dart';
import 'package:flutter/material.dart';

/// The incoming call screen: who's calling (with a pulsing photo), and
/// Decline / Accept buttons, plus "Message" to reply in chat instead.
class PickupScreen extends StatefulWidget {
  final CallModel callModel;

  const PickupScreen({super.key, required this.callModel});

  @override
  State<PickupScreen> createState() => _PickupScreenState();
}

class _PickupScreenState extends State<PickupScreen> {
  // Stays true unless the call is answered, so declining, replying by
  // message and not answering are all logged as missed when this closes.
  bool isCallMissed = true;
  late final AuthMethods authMethods = AuthMethods();
  String callerEmail = "";
  UserModel? callerModel;
  late final CallMethods callMethods = CallMethods();
  Timer? _ringTimer;
  late final AppLifecycleListener _lifecycle;
  static const Duration _ringTimeout = Duration(seconds: 45);

  // Adds this call to the call history on this phone.
  void addToLocalStorage({required String callStatus}) {
    final callLogModel = CallLogModel(
        callerId: widget.callModel.callerId,
        receiverId: widget.callModel.receiverId,
        callerName: widget.callModel.callerName,
        callerPic: widget.callModel.callerPic,
        receiverName: widget.callModel.receiverName,
        receiverPic: widget.callModel.receiverPic,
        callStatus: callStatus,
        timestamp: DateTime.now().toString(),
        callType: widget.callModel.callType);
    LogRepository.addLogs(callLogModel);
  }

  @override
  void initState() {
    super.initState();
    getUser();
    _lifecycle = AppLifecycleListener(onResume: _ringIfOnScreen);
    _startRinging();
  }

  @override
  void didUpdateWidget(covariant PickupScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new call replaced an old one while this screen was showing.
    if (oldWidget.callModel.channelId != widget.callModel.channelId) {
      _startRinging();
    }
  }

  // Rings for at most 45 seconds. A call that is already older than that
  // (caller's app died, or this app was opened much later) is ended right away.
  // createdAt is null for calls from old app builds: the timer covers those.
  void _startRinging() {
    _ringTimer?.cancel();
    Timestamp? createdAt = widget.callModel.createdAt;
    if (createdAt != null && DateTime.now().difference(createdAt.toDate()) > _ringTimeout) {
      callMethods.endCall(callModel: widget.callModel);
      return;
    }
    _ringIfOnScreen();
    _ringTimer = Timer(_ringTimeout, () {
      // Nobody answered. Deleting the docs closes this screen, and dispose()
      // logs the missed call.
      if (isCallMissed) callMethods.endCall(callModel: widget.callModel);
    });
  }

  // The ringtone plays only while the app is on screen. In the background the
  // call notification rings instead, so it is left alone until the app opens;
  // then it is cleared so the call doesn't ring twice.
  void _ringIfOnScreen() {
    if (!isCallMissed) return;
    final state = WidgetsBinding.instance.lifecycleState;
    if (state != null && state != AppLifecycleState.resumed) return;
    LocalNotifications.dismissCall();
    CallRinger.start();
  }

  Future<void> getUser() async {
    try {
      callerModel = await authMethods.getUserDetailsById(widget.callModel.callerId);
    } catch (e) {
      // Offline: the screen still works, just without the email and Message.
      debugPrint('Couldn\'t load caller: $e');
    }
    if (!mounted || callerModel == null) return;
    setState(() => callerEmail = callerModel!.email);
  }

  @override
  void dispose() {
    _ringTimer?.cancel();
    _lifecycle.dispose();
    CallRinger.stop();
    LocalNotifications.dismissCall();
    super.dispose();
    if (isCallMissed) addToLocalStorage(callStatus: "missed");
  }

  void _decline() {
    _ringTimer?.cancel();
    CallRinger.stop();
    // Deleting the call docs closes this screen; dispose() logs it as missed.
    callMethods.endCall(callModel: widget.callModel);
  }

  void _replyWithMessage() {
    // Caller's profile still loading (or gone): nothing to open yet.
    final caller = callerModel;
    if (caller == null) return;
    _decline();
    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(receiver: caller)));
  }

  void _accept() {
    _ringTimer?.cancel();
    CallRinger.stop();
    isCallMissed = false;
    // Logged with its length when the call screen closes (CallLifecycle).
    // Tells the caller (and the server rules) this call is live.
    callMethods.markAccepted(callModel: widget.callModel);
    final screen = widget.callModel.callType == "videoCall"
        ? CallScreen(callModel: widget.callModel)
        : AudioCallScreen(callModel: widget.callModel);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final call = widget.callModel;
    final isVideo = call.callType == "videoCall";
    final name = call.callerName.isEmpty ? 'EChat user' : call.callerName;

    return PopScope(
      // Back shouldn't silently leave the call ringing behind the app.
      canPop: false,
      child: Scaffold(
        body: CallBackground(
          child: SafeArea(
            child: LayoutBuilder(builder: (context, constraints) {
              // A phone held sideways: caller on the left, buttons on the right.
              final short = constraints.maxHeight < 480;
              final avatar = short ? 72.0 : (constraints.maxHeight * 0.2).clamp(88.0, 140.0);
              final kindLabel = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isVideo ? Icons.videocam_rounded : Icons.call_rounded, size: 16, color: Colors.white70),
                  const SizedBox(width: 6),
                  Text(isVideo ? 'Incoming video call' : 'Incoming voice call',
                      style: const TextStyle(fontSize: 14, color: Colors.white70)),
                ],
              );
              final identity = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PulsingAvatar(name: call.callerName, imageUrl: call.callerPic, size: avatar),
                  SizedBox(height: short ? 8 : 20),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: short ? 24 : 30, fontWeight: FontWeight.w700),
                  ),
                  if (callerEmail.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(callerEmail,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, color: Colors.white60)),
                  ],
                ],
              );
              final message = TextButton.icon(
                onPressed: callerModel == null ? null : _replyWithMessage,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white12,
                  disabledForegroundColor: Colors.white38,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: const Text('Message'),
              );
              final answerButtons = ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CallControlButton(
                      icon: Icons.call_end_rounded,
                      label: 'Decline',
                      tone: CallButtonTone.end,
                      size: 72,
                      onPressed: _decline,
                    ),
                    CallControlButton(
                      icon: isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                      label: 'Accept',
                      tone: CallButtonTone.accept,
                      size: 72,
                      onPressed: _accept,
                    ),
                  ],
                ),
              );

              if (short) {
                return Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(children: [kindLabel, const SizedBox(height: 12), identity]),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [message, const SizedBox(height: 24), answerButtons],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  const SizedBox(height: 24),
                  kindLabel,
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: identity,
                      ),
                    ),
                  ),
                  message,
                  const SizedBox(height: 32),
                  Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 40), child: answerButtons),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
