import 'package:cloud_firestore/cloud_firestore.dart';

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
  late Timestamp timestamp;

  MessageModel({
    required this.senderId,
    required this.receiverId,
    required this.type,
    required this.message,
    required this.timestamp,
    required this.photoUrl,
    required this.thumbnailUrl,
    required this.pdfUrl,
    required this.pdfName
});

//MessageModel.imageMessage is a constructor named imageMessage for a class called MessageModel
  MessageModel.imageMessage({
    required this.senderId,
    required this.receiverId,
    required this.type,
    required this.message,
    required this.timestamp,
    required this.photoUrl});

  MessageModel.videoMessage({
    required this.senderId,
    required this.receiverId,
    required this.type,
    required this.message,
    required this.timestamp,
    required this.videoUrl,
    required this.thumbnailUrl,
  });

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
    return map;
  }

  MessageModel.fromMap(Map<dynamic,dynamic> map){
    senderId=map['senderId'];
    receiverId=map['receiverId'];
    type=map['type'];
    message=map['message'];
    timestamp=map['timestamp'];
    photoUrl = map['photoUrl'];
    videoUrl = map['videoUrl'];
    thumbnailUrl = map['thumbnailUrl'];
    pdfUrl = map['pdfUrl'];
    pdfName = map['pdfName'];
  }

}