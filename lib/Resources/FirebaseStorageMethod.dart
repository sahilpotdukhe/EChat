import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/Models/MessageModel.dart';
import 'package:echat/Provider/ImageUploadProvider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';


class FirebaseStorageMethod{

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  void uploadImage(XFile? image, String receiverId, String senderId, ImageUploadProvider imageUploadProvider, Function(double) onProgress) async {
    try{
      imageUploadProvider.setToLoading();

      late String imageUrl;
      FirebaseStorage storage = FirebaseStorage.instance;
      final picture = '$receiverId-${DateTime.now().microsecondsSinceEpoch}.jpg';

      //For example, let's say you have an image file named "myImage.jpg" The full path to this image file would be:C:\Users\username\Pictures\myImage.jpg
      final File imagep = File(image!.path);//  It appears that image is a variable holding information(metadata) about an image. The .path property retrieves the file path of the image which is in the metadata

      // Each user uploads into their own folder (see storage.rules).
      UploadTask task = storage.ref().child('Media/$senderId/$picture').putFile(imagep, SettableMetadata(contentType: 'image/jpeg')); //ref(): This method retrieves a reference to the root location of your Firebase Storage.
      // putFile(imagep): This method is used to upload a file (imagep in this case) to the specified location in Firebase Storage.
      task.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });
      TaskSnapshot snapshot = (await task.whenComplete(() => task.snapshot)); //it returns task.snapshot, which represents the final status of the upload task.
      await task.whenComplete(() async {
        imageUrl = await snapshot.ref.getDownloadURL();}
      ); //snapshot.ref refers to the reference of the uploaded file in Firebase Storage, and getDownloadURL() retrieves the URL that can be used to download the file.



      MessageModel messageModel = MessageModel.imageMessage(
          senderId: senderId,
          receiverId: receiverId,
          type: 'Image',
          message: 'IMAGE',
          timestamp: Timestamp.now(),
          photoUrl: imageUrl
      );

      Map<String, dynamic> map = messageModel.toMap() as Map<String, dynamic>;
      imageUploadProvider.setToIdle();
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
      // The push notification is sent by the notifyNewMessage Cloud Function.
    }catch(e){
      print(e);
    }
  }

  void uploadAnyFile(PlatformFile? pickedFile, String receiverId, String senderId, ImageUploadProvider imageUploadProvider, Function(double) onProgress) async {

      imageUploadProvider.setToLoading();

      if(pickedFile != null){
        File file = File(pickedFile.path!);
        String fileName = pickedFile.name;
        String fileExtension = fileName.split('.').last;

        // Timestamp prefix keeps two files with the same name from overwriting each other.
        Reference ref = FirebaseStorage.instance.ref().child('Media/$senderId/${DateTime.now().microsecondsSinceEpoch}_$fileName');
        UploadTask uploadTask = ref.putFile(file);

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
           double progress = snapshot.bytesTransferred / snapshot.totalBytes;
           onProgress(progress);
        });

        TaskSnapshot taskSnapshot = await uploadTask.whenComplete((){});
        String downloadUrl = await taskSnapshot.ref.getDownloadURL();



        String thumbnailUrl = '';
        String pdfUrl = '';
        String pdfName = '';
        if (fileExtension == 'mp4') {
          thumbnailUrl = await _generateThumbnailandUpload(file.path, senderId);
        }else if(fileExtension == 'pdf'){
          pdfUrl = downloadUrl;
          pdfName = fileName;
        }

        MessageModel messageModel = MessageModel(
            senderId: senderId,
            receiverId: receiverId,
            type: fileExtension,
            message: fileExtension,
            timestamp: Timestamp.now(),
            photoUrl: downloadUrl,
            thumbnailUrl: thumbnailUrl,
            pdfUrl: pdfUrl,
            pdfName: pdfName
        );

        // The push notification is sent by the notifyNewMessage Cloud Function.
        imageUploadProvider.setToIdle();

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
      }
  }

  // Builds the thumbnail from the local video file, then uploads it.
  // Returns '' if no thumbnail could be made, so the message still sends.
  Future<String> _generateThumbnailandUpload(String videoPath, String senderId) async {
    final thumbnail = await FcNativeVideoThumbnail().saveThumbnailToBytes(
      srcFile: videoPath,
      width: 360,
      height: 200,
      format: 'jpeg',
      quality: 90,
    );
    if (thumbnail == null) return '';

    final Reference storageRef = FirebaseStorage.instance.ref().child('thumbnails/$senderId/${DateTime.now().microsecondsSinceEpoch}.jpg');
    await storageRef.putData(thumbnail, SettableMetadata(contentType: 'image/jpeg'));

    // Get the download URL of the uploaded thumbnail image
    final String downloadURL = await storageRef.getDownloadURL();

    return downloadURL;
  }
}