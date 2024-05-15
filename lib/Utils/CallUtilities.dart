import 'dart:convert';
import 'dart:math';
import 'package:echat/Models/CallLogModel.dart';
import 'package:echat/Resources/CallMethods.dart';
import 'package:echat/Models/CallModel.dart';
import 'package:echat/Models/UserModel.dart';
import 'package:echat/Resources/Repository/LogRepository.dart';
import 'package:echat/Screens/Call/CallScreen.dart';
import 'package:echat/Screens/Call/AudioCallScreen.dart';
import 'package:echat/Utils/utilities.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

    print("vfbr");
    print("Receivername: ${to_receiver.name}");
    print("Rexeiver url ${to_receiver.profilePhoto}");
    print("CallerName: ${from_Caller.name}");
    print("Caller url ${from_Caller.profilePhoto}");
    callModel.hasDialled = true;
    String receiverToken = to_receiver.notificationToken;

    if (callMade) {
      LogRepository.addLogs(callLogModel);
      print("CallUtils ${callModel.channelId}");
      try {
        http.Response response = await http.post(
          Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'key=AAAAq0ydI38:APA91bHE76HpjMV9xq6zd66mJyzmGoAte7AWwAMFbhVsXKMdVvDkTLs1oUrAqBLp1OdH7k8d2Lqkmp0FIDD1_r4PImOsVwZwQlWDaRrjyDTkggVaVKiCYijXLB46w-wHhqjgLiQEcaXe',
          },
          body: jsonEncode(
            <String, dynamic>{
              'notification': <String, dynamic>{
                'body': callLogModel.callerName,
                'title': 'Incoming Call',
                'image': callLogModel.callerPic,
                'channel_id': 'call_channel'
              },
              'priority': 'high',
              'data': <String, dynamic>{
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                'id': '1',
                'status': 'done',

              },
              'to': receiverToken,
            },
          ),
        );
        response;
      } catch (e) {
        print("Hello $e");
      }
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

  Future<void> sendPushNotification() async{

  }
}
