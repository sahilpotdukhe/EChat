import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/models/contact_model.dart';
import 'package:echat/models/message_model.dart';
import 'package:echat/resources/notification_service.dart';

class ChatFirebaseMethods{
  FirebaseFirestore firestore = FirebaseFirestore.instance;


  // Saves the sender's and the receiver's copy together: both or neither.
  // Offline, Firestore shows the message right away and the returned future
  // completes once it reaches the server; it only throws on a real failure
  // (e.g. rejected by security rules).
  Future<void> addMessagetoDb(MessageModel messageModel) async {
    Map<String, dynamic> map = messageModel.toMap() as Map<String, dynamic>;

    final DocumentReference senderCopy = firestore
        .collection("messages")
        .doc(messageModel.senderId)
        .collection(messageModel.receiverId)
        .doc();
    // Same id on both sides makes the two copies easy to match up.
    final DocumentReference receiverCopy = firestore
        .collection("messages")
        .doc(messageModel.receiverId)
        .collection(messageModel.senderId)
        .doc(senderCopy.id);

    final WriteBatch batch = firestore.batch();
    batch.set(senderCopy, map);
    batch.set(receiverCopy, map);
    await batch.commit();

    // Not awaited: a slow or unreachable notification server must not delay
    // or fail the message itself.
    NotificationService.notifyMessage(messageId: senderCopy.id, receiverId: messageModel.receiverId);

    await addToContacts(senderId: messageModel.senderId, receiverId: messageModel.receiverId);
  }

  Future<void> addToContacts({required String senderId, required String receiverId}) async {
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


  // Only the newest message, for the chat list preview.
  Stream<QuerySnapshot> fetchLastMessageBetween({required String senderId, required String receiverId}) =>
      firestore.collection("messages").doc(senderId).collection(receiverId)
          .orderBy("timestamp", descending: true).limit(1).snapshots();
}