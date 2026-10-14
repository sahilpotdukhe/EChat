import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echat/models/message_model.dart';
import 'package:echat/providers/image_upload_provider.dart';
import 'package:echat/resources/chat_firebase_methods.dart';
import 'package:echat/resources/media_compressor.dart';
import 'package:echat/resources/media_storage.dart';
import 'package:echat/utils/message_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';

// Uploads chat media (to Supabase, see MediaStorage), then saves the
// message. The push notification is sent by the notification server (see
// NotificationService). Both upload methods throw on failure so the chat
// screen can tell the user; the "uploading" spinner is always cleared.
class ChatMediaUploader{

  final ChatFirebaseMethods _chatFirebaseMethods = ChatFirebaseMethods();

  Future<void> uploadImage(XFile image, String receiverId, String senderId, ImageUploadProvider imageUploadProvider, Function(double) onProgress) async {
    imageUploadProvider.setToLoading();
    try{
      // Already shrunk by the picker (see MediaCompressor), which saves JPEG
      // in most cases but may keep a PNG as PNG.
      final bool png = MessageUtils.fileExtension(image.path) == 'png';
      final String imageUrl = await MediaStorage.uploadFile(
        folder: MediaStorage.chatFolder,
        uid: senderId,
        file: File(image.path),
        name: png ? 'photo.png' : 'photo.jpg',
        contentType: png ? 'image/png' : 'image/jpeg',
      );
      onProgress(1);

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
    File? compressed;
    try {
      final File original = File(path);
      String fileName = pickedFile.name;
      String fileExtension = MessageUtils.fileExtension(fileName);
      final MessageKind kind = MessageUtils.kindForType(fileExtension);

      // Videos are shrunk to a smaller .mp4 first; if that isn't possible
      // the original is sent.
      File file = original;
      if (kind == MessageKind.video) {
        compressed = await MediaCompressor.compressVideo(original);
        if (compressed != null) {
          file = compressed;
          fileExtension = 'mp4';
          fileName = '${_withoutExtension(fileName)}.mp4';
        }
      }

      final String downloadUrl = await MediaStorage.uploadFile(
        folder: MediaStorage.chatFolder,
        uid: senderId,
        file: file,
        name: fileName,
        contentType: _contentType(kind, fileExtension),
      );
      onProgress(1);

      String thumbnailUrl = '';
      String pdfUrl = '';
      String pdfName = '';
      if (kind == MessageKind.video) {
        thumbnailUrl = await _generateThumbnailandUpload(original.path, senderId);
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
      if (compressed != null) await MediaCompressor.cleanUp();
      imageUploadProvider.setToIdle();
    }
  }

  String _withoutExtension(String name) {
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  // Lets browsers and other apps open the link the right way. Unknown
  // types are left for Supabase to guess.
  String? _contentType(MessageKind kind, String extension) {
    switch (kind) {
      case MessageKind.image:
        return 'image/${extension == 'jpg' ? 'jpeg' : extension}';
      case MessageKind.video:
        return extension == 'mov' ? 'video/quicktime' : 'video/$extension';
      case MessageKind.pdf:
        return 'application/pdf';
      default:
        return null;
    }
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
        quality: 75,
      );
      if (thumbnail == null) return '';

      return await MediaStorage.uploadBytes(
        folder: MediaStorage.thumbnailFolder,
        uid: senderId,
        bytes: thumbnail,
        name: 'thumbnail.jpg',
        contentType: 'image/jpeg',
      );
    } catch (e) {
      debugPrint('Could not make a video thumbnail: $e');
      return '';
    }
  }
}
