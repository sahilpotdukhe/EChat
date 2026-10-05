import 'dart:convert';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:permission_handler/permission_handler.dart';

/// One Agora voice/video call: fetches a token, joins the channel and tracks
/// the remote user. Used by CallScreen and AudioCallScreen.
class AgoraCallSession {
  static const String appId = '3a5f9bfe0efa423e9eaf5447565e0f7b';
  static const String videoTokenServer =
      'https://agora-node-tokenserver-new.onrender.com/access_token';
  static const String audioTokenServer =
      'https://agoratokenserver-ny1v.onrender.com/access_token';

  final String channelId;
  final bool video;
  final RtcEngine engine = createAgoraRtcEngine();

  /// Agora uid of the other person, or null until they join / after they leave.
  final ValueNotifier<int?> remoteUid = ValueNotifier<int?>(null);

  bool _released = false;

  AgoraCallSession({required this.channelId, required this.video});

  String get _tokenServer => video ? videoTokenServer : audioTokenServer;

  Future<void> start() async {
    await [Permission.microphone, if (video) Permission.camera].request();
    final token = await _fetchToken();

    await engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));
    engine.registerEventHandler(RtcEngineEventHandler(
      onUserJoined: (connection, uid, elapsed) => remoteUid.value = uid,
      onUserOffline: (connection, uid, reason) {
        if (remoteUid.value == uid) remoteUid.value = null;
      },
    ));

    if (video) {
      await engine.enableVideo();
      await engine.startPreview();
    } else {
      await engine.disableVideo();
    }

    await engine.joinChannel(
      token: token,
      channelId: channelId,
      uid: 0,
      options: ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishMicrophoneTrack: true,
        publishCameraTrack: video,
        autoSubscribeAudio: true,
        autoSubscribeVideo: video,
      ),
    );
  }

  Future<String> _fetchToken() async {
    final response = await get(Uri.parse(
        '$_tokenServer?channelName=${Uri.encodeQueryComponent(channelId)}'));
    if (response.statusCode != 200) {
      throw Exception('Token server returned ${response.statusCode}');
    }
    return json.decode(response.body)['token'].toString();
  }

  Future<void> release() async {
    if (_released) return;
    _released = true;
    try {
      await engine.leaveChannel();
      await engine.release();
    } catch (e) {
      debugPrint('Error releasing Agora engine: $e');
    }
    remoteUid.dispose();
  }
}
