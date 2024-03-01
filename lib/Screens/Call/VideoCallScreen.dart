// import 'package:echat/Models/CallModel.dart';
// import 'package:flutter/material.dart';
// import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
//
// class VideoCallScreen extends StatefulWidget {
//   final CallModel callModel;
//   const VideoCallScreen({super.key, required this.callModel});
//
//   @override
//   State<VideoCallScreen> createState() => _VideoCallScreenState();
// }
//
// class _VideoCallScreenState extends State<VideoCallScreen> {
//   String channelId = "";
//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     channelId = widget.callModel.channelId;
//
//   }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//           child: ZegoUIKitPrebuiltCall(
//               appID: 2012045517,
//               appSign: '295ae998b0e2587fe5c046e584baf021cc8c0ab254e635dac96ef2bde4397f02',
//               callID: channelId,
//               userName: widget.callModel.receiverName,
//               userID: widget.callModel.receiverPic,
//               config:ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall(),
//           )
//
//       ),
//     );
//   }
// }
