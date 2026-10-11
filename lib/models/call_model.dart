import 'package:cloud_firestore/cloud_firestore.dart';

class CallModel{
  String callerId="";
  String callerName="";
  String callerPic="";
  String receiverId="";
  String receiverName="";
  String receiverPic="";
  String channelId="";
  String callType ="";
  bool hasDialled=false;
  // Set by the server when the call is placed. Null on docs from old app
  // builds, and on the caller's device until the server write lands.
  Timestamp? createdAt;
  // True once the receiver picks up.
  bool accepted=false;

  CallModel({
    required this.callerId,
    required this.callerName,
    required this.callerPic,
    required this.receiverId,
    required this.receiverName,
    required this.receiverPic,
    required this.channelId,
    required this.callType,
    this.createdAt,
    this.accepted = false,
  });

  Map toMap(CallModel call) {
    var callMap = <String, dynamic>{};
    callMap["caller_id"] = call.callerId;
    callMap["caller_name"] = call.callerName;
    callMap["caller_pic"] = call.callerPic;
    callMap["receiver_id"] = call.receiverId;
    callMap["receiver_name"] = call.receiverName;
    callMap["receiver_pic"] = call.receiverPic;
    callMap["channel_id"] = call.channelId;
    callMap["has_dialled"] = call.hasDialled;
    callMap["callType"] = call.callType;
    callMap["created_at"] = call.createdAt;
    callMap["accepted"] = call.accepted;
    return callMap;
  }

  // Old docs don't have every field, so fall back to defaults.
  CallModel.fromMap(Map callMap) {
    callerId = callMap["caller_id"] ?? "";
    callerName = callMap["caller_name"] ?? "";
    callerPic = callMap["caller_pic"] ?? "";
    receiverId = callMap["receiver_id"] ?? "";
    receiverName = callMap["receiver_name"] ?? "";
    receiverPic = callMap["receiver_pic"] ?? "";
    channelId = callMap["channel_id"] ?? "";
    hasDialled = callMap["has_dialled"] ?? false;
    callType = callMap["callType"] ?? "";
    createdAt = callMap["created_at"] is Timestamp ? callMap["created_at"] : null;
    accepted = callMap["accepted"] ?? false;
  }
}
