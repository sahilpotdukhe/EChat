import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/Models/MessageModel.dart';
import 'package:echat/Provider/ImageUploadProvider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class FirebaseStorageMethod{

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  void uploadImage(XFile? image, String receiverId, String senderId, ImageUploadProvider imageUploadProvider) async {
    try{
      imageUploadProvider.setToLoading();

      late String imageUrl;
      FirebaseStorage storage = FirebaseStorage.instance;
      final picture = '${senderId.toString()} ${receiverId.toString()} Time:${DateTime.now().microsecondsSinceEpoch.toString()}.jpg';

      //For example, let's say you have an image file named "myImage.jpg" The full path to this image file would be:C:\Users\username\Pictures\myImage.jpg
      final File imagep = File(image!.path);//  It appears that image is a variable holding information(metadata) about an image. The .path property retrieves the file path of the image which is in the metadata

      UploadTask task = storage.ref().child('Media/$picture').putFile(imagep); //ref(): This method retrieves a reference to the root location of your Firebase Storage.
      // putFile(imagep): This method is used to upload a file (imagep in this case) to the specified location in Firebase Storage.

      TaskSnapshot snapshot = (await task.whenComplete(() => task.snapshot)); //it returns task.snapshot, which represents the final status of the upload task.
      await task.whenComplete(() async {
        imageUrl = await snapshot.ref.getDownloadURL();}
      ); //snapshot.ref refers to the reference of the uploaded file in Firebase Storage, and getDownloadURL() retrieves the URL that can be used to download the file.

      imageUploadProvider.setToIdle();

      MessageModel messageModel = MessageModel.imageMessage(
          senderId: senderId,
          receiverId: receiverId,
          type: 'image',
          message: 'IMAGE',
          timestamp: Timestamp.now(),
          photoUrl: imageUrl
      );

      Map<String, dynamic> map = messageModel.toMap() as Map<String, dynamic>;
      // these is to store in the sender side
      await firestore
          .collection("messages")
          .doc(messageModel.senderId)
          .collection(messageModel.receiverId)
          .add(map);

      // these is to store in the receiver side
      await firestore
          .collection("messages")
          .doc(messageModel.receiverId)
          .collection(messageModel.senderId)
          .add(map);
    }catch(e){
      print(e);
    }
  }
}