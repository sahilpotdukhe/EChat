import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/Models/CallModel.dart';

class CallMethods{

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // This will constantly notices that whether there is any call documents are not
  Stream<DocumentSnapshot> callStream({required String uid}){
    return firestore.collection("Call").doc(uid).snapshots();
  }

  Future<bool> makeCall({required CallModel callModel}) async{
    try{
      // These is for the caller...it's hasDialled value will be set to true because it is dialing the call
      callModel.hasDialled = true;
      Map<String,dynamic> hasDialledMap = callModel.toMap(callModel) as Map<String,dynamic>;
      await firestore.collection("Call").doc(callModel.callerId).set(hasDialledMap);

      // These is for the receiver...the hasDialled value will be set to false
      callModel.hasDialled = false;
      Map<String,dynamic> hasNotDialledMap = callModel.toMap(callModel) as Map<String,dynamic>;
      await firestore.collection("Call").doc(callModel.receiverId).set(hasNotDialledMap);

      return true;
    }catch(e){
      print(e);
      return false;
    }
  }

  Future<bool> endCall({required CallModel callModel}) async{
    try{
      await firestore.collection("Call").doc(callModel.callerId).delete();
      await firestore.collection("Call").doc(callModel.receiverId).delete();
      return true;
    }catch(e){
      print(e);
      return false;
    }
  }
}