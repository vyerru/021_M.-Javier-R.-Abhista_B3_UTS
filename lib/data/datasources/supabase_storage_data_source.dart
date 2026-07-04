import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageDataSource {
  final SupabaseClient _client;

  SupabaseStorageDataSource(this._client);

  Future<List<String>> uploadFiles({
    required List<File> files,
    required String ticketId,
  }) async {
    final urls = <String>[];

    for (final file in files) {
      final ext = p.extension(file.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$timestamp$ext';
      final filePath = '$ticketId/$fileName';

      await _client.storage
          .from('ticket_attachments')
          .upload(filePath, file);

      final url = _client.storage
          .from('ticket_attachments')
          .getPublicUrl(filePath);

      urls.add(url);
    }

    return urls;
  }

  Future<void> deleteFile(String url) async {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;
    final bucketIndex = segments.indexOf('ticket_attachments');
    if (bucketIndex == -1) return;

    final objectPath = segments.sublist(bucketIndex + 1).join('/');

    await _client.storage
        .from('ticket_attachments')
        .remove([objectPath]);
  }
}
