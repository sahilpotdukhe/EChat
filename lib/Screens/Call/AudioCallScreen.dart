import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/Provider/UserProvider.dart';
import 'package:echat/Resources/AgoraCallSession.dart';
import 'package:echat/Resources/CallMethods.dart';
import 'package:echat/Models/CallModel.dart';
import 'package:echat/Screens/Call/CallControlButton.dart';
import 'package:echat/Utils/ScreenDimensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

class AudioCallScreen extends StatefulWidget {
  final CallModel callModel;

  const AudioCallScreen({super.key, required this.callModel});

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  final CallMethods callMethods = CallMethods();
  StreamSubscription? callStreamSubscription;
  late final AgoraCallSession _session;
  bool _isLoading = true;
  String? _error;
  bool _micMuted = false;
  bool _speakerOn = false;
  Timer? _noAnswerTimer;
  // Set once this screen starts closing, so it is popped only once.
  bool _closing = false;
  // Receiver picked up (they may still be connecting to Agora).
  bool _accepted = false;

  @override
  void initState() {
    super.initState();
    _session = AgoraCallSession(channelId: widget.callModel.channelId, video: false);
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
      debugPrint('Error starting audio call: $e');
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
    ScaleUtils.init(context);
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text('Audio Call'),
        ),
        body: SafeArea(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _participant(widget.callModel.callerPic, widget.callModel.callerName),
                              SizedBox(width: 20*ScaleUtils.horizontalScale,),
                              _participant(widget.callModel.receiverPic, widget.callModel.receiverName),
                            ],
                          ),
                          SizedBox(height: 24*ScaleUtils.verticalScale),
                          _status(),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 24*ScaleUtils.verticalScale),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          CallControlButton(
                            icon: _micMuted ? Icons.mic_off : Icons.mic,
                            color: Colors.blueGrey,
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
                            icon: _speakerOn ? Icons.volume_up : Icons.hearing,
                            color: Colors.blueGrey,
                            onPressed: _error != null
                                ? null
                                : () {
                                    setState(() => _speakerOn = !_speakerOn);
                                    _session.engine.setEnableSpeakerphone(_speakerOn);
                                  },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ));
  }

  Widget _participant(String pic, String name) {
    return SizedBox(
      width: 120*ScaleUtils.horizontalScale,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 30*ScaleUtils.scaleFactor,
            backgroundColor: Colors.transparent,
            backgroundImage: AssetImage('assets/user.jpg'),
            foregroundImage: pic.isEmpty ? null : NetworkImage(pic),
          ),
          SizedBox(height: 5*ScaleUtils.verticalScale,),
          Text(name,textAlign:TextAlign.center,overflow:TextOverflow.ellipsis,maxLines:2,style: TextStyle(fontSize: 20*ScaleUtils.scaleFactor,fontWeight: FontWeight.bold),)
        ],
      ),
    );
  }

  Widget _status() {
    if (_error != null) {
      return Text(_error!, textAlign: TextAlign.center);
    }
    return ValueListenableBuilder<int?>(
      valueListenable: _session.remoteUid,
      builder: (context, remoteUid, _) => Text(
        remoteUid == null ? 'Ringing...' : 'Connected',
        style: TextStyle(fontSize: 16*ScaleUtils.scaleFactor, color: Colors.grey),
      ),
    );
  }
}
