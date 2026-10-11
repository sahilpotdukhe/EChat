import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:echat/models/call_model.dart';
import 'package:echat/screens/call/call_lifecycle.dart';
import 'package:echat/screens/call/widgets/call_ui.dart';
import 'package:flutter/material.dart';

/// A video call: the other person full-screen, you in a small window in the
/// corner, the name and timer at the top and Mute / Camera / Flip / End at
/// the bottom. Once connected, tap the screen to hide or show the controls.
class CallScreen extends StatefulWidget {
  final CallModel callModel;

  const CallScreen({super.key, required this.callModel});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with CallLifecycle {
  bool _micMuted = false;
  bool _cameraOff = false;
  bool _showControls = true;

  @override
  CallModel get callModel => widget.callModel;

  @override
  bool get isVideo => true;

  @override
  void initState() {
    super.initState();
    startCall();
  }

  @override
  void dispose() {
    disposeCall();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = !isStarting && error == null;
    final connected = connectedAt != null;
    // Controls always show until the other person is on screen.
    final controlsVisible = _showControls || !connected;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) hangUp();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: CallBackground(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: connected ? () => setState(() => _showControls = !_showControls) : null,
            child: Stack(
              children: [
                Positioned.fill(child: _remoteView()),
                if (ready) _selfView(context),
                _topBar(controlsVisible),
                Positioned(left: 0, right: 0, bottom: 0, child: _controls(controlsVisible, ready)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Before the other person joins (or on error), show their photo and the
  // status in the middle instead of an empty black screen.
  Widget _remoteView() {
    final remoteUid = isStarting || error != null ? null : session.remoteUid.value;
    if (remoteUid == null) {
      final status = statusText ?? '';
      final height = MediaQuery.sizeOf(context).height;
      // Room is left at the top and bottom for the bars; sideways phones get
      // a smaller photo so the name still fits.
      final short = height < 480;
      return SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, short ? 16 : 80, 24, short ? 120 : 80),
            child: Column(
              children: [
                PulsingAvatar(name: otherName, imageUrl: otherPic, size: short ? 64 : 112, pulsing: error == null),
                const SizedBox(height: 20),
                Text(
                  otherName.isEmpty ? 'EChat user' : otherName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(status,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: error != null ? const Color(0xFFFCA5A5) : Colors.white70)),
              ],
            ),
          ),
        ),
      );
    }
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: session.engine,
        canvas: VideoCanvas(uid: remoteUid),
        connection: RtcConnection(channelId: callModel.channelId),
      ),
    );
  }

  Widget _selfView(BuildContext context) {
    final shortSide = MediaQuery.sizeOf(context).shortestSide;
    final width = (shortSide * 0.28).clamp(96.0, 160.0);
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 64,
      right: 16,
      width: width,
      height: width * 1.45,
      child: Semantics(
        label: _cameraOff ? 'Your camera is off' : 'Your camera',
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 12)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _cameraOff
                ? Container(
                    color: const Color(0xFF23232D),
                    child: const Icon(Icons.videocam_off_rounded, color: Colors.white54),
                  )
                : AgoraVideoView(
                    controller: VideoViewController(rtcEngine: session.engine, canvas: const VideoCanvas(uid: 0)),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(bool visible) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(
          opacity: visible && connectedAt != null ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black54, Colors.transparent],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        otherName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (connectedAt != null) CallDuration(since: connectedAt!),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _controls(bool visible, bool ready) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black54, Colors.transparent],
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CallControlButton(
                        icon: _micMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        label: _micMuted ? 'Unmute' : 'Mute',
                        active: _micMuted,
                        onPressed: !ready
                            ? null
                            : () {
                                setState(() => _micMuted = !_micMuted);
                                session.engine.muteLocalAudioStream(_micMuted);
                              },
                      ),
                      CallControlButton(
                        icon: _cameraOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                        label: 'Camera',
                        active: _cameraOff,
                        onPressed: !ready
                            ? null
                            : () {
                                setState(() => _cameraOff = !_cameraOff);
                                session.engine.muteLocalVideoStream(_cameraOff);
                                _cameraOff ? session.engine.stopPreview() : session.engine.startPreview();
                              },
                      ),
                      CallControlButton(
                        icon: Icons.cameraswitch_rounded,
                        label: 'Flip',
                        onPressed: !ready || _cameraOff ? null : () => session.engine.switchCamera(),
                      ),
                      CallControlButton(
                        icon: Icons.call_end_rounded,
                        label: 'End',
                        tone: CallButtonTone.end,
                        size: 64,
                        onPressed: hangUp,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
