import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/resources/agora_call_session.dart';
import 'package:echat/resources/call_methods.dart';
import 'package:echat/models/call_model.dart';
import 'package:echat/providers/user_provider.dart';
import 'package:echat/screens/call/call_control_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

class CallScreen extends StatefulWidget {
  final CallModel callModel;

  const CallScreen({super.key, required this.callModel});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final CallMethods callMethods = CallMethods();
  StreamSubscription? callStreamSubscription;
  late final AgoraCallSession _session;
  bool _isLoading = true;
  String? _error;
  bool _micMuted = false;
  bool _cameraOff = false;
  Timer? _noAnswerTimer;
  // Set once this screen starts closing, so it is popped only once.
  bool _closing = false;
  // Receiver picked up (they may still be connecting to Agora).
  bool _accepted = false;

  @override
  void initState() {
    super.initState();
    _session = AgoraCallSession(channelId: widget.callModel.channelId, video: true);
    _startCall();
    addPostFrameCallBack();
    // Caller only: hang up if nobody answers within 45 seconds.
    if (widget.callModel.hasDialled) {
      _noAnswerTimer = Timer(const Duration(seconds: 45), _onNoAnswer);
      _session.remoteUid.addListener(() {
        if (_session.remoteUid.value != null) _noAnswerTimer?.cancel();
      });
    }
  }

  // Skipped once the receiver accepted: their token fetch can be slow when
  // the token server is waking up, and they can still hang up themselves.
  void _onNoAnswer() {
    if (!mounted || _closing || _accepted || _session.remoteUid.value != null) return;
    ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    _hangUp();
    messenger.showSnackBar(SnackBar(content: Text('No answer')));
  }

  Future<void> _startCall() async {
    try {
      await _session.start();
    } catch (e) {
      debugPrint('Error starting video call: $e');
      _error = 'Could not connect the call. Please try again.';
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Close this screen when the call document is deleted (the other side hung up).
  addPostFrameCallBack() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);

      callStreamSubscription = callMethods.callStream(uid: userProvider.getUser!.uid).listen((DocumentSnapshot documentSnapshot) {
        Map? data = documentSnapshot.data() as Map?;
        if (data == null) {
          if (mounted && !_closing) {
            _closing = true;
            _noAnswerTimer?.cancel();
            Navigator.pop(context);
          }
          return;
        }
        _accepted = data['accepted'] == true;
      });
    });
  }

  @override
  void dispose() {
    _noAnswerTimer?.cancel();
    callStreamSubscription?.cancel();
    _session.release();
    super.dispose();
  }

  Future<void> _hangUp() async {
    if (_closing) return;
    _closing = true;
    _noAnswerTimer?.cancel();
    await callStreamSubscription?.cancel();
    await _session.release();
    callMethods.endCall(callModel: widget.callModel);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text('Video Call'),
        ),
        body: SafeArea(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    Positioned.fill(child: _remoteVideo()),
                    if (_error == null)
                      Positioned(
                        top: 16,
                        right: 16,
                        width: 110,
                        height: 160,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _cameraOff
                              ? Container(color: Colors.grey.shade900)
                              : AgoraVideoView(
                                  controller: VideoViewController(
                                    rtcEngine: _session.engine,
                                    canvas: const VideoCanvas(uid: 0),
                                  ),
                                ),
                        ),
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 24,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          CallControlButton(
                            icon: _micMuted ? Icons.mic_off : Icons.mic,
                            onPressed: _error != null
                                ? null
                                : () {
                                    setState(() => _micMuted = !_micMuted);
                                    _session.engine.muteLocalAudioStream(_micMuted);
                                  },
                          ),
                          CallControlButton(
                            icon: Icons.call_end,
                            color: Colors.red,
                            onPressed: _hangUp,
                          ),
                          CallControlButton(
                            icon: _cameraOff ? Icons.videocam_off : Icons.videocam,
                            onPressed: _error != null
                                ? null
                                : () {
                                    setState(() => _cameraOff = !_cameraOff);
                                    _session.engine.muteLocalVideoStream(_cameraOff);
                                    _cameraOff
                                        ? _session.engine.stopPreview()
                                        : _session.engine.startPreview();
                                  },
                          ),
                          CallControlButton(
                            icon: Icons.cameraswitch,
                            onPressed: _error != null
                                ? null
                                : () => _session.engine.switchCamera(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ));
  }

  Widget _remoteVideo() {
    if (_error != null) {
      return Center(
        child: Text(_error!, style: TextStyle(color: Colors.white, fontSize: 16)),
      );
    }
    return ValueListenableBuilder<int?>(
      valueListenable: _session.remoteUid,
      builder: (context, remoteUid, _) {
        if (remoteUid == null) {
          return Center(
            child: Text('Waiting for the other person to join...',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          );
        }
        return AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: _session.engine,
            canvas: VideoCanvas(uid: remoteUid),
            connection: RtcConnection(channelId: widget.callModel.channelId),
          ),
        );
      },
    );
  }
}
