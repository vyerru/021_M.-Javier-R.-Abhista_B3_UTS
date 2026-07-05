import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadFileData {
  final Uint8List bytes;
  final String ext;

  const UploadFileData({required this.bytes, required this.ext});
}

class SupabaseStorageDataSource {
  final SupabaseClient _client;

  SupabaseStorageDataSource(this._client);

  Future<List<String>> uploadFiles({
    required List<UploadFileData> files,
    required String ticketId,
  }) async {
    final urls = <String>[];

    for (final file in files) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$timestamp.${file.ext}';
      final filePath = '$ticketId/$fileName';

      await _client.storage
          .from('ticket_attachments')
          .uploadBinary(filePath, file.bytes);

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
