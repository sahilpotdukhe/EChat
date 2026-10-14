import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:video_compress/video_compress.dart';

/// Shrinks photos and videos before they are uploaded, so they send faster
/// and load faster for the other person (the way WhatsApp does). Documents
/// and PDFs are sent untouched.
class MediaCompressor {
  /// Photos from the gallery or camera: longest side at most this many
  /// pixels, saved as JPEG at this quality (0-100). Plenty for a phone
  /// screen; a 4-8 MB camera photo becomes roughly 200-500 KB.
  static const double maxPhotoSide = 1600;
  static const int photoQuality = 75;

  /// Re-encodes a video at 960x540 (keeping the sound) as an .mp4. Returns
  /// the smaller file, or null to send the original instead (unsupported
  /// platform, already small, another compression running, or an error).
  /// The caller deletes the returned file after uploading ([cleanUp]).
  static Future<File?> compressVideo(File original) async {
    if (!(Platform.isAndroid || Platform.isIOS)) return null;
    if (VideoCompress.isCompressing) return null;
    try {
      final MediaInfo? info = await VideoCompress.compressVideo(
        original.path,
        quality: VideoQuality.Res960x540Quality,
        includeAudio: true,
      );
      final String? path = info?.path;
      if (path == null) return null;
      final File compressed = File(path);
      // A video that was already small can come out bigger: keep the original.
      if (await compressed.length() >= await original.length()) {
        await cleanUp();
        return null;
      }
      return compressed;
    } catch (e) {
      debugPrint('Could not compress the video, sending the original: $e');
      return null;
    }
  }

  /// Deletes the compressed copies kept in the app's cache.
  static Future<void> cleanUp() async {
    try {
      await VideoCompress.deleteAllCache();
    } catch (e) {
      debugPrint('Could not clear compressed videos: $e');
    }
  }
}
