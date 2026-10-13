import 'package:cloud_firestore/cloud_firestore.dart';

/// Tick status of a message, stored on both copies. It only ever moves
/// forward: sent -> delivered (reached their phone) -> read (they opened the
/// chat). Messages from before ticks existed have no status ('').
class MessageStatus {
  static const String sent = 'sent';
  static const String delivered = 'delivered';
  static const String read = 'read';

  /// 0 for no status, then 1, 2, 3 in the order above.
  static int rank(String status) => const [sent, delivered, read].indexOf(status) + 1;
}

class MessageModel{
  String senderId = "";
  String receiverId = "";
  String type = "";
  String message= "";
  String photoUrl="";
  String videoUrl = "";
  String thumbnailUrl = "";
  String pdfUrl = "";
  String pdfName = "";
  // Original name of an uploaded file (any type); '' for text and photos.
  String fileName = "";
  late Timestamp timestamp;
  // See MessageStatus. '' on messages saved before ticks existed.
  String status = "";
  // Calls only (type 'call'): 'audioCall' / 'videoCall', and how long the
  // two people talked, in seconds (0 for a missed call).
  String callType = "";
  int callDuration = 0;

  MessageModel({
    required this.senderId,
    required this.receiverId,
    required this.type,
    required this.message,
    required this.timestamp,
    required this.photoUrl,
    required this.thumbnailUrl,
    required this.pdfUrl,
    required this.pdfName,
    this.fileName = "",
    this.status = MessageStatus.sent,
});

//MessageModel.imageMessage is a constructor named imageMessage for a class called MessageModel
  MessageModel.imageMessage({
    required this.senderId,
    required this.receiverId,
    required this.type,
    required this.message,
    required this.timestamp,
    required this.photoUrl,
    this.status = MessageStatus.sent});

  /// A call shown in the chat, like WhatsApp's "Voice call · 3 min".
  /// [answered] false means nobody picked up.
  MessageModel.call({
    required this.senderId,
    required this.receiverId,
    required this.callType,
    required bool answered,
    required this.callDuration,
    required this.timestamp,
    this.status = MessageStatus.sent,
  })  : type = 'call',
        message = answered ? 'answered' : 'missed';

  bool get isDeleted => type == 'deleted';
  bool get isCall => type == 'call';
  bool get isMissedCall => isCall && message != 'answered';
  bool get isVideoCall => callType == 'videoCall';

  Map toMap(){
    var map=<String,dynamic>{};
    map['senderId']=senderId;
    map['receiverId']=receiverId;
    map['type']=type;
    map['message']=message;
    map['timestamp']=timestamp;
    map['photoUrl']=photoUrl;
    map['videoUrl'] = videoUrl;
    map['thumbnailUrl'] = thumbnailUrl;
    map['pdfUrl'] = pdfUrl;
    map['pdfName'] = pdfName;
    map['fileName'] = fileName;
    map['status'] = status;
    if (isCall) {
      map['callType'] = callType;
      map['callDuration'] = callDuration;
    }
    return map;
  }

  // Missing fields (older messages) fall back to defaults instead of throwing.
  MessageModel.fromMap(Map<dynamic,dynamic> map){
    senderId = map['senderId'] ?? '';
    receiverId = map['receiverId'] ?? '';
    type = map['type'] ?? '';
    message = map['message'] ?? '';
    timestamp = map['timestamp'] is Timestamp ? map['timestamp'] : Timestamp.now();
    photoUrl = map['photoUrl'] ?? '';
    videoUrl = map['videoUrl'] ?? '';
    thumbnailUrl = map['thumbnailUrl'] ?? '';
    pdfUrl = map['pdfUrl'] ?? '';
    pdfName = map['pdfName'] ?? '';
    fileName = map['fileName'] ?? '';
    status = map['status'] is String ? map['status'] : '';
    callType = map['callType'] ?? '';
    callDuration = (map['callDuration'] as num?)?.toInt() ?? 0;
  }

  /// What "Delete for everyone" leaves behind on both copies: the text and
  /// any file links are wiped, the rest (who, when) stays.
  static const Map<String, dynamic> deletedFields = {
    'type': 'deleted',
    'message': '',
    'photoUrl': '',
    'videoUrl': '',
    'thumbnailUrl': '',
    'pdfUrl': '',
    'pdfName': '',
    'fileName': '',
  };
}
