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

  CallModel({
    required this.callerId,
    required this.callerName,
    required this.callerPic,
    required this.receiverId,
    required this.receiverName,
    required this.receiverPic,
    required this.channelId,
    required this.callType
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
    return callMap;
  }

  CallModel.fromMap(Map callMap) {
    callerId = callMap["caller_id"];
    callerName = callMap["caller_name"];
    callerPic = callMap["caller_pic"];
    receiverId = callMap["receiver_id"];
    receiverName = callMap["receiver_name"];
    receiverPic = callMap["receiver_pic"];
    channelId = callMap["channel_id"];
    hasDialled = callMap["has_dialled"];
    callType = callMap["callType"];
  }
}