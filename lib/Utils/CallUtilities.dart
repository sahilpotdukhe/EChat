import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/Models/CallLogModel.dart';
import 'package:echat/Resources/CallMethods.dart';
import 'package:echat/Models/CallModel.dart';
import 'package:echat/Models/UserModel.dart';
import 'package:echat/Resources/Repository/LogRepository.dart';
import 'package:echat/Screens/Call/CallScreen.dart';
import 'package:echat/Screens/Call/AudioCallScreen.dart';
import 'package:flutter/material.dart';

class CallUtilities {
  static CallMethods callMethods = CallMethods();

  static Future<CallModel> dial({required UserModel from_Caller, required UserModel to_receiver, context,required String callType}) async {

    CallModel callModel = CallModel(
      callerId: from_Caller.uid,
      callerName: from_Caller.name,
      callerPic: from_Caller.profilePhoto,
      receiverId: to_receiver.uid,
      receiverName: to_receiver.name,
      receiverPic: to_receiver.profilePhoto,
      // Random 20-character id: unique per call and not guessable,
      // so nobody can join someone else's call room.
      channelId: FirebaseFirestore.instance.collection('Call').doc().id,
      callType: callType,
    );

    CallLogModel callLogModel = CallLogModel(
        callerName: from_Caller.name,
        callerPic: from_Caller.profilePhoto,
        receiverName: to_receiver.name,
        receiverPic: to_receiver.profilePhoto,
        callStatus: "Dialled",
        timestamp: DateTime.now().toString(),
        callType: callType
    );

    bool callMade = await callMethods.makeCall(callModel: callModel);

    print("vfbr");
    print("Receivername: ${to_receiver.name}");
    print("Rexeiver url ${to_receiver.profilePhoto}");
    print("CallerName: ${from_Caller.name}");
    print("Caller url ${from_Caller.profilePhoto}");
    callModel.hasDialled = true;

    if (callMade) {
      LogRepository.addLogs(callLogModel);
      print("CallUtils ${callModel.channelId}");
      // The incoming-call notification is sent by the notifyIncomingCall Cloud Function.
      if(callType=='videoCall'){
        print("vfbr");
        Navigator.push(context, MaterialPageRoute(builder: (context) => CallScreen(callModel: callModel)));
      }else if(callType == "audioCall"){
        print("vfbr");
        Navigator.push(context, MaterialPageRoute(builder: (context) => AudioCallScreen(callModel: callModel)));
      }
    }
    return callModel;
  }
}
