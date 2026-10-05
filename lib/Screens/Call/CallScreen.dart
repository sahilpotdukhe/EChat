import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/Resources/AgoraCallSession.dart';
import 'package:echat/Resources/CallMethods.dart';
import 'package:echat/Models/CallModel.dart';
import 'package:echat/Provider/UserProvider.dart';
import 'package:echat/Screens/Call/CallControlButton.dart';
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

  @override
  void initState() {
    super.initState();
    _session = AgoraCallSession(channelId: widget.callModel.channelId, video: true);
    _startCall();
    addPostFrameCallBack();
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
      UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);

      callStreamSubscription = callMethods.callStream(uid: userProvider.getUser!.uid).listen((DocumentSnapshot documentSnapshot) {
        if (documentSnapshot.data() == null && mounted) {
          Navigator.pop(context);
        }
      });
    });
  }

  @override
  void dispose() {
    callStreamSubscription?.cancel();
    _session.release();
    super.dispose();
  }

  Future<void> _hangUp() async {
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
