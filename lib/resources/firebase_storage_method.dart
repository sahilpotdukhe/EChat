import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/models/message_model.dart';
import 'package:echat/providers/image_upload_provider.dart';
import 'package:echat/resources/chat_firebase_methods.dart';
import 'package:echat/utils/message_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';

// Uploads chat media, then saves the message. Each user uploads into their own
// folder (see storage.rules). The push notification is sent by the
// notifyNewMessage Cloud Function. Both upload methods throw on failure so the
// chat screen can tell the user; the "uploading" spinner is always cleared.
class FirebaseStorageMethod{

  final ChatFirebaseMethods _chatFirebaseMethods = ChatFirebaseMethods();

  Future<void> uploadImage(XFile image, String receiverId, String senderId, ImageUploadProvider imageUploadProvider, Function(double) onProgress) async {
    imageUploadProvider.setToLoading();
    try{
      final picture = '$receiverId-${DateTime.now().microsecondsSinceEpoch}.jpg';
      final Reference ref = FirebaseStorage.instance.ref().child('Media/$senderId/$picture');
      final String imageUrl = await _upload(ref, File(image.path), onProgress, SettableMetadata(contentType: 'image/jpeg'));

      MessageModel messageModel = MessageModel.imageMessage(
          senderId: senderId,
          receiverId: receiverId,
          type: 'Image',
          message: 'IMAGE',
          timestamp: Timestamp.now(),
          photoUrl: imageUrl
      );
      await _chatFirebaseMethods.addMessagetoDb(messageModel);
    } finally {
      imageUploadProvider.setToIdle();
    }
  }

  Future<void> uploadAnyFile(PlatformFile pickedFile, String receiverId, String senderId, ImageUploadProvider imageUploadProvider, Function(double) onProgress) async {
    final String? path = pickedFile.path;
    if (path == null) throw Exception('The picked file has no path on this device');

    imageUploadProvider.setToLoading();
    try {
      final File file = File(path);
      final String fileName = pickedFile.name;
      final String fileExtension = MessageUtils.fileExtension(fileName);
      final MessageKind kind = MessageUtils.kindForType(fileExtension);

      // Timestamp prefix keeps two files with the same name from overwriting each other.
      final Reference ref = FirebaseStorage.instance.ref().child('Media/$senderId/${DateTime.now().microsecondsSinceEpoch}_$fileName');
      final String downloadUrl = await _upload(ref, file, onProgress, null);

      String thumbnailUrl = '';
      String pdfUrl = '';
      String pdfName = '';
      if (kind == MessageKind.video) {
        thumbnailUrl = await _generateThumbnailandUpload(file.path, senderId);
      }else if(kind == MessageKind.pdf){
        pdfUrl = downloadUrl;
        pdfName = fileName;
      }

      // Files without an extension are stored as type 'file'.
      final String type = fileExtension.isEmpty ? 'file' : fileExtension;
      MessageModel messageModel = MessageModel(
          senderId: senderId,
          receiverId: receiverId,
          type: type,
          message: type,
          timestamp: Timestamp.now(),
          photoUrl: downloadUrl,
          thumbnailUrl: thumbnailUrl,
          pdfUrl: pdfUrl,
          pdfName: pdfName,
          fileName: fileName,
      );
      await _chatFirebaseMethods.addMessagetoDb(messageModel);
    } finally {
      imageUploadProvider.setToIdle();
    }
  }

  // Uploads [file] to [ref], reporting progress (0..1), and returns its download URL.
  Future<String> _upload(Reference ref, File file, Function(double) onProgress, SettableMetadata? metadata) async {
    final UploadTask task = ref.putFile(file, metadata);
    task.snapshotEvents.listen((TaskSnapshot snapshot) {
      // totalBytes is 0 until the upload starts.
      if (snapshot.totalBytes > 0) onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
    }, onError: (_) {}); // the error is thrown by `await task` below
    final TaskSnapshot done = await task;
    return done.ref.getDownloadURL();
  }

  // Builds the thumbnail from the local video file, then uploads it.
  // Returns '' if no thumbnail could be made, so the message still sends.
  Future<String> _generateThumbnailandUpload(String videoPath, String senderId) async {
    try {
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
      return await storageRef.getDownloadURL();
    } catch (e) {
      debugPrint('Could not make a video thumbnail: $e');
      return '';
    }
  }
}
