// import 'package:echat/Models/CallModel.dart';
// import 'package:flutter/material.dart';
// import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
//
// class CallInvitationPage extends StatefulWidget {
//   final CallModel callModel;
//   const CallInvitationPage({super.key, required this.callModel});
//
//   @override
//   State<CallInvitationPage> createState() => _CallInvitationPageState();
// }
//
// class _CallInvitationPageState extends State<CallInvitationPage> {
//   @override
//   Widget build(BuildContext context) {
//     return ZegoSendCallInvitationButton(
//       isVideoCall: true,
//       callID: widget.callModel.channelId,
//       resourceID: "zegouikit_call", //You need to use the resourceID that you created in the subsequent steps. Please continue reading this document.
//       invitees: [
//         ZegoUIKitUser(
//           id: widget.callModel.receiverId,
//           name: widget.callModel.receiverName,
//         )
//       ],
//     );
//   }
// }
//
//
//
