import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel{
  String senderId = "";
  String receiverId = "";
  String type = "";
  String message= "";
  String photoUrl="";
  late Timestamp timestamp;

  MessageModel({
    required this.senderId,
    required this.receiverId,
    required this.type,
    required this.message,
    required this.timestamp
});

//MessageModel.imageMessage is a constructor named imageMessage for a class called MessageModel
  MessageModel.imageMessage({
    required this.senderId,
    required this.receiverId,
    required this.type,
    required this.message,
    required this.timestamp,
    required this.photoUrl});

  Map toMap(){
    var map=<String,dynamic>{};
    map['senderId']=senderId;
    map['receiverId']=receiverId;
    map['type']=type;
    map['message']=message;
    map['timestamp']=timestamp;
    map['photoUrl']=photoUrl;
    return map;
  }

  MessageModel.fromMap(Map<dynamic,dynamic> map){
    senderId=map['senderId'];
    receiverId=map['receiverId'];
    type=map['type'];
    message=map['message'];
    timestamp=map['timestamp'];
  }

}