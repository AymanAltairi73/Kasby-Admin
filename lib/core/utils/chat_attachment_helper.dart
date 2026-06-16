import 'package:kasby_admin/core/services/supabase_service.dart';

/// Resolves chat attachment paths/URLs to loadable image URLs (signed URLs for private bucket).
class ChatAttachmentHelper {
  ChatAttachmentHelper._();

  static const String bucket = 'chat_attachments';
  static const int signedUrlTtlSeconds = 60 * 60 * 24;

  static String extractStoragePath(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return trimmed;

    if (!trimmed.startsWith('http')) {
      return trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return trimmed;

    final segments = uri.pathSegments;
    final bucketIndex = segments.indexOf(bucket);
    if (bucketIndex >= 0 && bucketIndex + 1 < segments.length) {
      return segments.sublist(bucketIndex + 1).join('/');
    }

    const publicMarker = '/object/public/$bucket/';
    final full = uri.toString();
    final publicIdx = full.indexOf(publicMarker);
    if (publicIdx >= 0) {
      return full.substring(publicIdx + publicMarker.length);
    }

    const signMarker = '/object/sign/$bucket/';
    final signIdx = full.indexOf(signMarker);
    if (signIdx >= 0) {
      final rest = full.substring(signIdx + signMarker.length);
      return rest.split('?').first;
    }

    return trimmed;
  }

  static Future<String> resolveDisplayUrl(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return trimmed;

    if (trimmed.startsWith('http') &&
        !trimmed.contains('/storage/v1/object/')) {
      return trimmed;
    }

    final path = extractStoragePath(trimmed);
    if (path.isEmpty) return trimmed;

    try {
      return await SupabaseService.client.storage
          .from(bucket)
          .createSignedUrl(path, signedUrlTtlSeconds);
    } catch (_) {
      return SupabaseService.client.storage.from(bucket).getPublicUrl(path);
    }
  }
}
