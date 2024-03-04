import 'dart:math';
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
      channelId: Random().nextInt(1000).toString(),
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

    callModel.hasDialled = true;

    if (callMade) {
      LogRepository.addLogs(callLogModel);
      print("CallUtils ${callModel.channelId}");
      if(callType=='videoCall'){
        Navigator.push(context, MaterialPageRoute(builder: (context) => CallScreen(callModel: callModel)));
      }else if(callType == "audioCall"){
        Navigator.push(context, MaterialPageRoute(builder: (context) => AudioCallScreen(callModel: callModel)));
      }

    }
    return callModel;
  }
}
