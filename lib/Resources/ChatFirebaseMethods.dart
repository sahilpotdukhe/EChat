import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/Models/ContactModel.dart';
import 'package:echat/Models/MessageModel.dart';
import 'package:echat/Models/UserModel.dart';

class ChatFirebaseMethods{
  FirebaseFirestore firestore = FirebaseFirestore.instance;


  Future<void> addMessagetoDb(MessageModel messageModel, UserModel sender, UserModel receiver) async {
    Map<String, dynamic> map = messageModel.toMap() as Map<String, dynamic>;

    // these is to store in the sender side
    await firestore
        .collection("messages")
        .doc(messageModel.senderId)
        .collection(messageModel.receiverId)
        .add(map);

    addToContacts(senderId: messageModel.senderId, receiverId: messageModel.receiverId );
    // these is to store in the receiver side
    await firestore
        .collection("messages")
        .doc(messageModel.receiverId)
        .collection(messageModel.senderId)
        .add(map);
  }

  addToContacts({required String senderId, required String receiverId}) async {
    Timestamp currentTime = Timestamp.now();

    await addToSenderContacts(senderId, receiverId, currentTime);
    await addToReceiverContacts(senderId, receiverId, currentTime);

  }

  Future<void> addToSenderContacts(String senderId, String receiverId,currentTime) async{
    DocumentSnapshot senderSnapshot = await firestore.collection("Users").doc(senderId).collection("Contacts").doc(receiverId).get();
    if(!senderSnapshot.exists){
      ContactModel receiverContact = ContactModel(uid: receiverId, addedOn: currentTime);
      var receiverMap = receiverContact.toMap(receiverContact);

      await firestore.collection("Users").doc(senderId).collection("Contacts").doc(receiverId).set(receiverMap as Map<String,dynamic>);
    }
  }


  Future<void> addToReceiverContacts(String senderId, String receiverId,currentTime) async{
    DocumentSnapshot receiverSnapshot = await firestore.collection("Users").doc(receiverId).collection("Contacts").doc(senderId).get();
    if(!receiverSnapshot.exists){
      ContactModel senderContact = ContactModel(uid: senderId, addedOn: currentTime);
      var senderMap = senderContact.toMap(senderContact);

      await firestore.collection("Users").doc(receiverId).collection("Contacts").doc(senderId).set(senderMap as Map<String,dynamic>);
    }
  }

  Stream<QuerySnapshot> fetchContacts({required String userId}) =>
      firestore.collection("Users").doc(userId).collection("Contacts").snapshots();


  Stream<QuerySnapshot> fetchLastMessageBetween({required String senderId, required String receiverId}) =>
      firestore.collection("messages").doc(senderId).collection(receiverId).orderBy("timestamp").snapshots();
}