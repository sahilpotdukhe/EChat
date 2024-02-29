class CallLogModel{

  int? callLogId;
  String callerName = "";
  String callerPic = "";
  String receiverName = "";
  String receiverPic = "";
  String callStatus = "";
  String timestamp = "";

  CallLogModel({
    this.callLogId,
    required this.callerName,
    required this.callerPic,
    required this.receiverName,
    required this.receiverPic,
    required this.callStatus,
    required this.timestamp
});

  Map<String,dynamic> toMap(CallLogModel callLogModel){
    Map<String,dynamic> logMap = Map();
    logMap['callLog_id'] = callLogModel.callLogId;
    logMap['caller_name'] = callLogModel.callerName;
    logMap['caller_pic'] = callLogModel.callerPic;
    logMap['receiver_name'] = callLogModel.receiverName;
    logMap['receiver_pic'] = callLogModel.receiverPic;
    logMap['call_status'] = callLogModel.callStatus;
    logMap['timestamp'] = callLogModel.timestamp;
    return logMap;
  }

  CallLogModel.fromMap(Map logMap){
    callLogId = logMap['callLog_id'];
    callerName = logMap['caller_name'];
    callerPic = logMap['caller_pic'];
    receiverName = logMap['receiver_name'];
    receiverPic = logMap['receiver_pic'];
    callStatus = logMap['call_status'];
    timestamp = logMap['timestamp'];
  }

}