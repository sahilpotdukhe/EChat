import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/models/call_log_model.dart';
import 'package:echat/resources/call_methods.dart';
import 'package:echat/models/call_model.dart';
import 'package:echat/models/user_model.dart';
import 'package:echat/resources/repositories/log_repository.dart';
import 'package:echat/screens/call/call_screen.dart';
import 'package:echat/screens/call/audio_call_screen.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_kit/shadcn_kit.dart';

class CallUtilities {
  static CallMethods callMethods = CallMethods();

  static Future<CallModel> dial({required UserModel fromCaller, required UserModel toReceiver, required BuildContext context,required String callType}) async {

    CallModel callModel = CallModel(
      callerId: fromCaller.uid,
      callerName: fromCaller.name,
      callerPic: fromCaller.profilePhoto,
      receiverId: toReceiver.uid,
      receiverName: toReceiver.name,
      receiverPic: toReceiver.profilePhoto,
      // Random 20-character id: unique per call and not guessable,
      // so nobody can join someone else's call room.
      channelId: FirebaseFirestore.instance.collection('Call').doc().id,
      callType: callType,
    );

    CallLogModel callLogModel = CallLogModel(
        callerId: fromCaller.uid,
        receiverId: toReceiver.uid,
        callerName: fromCaller.name,
        callerPic: fromCaller.profilePhoto,
        receiverName: toReceiver.name,
        receiverPic: toReceiver.profilePhoto,
        callStatus: "Dialled",
        timestamp: DateTime.now().toString(),
        callType: callType
    );

    CallResult result = await callMethods.makeCall(callModel: callModel);
    callModel.hasDialled = true;

    // Only calls that actually went out go into the call history.
    if (result == CallResult.started) LogRepository.addLogs(callLogModel);

    if (!context.mounted) return callModel;

    if (result == CallResult.busy) {
      showShadcnToast(context,
          title: '${toReceiver.name.isEmpty ? 'They' : toReceiver.name} is on another call',
          description: 'Try again in a little while.');
    } else if (result == CallResult.failed) {
      showShadcnToast(context,
          title: 'Couldn\'t start the call',
          description: 'Check your connection and try again.',
          variant: ShadcnToastVariant.destructive);
    } else {
      // CallMethods.makeCall asks the notification server to ring the receiver.
      if(callType=='videoCall'){
        Navigator.push(context, MaterialPageRoute(builder: (context) => CallScreen(callModel: callModel)));
      }else if(callType == "audioCall"){
        Navigator.push(context, MaterialPageRoute(builder: (context) => AudioCallScreen(callModel: callModel)));
      }
    }
    return callModel;
  }
}
