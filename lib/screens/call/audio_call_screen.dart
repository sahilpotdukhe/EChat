import 'package:echat/models/call_model.dart';
import 'package:echat/screens/call/call_lifecycle.dart';
import 'package:echat/screens/call/widgets/call_ui.dart';
import 'package:flutter/material.dart';

/// A voice call: the other person's photo and name, "Ringing…" /
/// "Connecting…" then a running timer, and Mute / Speaker / End buttons.
class AudioCallScreen extends StatefulWidget {
  final CallModel callModel;

  const AudioCallScreen({super.key, required this.callModel});

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> with CallLifecycle {
  bool _micMuted = false;
  bool _speakerOn = false;

  @override
  CallModel get callModel => widget.callModel;

  @override
  bool get isVideo => false;

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
    final status = statusText;
    final name = otherName.isEmpty ? 'EChat user' : otherName;

    return PopScope(
      // Back hangs up rather than leaving a call running unseen.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) hangUp();
      },
      child: Scaffold(
        body: CallBackground(
          child: SafeArea(
            child: LayoutBuilder(builder: (context, constraints) {
              // A phone held sideways: person on the left, controls on the right.
              final short = constraints.maxHeight < 480;
              final avatar = short ? 72.0 : (constraints.maxHeight * 0.2).clamp(88.0, 140.0);
              final identity = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PulsingAvatar(
                    name: otherName,
                    imageUrl: otherPic,
                    size: avatar,
                    pulsing: connectedAt == null && error == null,
                  ),
                  SizedBox(height: short ? 8 : 20),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: short ? 24 : 28, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (status != null)
                    Text(status,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: error != null ? const Color(0xFFFCA5A5) : Colors.white70,
                        ))
                  else
                    CallDuration(since: connectedAt!),
                ],
              );
              final controls = ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
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
                      icon: Icons.call_end_rounded,
                      label: 'End',
                      tone: CallButtonTone.end,
                      size: 68,
                      onPressed: hangUp,
                    ),
                    CallControlButton(
                      icon: _speakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                      label: 'Speaker',
                      active: _speakerOn,
                      onPressed: !ready
                          ? null
                          : () {
                              setState(() => _speakerOn = !_speakerOn);
                              session.engine.setEnableSpeakerphone(_speakerOn);
                            },
                    ),
                  ],
                ),
              );

              if (short) {
                return Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: identity),
                      ),
                    ),
                    Expanded(child: Center(child: Padding(padding: const EdgeInsets.all(16), child: controls))),
                  ],
                );
              }
              return Column(
                children: [
                  const SizedBox(height: 16),
                  const Text('Voice call', style: TextStyle(fontSize: 14, color: Colors.white70)),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: identity,
                      ),
                    ),
                  ),
                  Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 32), child: controls),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
