import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/resources/call_methods.dart';
import 'package:echat/models/call_model.dart';
import 'package:echat/models/user_model.dart';
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

    CallResult result = await callMethods.makeCall(callModel: callModel);
    callModel.hasDialled = true;

    // The call history entry (and the call in the chat) is saved when the
    // call screen closes, once its length is known (see CallLifecycle).

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
