import 'dart:async';
import 'dart:convert';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:echat/resources/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:permission_handler/permission_handler.dart';

/// One Agora voice/video call: fetches a token, joins the channel and tracks
/// the remote user. Used by CallScreen and AudioCallScreen.
class AgoraCallSession {
  // Must be the same Agora project the servers sign passes for (also in
  // server/src/app.js),
  // otherwise Agora rejects the token and the call never connects.
  static const String appId = '4e3d9239cb394c08beae2ed37754bf1d';
  static const String _tokenServer =
      'https://agora-node-tokenserver-new.onrender.com/access_token';

  final String channelId;
  final bool video;
  final RtcEngine engine = createAgoraRtcEngine();

  /// Agora uid of the other person, or null until they join / after they leave.
  final ValueNotifier<int?> remoteUid = ValueNotifier<int?>(null);

  bool _released = false;

  AgoraCallSession({required this.channelId, required this.video});

  Future<void> start() async {
    // Fetch the call pass while the permission prompt is up.
    final Future<String> tokenFuture = _fetchToken();
    // Don't report a pass failure as unhandled while still waiting here.
    tokenFuture.ignore();
    await [Permission.microphone, if (video) Permission.camera].request();
    final token = await tokenFuture;

    await engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));
    engine.registerEventHandler(RtcEngineEventHandler(
      onError: (err, msg) => debugPrint('Agora error: $err $msg'),
      onConnectionStateChanged: (connection, state, reason) =>
          debugPrint('Agora connection: $state ($reason)'),
      onJoinChannelSuccess: (connection, elapsed) =>
          debugPrint('Agora joined channel ${connection.channelId}'),
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

  // The call pass comes from EChat's own server (fast, kept awake, and only
  // gives passes to people in the call). Until that server has the Agora
  // certificate set up, fall back to the old token server.
  Future<String> _fetchToken() async {
    try {
      return await NotificationService.callToken(channelId);
    } catch (e) {
      debugPrint('EChat server call pass failed, trying the old token server: $e');
    }
    final Response response;
    try {
      // The free-tier server can take a while to wake up, but not forever.
      response = await get(Uri.parse(
              '$_tokenServer?channelName=${Uri.encodeQueryComponent(channelId)}'))
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw Exception('Token server did not respond within 30 seconds');
    }
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
