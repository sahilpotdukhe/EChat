class CallLogModel{
  int? callLogId;
  String callerId = "";
  String callerName = "";
  String callerPic = "";
  String receiverId = "";
  String receiverName = "";
  String receiverPic = "";
  // "Dialled" (we called), "received" (we picked up) or "missed".
  String callStatus = "";
  String timestamp = "";
  String callType = "";

  CallLogModel({
    this.callLogId,
    this.callerId = "",
    required this.callerName,
    required this.callerPic,
    this.receiverId = "",
    required this.receiverName,
    required this.receiverPic,
    required this.callStatus,
    required this.timestamp,
    required this.callType
});

  bool get isOutgoing => callStatus == "Dialled";
  bool get isMissed => !isOutgoing && callStatus != "received";
  bool get isVideo => callType == "videoCall";

  /// The other person on the call.
  String get peerId => isOutgoing ? receiverId : callerId;
  String get peerName => isOutgoing ? receiverName : callerName;
  String get peerPic => isOutgoing ? receiverPic : callerPic;

  /// Null when the stored timestamp can't be read.
  DateTime? get time => DateTime.tryParse(timestamp);

  Map<String,dynamic> toMap(CallLogModel callLogModel){
    final logMap = <String, dynamic>{};
    logMap['callLog_id'] = callLogModel.callLogId;
    logMap['caller_id'] = callLogModel.callerId;
    logMap['caller_name'] = callLogModel.callerName;
    logMap['caller_pic'] = callLogModel.callerPic;
    logMap['receiver_id'] = callLogModel.receiverId;
    logMap['receiver_name'] = callLogModel.receiverName;
    logMap['receiver_pic'] = callLogModel.receiverPic;
    logMap['call_status'] = callLogModel.callStatus;
    logMap['timestamp'] = callLogModel.timestamp;
    logMap['callType'] = callLogModel.callType;
    return logMap;
  }

  // Logs saved before ids were stored (or with missing fields) fall back to
  // empty values instead of throwing.
  CallLogModel.fromMap(Map logMap){
    callLogId = logMap['callLog_id'];
    callerId = logMap['caller_id'] ?? '';
    callerName = logMap['caller_name'] ?? '';
    callerPic = logMap['caller_pic'] ?? '';
    receiverId = logMap['receiver_id'] ?? '';
    receiverName = logMap['receiver_name'] ?? '';
    receiverPic = logMap['receiver_pic'] ?? '';
    callStatus = logMap['call_status'] ?? '';
    timestamp = logMap['timestamp'] ?? '';
    callType = logMap['callType'] ?? '';
  }
}
