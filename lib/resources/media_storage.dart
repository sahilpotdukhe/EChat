import 'dart:io';
import 'dart:math';

import 'package:echat/resources/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Where chat photos, videos, files and profile pictures are kept: a public
/// Supabase Storage bucket. Sign-in stays with Firebase: Supabase is set up
/// to trust Firebase sign-in tokens (see docs/SUPABASE_SETUP.md), and its
/// rules only let each person upload into, or delete from, their own folder.
///
/// Paths are `<folder>/<uid>/<random>_<name>`, e.g. `Media/abc123/k3j…_photo.jpg`.
/// The random part makes links impossible to guess, like Firebase's
/// download tokens did. Files already sent through Firebase Storage keep
/// working: their links are stored in the messages.
///
/// Defaults point at the EChat Supabase project; override per build with:
///   `--dart-define=SUPABASE_URL=https://<project>.supabase.co`
///   `--dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable key>`
class MediaStorage {
  static const String url = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://kndqxapcrpmktblezzts.supabase.co');
  // Publishable keys are meant to ship inside apps; the storage rules (not
  // this key) decide who may upload or delete.
  static const String publishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: 'sb_publishable_7n94gxRDggU0PmxwfjxX6A_rk6SWPT-');
  static const String bucket = String.fromEnvironment('SUPABASE_BUCKET', defaultValue: 'media');

  static const String chatFolder = 'Media';
  static const String thumbnailFolder = 'thumbnails';
  static const String profileFolder = 'Users';

  // Every upload gets a new random path and is never changed, so phones and
  // Supabase's CDN may keep a copy for a year instead of the default hour:
  // media opened before loads from the cache instead of downloading again.
  static const String _cacheSeconds = '31536000';

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;

  static bool _initialized = false;
  static Future<void>? _roleCheck;

  /// Called once from main(). Without the dart-defines above, uploads fail
  /// with a clear message instead of the app failing to start.
  static Future<void> initialize() async {
    if (!isConfigured) {
      debugPrint('MediaStorage: SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY not set; uploads are off.');
      return;
    }
    await Supabase.initialize(
      url: url,
      publishableKey: publishableKey,
      // Every Supabase request carries the Firebase sign-in token.
      accessToken: () async => FirebaseAuth.instance.currentUser?.getIdToken(),
    );
    _initialized = true;
  }

  static StorageFileApi get _files {
    if (!_initialized) {
      throw StateError('File uploads are not set up yet (Supabase keys missing from this build).');
    }
    return Supabase.instance.client.storage.from(bucket);
  }

  /// Uploads a file from disk and returns its public link.
  static Future<String> uploadFile({
    required String folder,
    required String uid,
    required File file,
    required String name,
    String? contentType,
  }) async {
    final api = _files;
    await _ensureSupabaseRole();
    final path = _pathFor(folder, uid, name);
    await api.upload(path, file, fileOptions: FileOptions(contentType: contentType, cacheControl: _cacheSeconds));
    return api.getPublicUrl(path);
  }

  /// Uploads bytes in memory (e.g. a generated video thumbnail).
  static Future<String> uploadBytes({
    required String folder,
    required String uid,
    required Uint8List bytes,
    required String name,
    String? contentType,
  }) async {
    final api = _files;
    await _ensureSupabaseRole();
    final path = _pathFor(folder, uid, name);
    await api.uploadBinary(path, bytes, fileOptions: FileOptions(contentType: contentType, cacheControl: _cacheSeconds));
    return api.getPublicUrl(path);
  }

  /// Deletes a file this app uploaded, given its public link. Links to
  /// anything else (old Firebase files, other people's files) are ignored.
  /// Never throws: a file left behind only costs storage.
  static Future<void> removeByUrl(String publicUrl) async {
    final path = storagePathFromUrl(publicUrl, url, bucket);
    if (path == null || !_initialized) return;
    try {
      await _files.remove([path]);
    } catch (e) {
      debugPrint('MediaStorage: could not delete $path: $e');
    }
  }

  /// `<supabaseUrl>/storage/v1/object/public/<bucket>/<path>` -> `<path>`,
  /// or null for any other link.
  @visibleForTesting
  static String? storagePathFromUrl(String publicUrl, String supabaseUrl, String bucket) {
    if (supabaseUrl.isEmpty) return null;
    final prefix = '$supabaseUrl/storage/v1/object/public/$bucket/';
    if (!publicUrl.startsWith(prefix)) return null;
    final path = Uri.decodeFull(publicUrl.substring(prefix.length).split('?').first);
    return path.isEmpty ? null : path;
  }

  /// A safe storage key: Supabase only accepts plain ASCII names, so other
  /// characters become "_". The original name is kept in the message.
  @visibleForTesting
  static String safeFileName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final trimmed = cleaned.length > 80 ? cleaned.substring(cleaned.length - 80) : cleaned;
    return trimmed.isEmpty ? 'file' : trimmed;
  }

  static final Random _random = Random.secure();

  static String _pathFor(String folder, String uid, String name) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final token = List.generate(20, (_) => chars[_random.nextInt(chars.length)]).join();
    return '$folder/$uid/${token}_${safeFileName(name)}';
  }

  // Supabase only treats a Firebase token as signed in when it carries the
  // claim role = "authenticated". The notification server (which holds the
  // Firebase admin key) adds it once per account; then the token is
  // refreshed so it includes it.
  static Future<void> _ensureSupabaseRole() => _roleCheck ??= () async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw StateError('Not signed in');
        final result = await user.getIdTokenResult();
        if (result.claims?['role'] == 'authenticated') return;
        await NotificationService.grantStorageAccess();
        await user.getIdToken(true);
      }()
          .catchError((Object e) {
        // Try again on the next upload.
        _roleCheck = null;
        throw e;
      });

  /// Forget the cached role check (e.g. another account signed in).
  static void reset() => _roleCheck = null;
}
